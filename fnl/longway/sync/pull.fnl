;; Pull operations for longway.nvim
;; Fetches stories/epics from Shortcut and writes markdown files

(local config (require :longway.config))
(local stories-api (require :longway.api.stories))
(local comments-api (require :longway.api.comments))
(local epics-api (require :longway.api.epics))
(local members-api (require :longway.api.members))
(local workflows-api (require :longway.api.workflows))
(local search-api (require :longway.api.search))
(local comments-md (require :longway.markdown.comments))
(local parser (require :longway.markdown.parser))
(local renderer (require :longway.markdown.renderer))
(local slug (require :longway.util.slug))
(local notify (require :longway.ui.notify))
(local progress (require :longway.ui.progress))

(local M {})

(fn ensure-directory [path]
  "Ensure a directory exists, creating it if necessary"
  (let [exists (vim.fn.isdirectory path)]
    (when (= exists 0)
      (vim.fn.mkdir path "p"))))

(fn write-file [path content]
  "Write content to a file"
  (let [file (io.open path "w")]
    (when file
      (file:write content)
      (file:close)
      true)))

(fn fetch-story-comments [story]
  "Fetch comments for a story and attach formatted comments
   Mutates story to add .comments field
   Returns: story (with .comments populated)"
  (let [cfg (config.get)]
    (when cfg.sync_sections.comments
      (let [result (comments-api.list story.id)]
        (when result.ok
          (let [raw-comments (or result.data [])
                ;; Respect max_pull limit
                limited (if (and cfg.comments.max_pull
                                (> (length raw-comments) cfg.comments.max_pull))
                           (do
                             (let [trimmed []]
                               (for [i 1 cfg.comments.max_pull]
                                 (table.insert trimmed (. raw-comments i)))
                               trimmed))
                           raw-comments)
                formatted (comments-md.format-api-comments limited)]
            (set story.comments formatted))))))
  story)

(fn enrich-story-slim [story]
  "Enrich a StorySlim object with resolved names for rendering.
   The epic stories endpoint returns workflow_state_id and owner_ids (UUIDs),
   but the renderer expects workflow_state_name and owners [{:profile {:name ...}}]."
  (when (and story.workflow_state_id (not story.workflow_state_name))
    (set story.workflow_state_name
         (workflows-api.resolve-state-name story.workflow_state_id)))
  (when (and story.owner_ids
             (not story.owners)
             (> (length story.owner_ids) 0))
    (let [owners []]
      (each [_ owner-id (ipairs story.owner_ids)]
        (let [name (members-api.resolve-name owner-id)]
          (table.insert owners {:id owner-id :profile {:name name}})))
      (set story.owners owners)))
  story)

(fn enrich-epic-stories [stories]
  "Enrich a list of StorySlim objects for epic table rendering."
  (each [_ story (ipairs stories)]
    (enrich-story-slim story))
  stories)

(fn preserve-local-notes [new-markdown old-local-notes]
  "Replace the blank Local Notes template in new-markdown with preserved content.
   old-local-notes: the full '## Local Notes...' text from the previous content, or nil.
   Returns: updated markdown string."
  (if (not old-local-notes)
      new-markdown
      (let [template (renderer.render-local-notes)
            (start end) (string.find new-markdown template 1 true)]
        (if start
            (.. (string.sub new-markdown 1 (- start 1))
                old-local-notes
                (string.sub new-markdown (+ end 1)))
            new-markdown))))

(fn M.pull-story [story-id opts]
  "Pull a single story from Shortcut and save as markdown
   opts: {:silent bool} - when true, suppress per-story notifications (used during bulk sync)
   Returns: {:ok bool :path string :error string}"
  (let [silent (and opts opts.silent)]
    (when (not silent)
      (notify.pull-started story-id))

    (let [result (stories-api.get story-id)]
      (if (not result.ok)
          (do
            (when (not silent)
              (notify.api-error result.error result.status))
            {:ok false :error result.error})
          ;; Got the story - also fetch comments
          (let [story (fetch-story-comments result.data)
                stories-dir (config.get-stories-dir)
                filename (slug.make-filename story.id story.name "story")
                filepath (.. stories-dir "/" filename)
                markdown (renderer.render-story story)
                ;; Preserve local notes from existing file
                old-local-notes (when (= (vim.fn.filereadable filepath) 1)
                                  (let [f (io.open filepath "r")]
                                    (when f
                                      (let [existing (f:read "*a")]
                                        (f:close)
                                        (parser.extract-local-notes existing)))))
                final-markdown (preserve-local-notes markdown old-local-notes)]
            ;; Ensure directory exists
            (ensure-directory stories-dir)

            ;; Write the file
            (if (write-file filepath final-markdown)
                (do
                  (when (not silent)
                    (notify.pull-completed story.id story.name))
                  {:ok true :path filepath :story story})
                (do
                  (notify.error (string.format "Failed to write file: %s" filepath))
                  {:ok false :error "Failed to write file"})))))))

(fn M.pull-story-to-buffer [story-id]
  "Pull a story and open it in a new buffer"
  (let [result (M.pull-story story-id)]
    (when result.ok
      (vim.cmd (.. "confirm edit " (vim.fn.fnameescape result.path))))
    result))

(fn M.refresh-current-buffer []
  "Refresh the current buffer from Shortcut"
  (let [bufnr (vim.api.nvim_get_current_buf)
        filepath (vim.api.nvim_buf_get_name bufnr)]
    (if (= filepath "")
        (do
          (notify.error "No file in current buffer")
          {:ok false :error "No file in current buffer"})
        ;; Read current content to get shortcut_id
        (let [content (table.concat (vim.api.nvim_buf_get_lines bufnr 0 -1 false) "\n")
              parsed (parser.parse content)
              story-id (. parsed.frontmatter :shortcut_id)
              shortcut-type (or (. parsed.frontmatter :shortcut_type) "story")]
          (if (not story-id)
              (do
                (notify.error "Not a longway-managed file")
                {:ok false :error "Not a longway-managed file"})
              ;; Extract local notes before refreshing
              (let [old-local-notes (parser.extract-local-notes content)]
                ;; Pull fresh data based on type
                (if (= shortcut-type "epic")
                    ;; Epic refresh
                    (let [result (epics-api.get-with-stories story-id)]
                      (if (not result.ok)
                          (do
                            (notify.api-error result.error result.status)
                            {:ok false :error result.error})
                          (let [epic result.data.epic
                                stories (enrich-epic-stories (or result.data.stories []))
                                markdown (renderer.render-epic epic stories)
                                final-markdown (preserve-local-notes markdown old-local-notes)
                                lines (vim.split final-markdown "\n" {:plain true})]
                            (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
                            (notify.pull-completed epic.id epic.name)
                            {:ok true :epic epic})))
                    ;; Story refresh
                    (let [result (stories-api.get story-id)]
                      (if (not result.ok)
                          (do
                            (notify.api-error result.error result.status)
                            {:ok false :error result.error})
                          (let [story (fetch-story-comments result.data)
                                markdown (renderer.render-story story)
                                final-markdown (preserve-local-notes markdown old-local-notes)
                                lines (vim.split final-markdown "\n" {:plain true})]
                            (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
                            (notify.pull-completed story.id story.name)
                            {:ok true :story story}))))))))))

(fn M.pull-epic [epic-id]
  "Pull a single epic from Shortcut and save as markdown
   Returns: {:ok bool :path string :error string}"
  (notify.info (string.format "Pulling epic %s..." epic-id))

  (let [result (epics-api.get-with-stories epic-id)]
    (if (not result.ok)
        (do
          (notify.api-error result.error result.status)
          {:ok false :error result.error})
        ;; Got the epic — enrich StorySlim objects with resolved names
        (let [epic result.data.epic
              stories (enrich-epic-stories (or result.data.stories []))
              epics-dir (config.get-epics-dir)
              filename (slug.make-filename epic.id epic.name "epic")
              filepath (.. epics-dir "/" filename)
              markdown (renderer.render-epic epic stories)
              ;; Preserve local notes from existing file
              old-local-notes (when (= (vim.fn.filereadable filepath) 1)
                                (let [f (io.open filepath "r")]
                                  (when f
                                    (let [existing (f:read "*a")]
                                      (f:close)
                                      (parser.extract-local-notes existing)))))
              final-markdown (preserve-local-notes markdown old-local-notes)]
          ;; Ensure directory exists
          (ensure-directory epics-dir)

          ;; Write the file
          (if (write-file filepath final-markdown)
              (do
                (notify.pull-completed epic.id epic.name)
                {:ok true :path filepath :epic epic :stories stories})
              (do
                (notify.error (string.format "Failed to write file: %s" filepath))
                {:ok false :error "Failed to write file"}))))))

(fn M.pull-epic-to-buffer [epic-id]
  "Pull an epic and open it in a new buffer"
  (let [result (M.pull-epic epic-id)]
    (when result.ok
      (vim.cmd (.. "confirm edit " (vim.fn.fnameescape result.path))))
    result))

(fn M.sync-stories [query opts]
  "Sync multiple stories based on a search query
   query: search query string (e.g., 'owner:me state:started')
   opts: {:max_results number :include_epics bool}
   Returns: {:ok bool :synced number :failed number :errors [string]}"
  (let [opts (or opts {})
        max-results (or opts.max_results 100)]
    (notify.info (string.format "Syncing stories matching: %s" (or query "all")))

    (let [result (search-api.search-stories-all query {:max_results max-results})]
      (if (not result.ok)
          (do
            (notify.api-error result.error)
            {:ok false :error result.error :synced 0 :failed 0})
          ;; Got stories, sync each one
          (let [stories result.data
                total (length stories)
                progress-id (progress.start "Syncing" total)
                errors []
                (synced-count failed-count)
                (accumulate [(synced failed) (values 0 0)
                             i story (ipairs stories)]
                  (do
                    (progress.update progress-id i total (or story.name (tostring story.id)))
                    (vim.cmd.redraw)
                    (let [pull-result (M.pull-story story.id {:silent true})]
                      (if pull-result.ok
                          (values (+ synced 1) failed)
                          (do
                            (table.insert errors (string.format "Story %s: %s" story.id (or pull-result.error "unknown error")))
                            (values synced (+ failed 1)))))))]
            (progress.finish progress-id synced-count failed-count)
            {:ok true
             :synced synced-count
             :failed failed-count
             :errors errors
             :total total})))))

(fn M.sync-preset [preset-name]
  "Sync stories using a named preset from config
   Returns: {:ok bool :synced number :failed number :error string}"
  (let [cfg (config.get)
        presets (or cfg.presets {})
        preset (. presets preset-name)]
    (if (not preset)
        (do
          (notify.error (string.format "Preset '%s' not found" preset-name))
          {:ok false :error "Preset not found"})
        ;; Build query from preset
        (let [query (or preset.query "")
              opts {:max_results (or preset.max_results 100)}]
          (notify.info (string.format "Running preset '%s'" preset-name))
          (M.sync-stories query opts)))))

(fn M.sync-all-presets []
  "Sync all configured presets
   Returns: {:ok bool :results table}"
  (let [cfg (config.get)
        presets (or cfg.presets {})
        results {}]
    (if (= (next presets) nil)
        (do
          (notify.warn "No presets configured")
          {:ok false :error "No presets configured"})
        (let [preset-names (vim.tbl_keys presets)
              total (length preset-names)
              progress-id (progress.start "Syncing presets" total)]
          (each [i name (ipairs preset-names)]
            (progress.update progress-id i total name)
            (tset results name (M.sync-preset name)))
          (progress.finish progress-id total 0)
          {:ok true :results results}))))

M
