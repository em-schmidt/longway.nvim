;; Pull operations for longway.nvim
;; Fetches stories/epics from Shortcut and writes markdown files

(local config (require :longway.config))
(local stories-api (require :longway.api.stories))
(local epics-api (require :longway.api.epics))
(local search-api (require :longway.api.search))
(local renderer (require :longway.markdown.renderer))
(local slug (require :longway.util.slug))
(local notify (require :longway.ui.notify))

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

(fn M.pull-story [story-id]
  "Pull a single story from Shortcut and save as markdown
   Returns: {:ok bool :path string :error string}"
  (notify.pull-started story-id)

  (let [result (stories-api.get story-id)]
    (if (not result.ok)
        (do
          (notify.api-error result.error result.status)
          {:ok false :error result.error})
        ;; Got the story
        (let [story result.data
              stories-dir (config.get-stories-dir)
              filename (slug.make-filename story.id story.name "story")
              filepath (.. stories-dir "/" filename)
              markdown (renderer.render-story story)]
          ;; Ensure directory exists
          (ensure-directory stories-dir)

          ;; Write the file
          (if (write-file filepath markdown)
              (do
                (notify.pull-completed story.id story.name)
                {:ok true :path filepath :story story})
              (do
                (notify.error (string.format "Failed to write file: %s" filepath))
                {:ok false :error "Failed to write file"}))))))

(fn M.pull-story-to-buffer [story-id]
  "Pull a story and open it in a new buffer"
  (let [result (M.pull-story story-id)]
    (when result.ok
      (vim.cmd (.. "edit " result.path)))
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
              parser (require :longway.markdown.parser)
              parsed (parser.parse content)
              story-id (. parsed.frontmatter :shortcut_id)
              shortcut-type (or (. parsed.frontmatter :shortcut_type) "story")]
          (if (not story-id)
              (do
                (notify.error "Not a longway-managed file")
                {:ok false :error "Not a longway-managed file"})
              ;; Pull fresh data based on type
              (if (= shortcut-type "epic")
                  ;; Epic refresh
                  (let [result (epics-api.get-with-stories story-id)]
                    (if (not result.ok)
                        (do
                          (notify.api-error result.error result.status)
                          {:ok false :error result.error})
                        (let [epic result.data.epic
                              stories result.data.stories
                              markdown (renderer.render-epic epic stories)
                              lines (vim.split markdown "\n" {:plain true})]
                          (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
                          (notify.pull-completed epic.id epic.name)
                          {:ok true :epic epic})))
                  ;; Story refresh
                  (let [result (stories-api.get story-id)]
                    (if (not result.ok)
                        (do
                          (notify.api-error result.error result.status)
                          {:ok false :error result.error})
                        (let [story result.data
                              markdown (renderer.render-story story)
                              lines (vim.split markdown "\n" {:plain true})]
                          (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
                          (notify.pull-completed story.id story.name)
                          {:ok true :story story})))))))))

(fn M.pull-epic [epic-id]
  "Pull a single epic from Shortcut and save as markdown
   Returns: {:ok bool :path string :error string}"
  (notify.info (string.format "Pulling epic %s..." epic-id))

  (let [result (epics-api.get-with-stories epic-id)]
    (if (not result.ok)
        (do
          (notify.api-error result.error result.status)
          {:ok false :error result.error})
        ;; Got the epic
        (let [epic result.data.epic
              stories result.data.stories
              epics-dir (config.get-epics-dir)
              filename (slug.make-filename epic.id epic.name "epic")
              filepath (.. epics-dir "/" filename)
              markdown (renderer.render-epic epic stories)]
          ;; Ensure directory exists
          (ensure-directory epics-dir)

          ;; Write the file
          (if (write-file filepath markdown)
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
      (vim.cmd (.. "edit " result.path)))
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
                synced-count (vim.fn.ref 0)
                failed-count (vim.fn.ref 0)
                errors []]
            (notify.info (string.format "Found %d stories to sync" total))

            ;; Process each story
            (each [i story (ipairs stories)]
              (let [pull-result (M.pull-story story.id)]
                (if pull-result.ok
                    (vim.fn.setreg synced-count (+ (vim.fn.getreg synced-count) 1))
                    (do
                      (vim.fn.setreg failed-count (+ (vim.fn.getreg failed-count) 1))
                      (table.insert errors (string.format "Story %s: %s" story.id (or pull-result.error "unknown error")))))))

            (let [synced (vim.fn.getreg synced-count)
                  failed (vim.fn.getreg failed-count)]
              (notify.info (string.format "Sync complete: %d synced, %d failed" synced failed))
              {:ok true
               :synced synced
               :failed failed
               :errors errors
               :total total}))))))

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
        (do
          (each [name _ (pairs presets)]
            (tset results name (M.sync-preset name)))
          {:ok true :results results}))))

M
