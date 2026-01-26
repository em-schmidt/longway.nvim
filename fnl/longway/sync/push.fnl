;; Push operations for longway.nvim
;; Pushes local changes back to Shortcut

(local config (require :longway.config))
(local stories-api (require :longway.api.stories))
(local parser (require :longway.markdown.parser))
(local notify (require :longway.ui.notify))
(local tasks-sync (require :longway.sync.tasks))
(local tasks-md (require :longway.markdown.tasks))
(local comments-sync (require :longway.sync.comments))
(local comments-md (require :longway.markdown.comments))
(local confirm (require :longway.ui.confirm))
(local hash (require :longway.util.hash))
(local frontmatter (require :longway.markdown.frontmatter))

(local M {})

(fn update-buffer-frontmatter [bufnr new-fm-data]
  "Update frontmatter in a buffer with new data"
  (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        content (table.concat lines "\n")
        parsed-fm (frontmatter.parse content)]
    ;; Merge new data into existing frontmatter
    (each [k v (pairs new-fm-data)]
      (tset parsed-fm.frontmatter k v))
    ;; Generate new frontmatter string
    (let [new-fm-str (frontmatter.generate parsed-fm.frontmatter)
          ;; Find end of frontmatter (second ---)
          new-content (.. new-fm-str "\n\n" parsed-fm.body)
          new-lines (vim.split new-content "\n" {:plain true})]
      (vim.api.nvim_buf_set_lines bufnr 0 -1 false new-lines))))

(fn update-buffer-tasks [bufnr tasks]
  "Update the tasks section in a buffer with new task data (including new IDs)"
  (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        content (table.concat lines "\n")
        cfg (config.get)
        start-marker (string.gsub cfg.sync_start_marker "{section}" "tasks")
        end-marker (string.gsub cfg.sync_end_marker "{section}" "tasks")
        ;; Find the markers
        start-escaped (string.gsub start-marker "[%-%.%+%[%]%(%)%$%^%%%?%*]" "%%%1")
        end-escaped (string.gsub end-marker "[%-%.%+%[%]%(%)%$%^%%%?%*]" "%%%1")]
    ;; Find start and end positions
    (var start-line nil)
    (var end-line nil)
    (each [i line (ipairs lines)]
      (when (string.match line start-escaped)
        (set start-line i))
      (when (and start-line (not end-line) (string.match line end-escaped))
        (set end-line i)))

    (when (and start-line end-line)
      ;; Generate new task content
      (let [new-task-content (tasks-md.render-tasks tasks)
            new-section-lines [start-marker]
            task-lines (vim.split new-task-content "\n" {:plain true})]
        (each [_ line (ipairs task-lines)]
          (table.insert new-section-lines line))
        (table.insert new-section-lines end-marker)
        ;; Replace lines from start to end
        (vim.api.nvim_buf_set_lines bufnr (- start-line 1) end-line false new-section-lines)))))

(fn update-buffer-comments [bufnr comments]
  "Update the comments section in a buffer with new comment data (including new IDs)"
  (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        cfg (config.get)
        start-marker (string.gsub cfg.sync_start_marker "{section}" "comments")
        end-marker (string.gsub cfg.sync_end_marker "{section}" "comments")
        ;; Find the markers
        start-escaped (string.gsub start-marker "[%-%.%+%[%]%(%)%$%^%%%?%*]" "%%%1")
        end-escaped (string.gsub end-marker "[%-%.%+%[%]%(%)%$%^%%%?%*]" "%%%1")]
    ;; Find start and end positions
    (var start-line nil)
    (var end-line nil)
    (each [i line (ipairs lines)]
      (when (string.match line start-escaped)
        (set start-line i))
      (when (and start-line (not end-line) (string.match line end-escaped))
        (set end-line i)))

    (when (and start-line end-line)
      ;; Generate new comment content
      (let [new-comment-content (comments-md.render-comments comments)
            new-section-lines [start-marker]
            comment-lines (vim.split new-comment-content "\n" {:plain true})]
        (each [_ line (ipairs comment-lines)]
          (table.insert new-section-lines line))
        (table.insert new-section-lines end-marker)
        ;; Replace lines from start to end
        (vim.api.nvim_buf_set_lines bufnr (- start-line 1) end-line false new-section-lines)))))

(fn push-story-comments [story-id local-comments opts]
  "Push comment changes to Shortcut
   Returns: {:ok bool :comments [updated comments] :error string}"
  (let [cfg (config.get)
        comments-api (require :longway.api.comments)]
    ;; Fetch current remote comments
    (let [remote-result (comments-api.list story-id)]
      (if (not remote-result.ok)
          {:ok false :error remote-result.error}
          ;; Format remote comments for comparison
          (let [remote-comments (comments-md.format-api-comments (or remote-result.data []))
                diff (comments-sync.diff local-comments remote-comments)
                has-changes (. comments-sync "has-changes?")]
            (if (and (not (has-changes diff)) (= (length diff.edited) 0))
                {:ok true :comments local-comments}
                ;; Check if we need to confirm deletions
                (if (and (> (length diff.deleted) 0)
                         cfg.comments.confirm_delete
                         (not opts.skip_confirm))
                    ;; Use synchronous confirmation prompt
                    (let [delete-count (length diff.deleted)
                          msg (string.format
                                "Push will delete %d comment%s from Shortcut. Continue?"
                                delete-count
                                (if (= delete-count 1) "" "s"))
                          confirmed (confirm.confirm-sync msg)]
                      (if confirmed
                          ;; User confirmed deletion
                          (comments-sync.push story-id local-comments remote-comments
                                              {:skip_delete false})
                          ;; User declined - push without deletions
                          (do
                            (notify.info "Skipping comment deletions")
                            (comments-sync.push story-id local-comments remote-comments
                                                {:skip_delete true}))))
                    ;; No confirmation needed
                    (comments-sync.push story-id local-comments remote-comments
                                        {:skip_delete (or opts.skip_delete false)}))))))))

(fn push-story-description [story-id description]
  "Push just the description to Shortcut
   Returns: {:ok bool :error string}"
  (let [update-data {:description description}
        result (stories-api.update story-id update-data)]
    (if result.ok
        {:ok true :story result.data}
        {:ok false :error result.error :status result.status})))

(fn push-story-tasks [story-id local-tasks opts]
  "Push task changes to Shortcut
   Returns: {:ok bool :tasks [updated tasks] :error string}"
  (let [cfg (config.get)]
    ;; First, get current remote story to get remote tasks
    (let [story-result (stories-api.get story-id)]
      (if (not story-result.ok)
          {:ok false :error story-result.error}
          ;; Push tasks
          (let [remote-tasks (or story-result.data.tasks [])
                diff (tasks-sync.diff local-tasks remote-tasks)
                has-changes (. tasks-sync "has-changes?")]
            (if (not (has-changes diff))
                {:ok true :tasks local-tasks}
                ;; Check if we need to confirm deletions
                (if (and (> (length diff.deleted) 0)
                         cfg.tasks.confirm_delete
                         (not opts.skip_confirm))
                    ;; Use synchronous confirmation prompt
                    (let [delete-count (length diff.deleted)
                          msg (string.format
                                "Push will delete %d task%s from Shortcut. Continue?"
                                delete-count
                                (if (= delete-count 1) "" "s"))
                          confirmed (confirm.confirm-sync msg)]
                      (if confirmed
                          ;; User confirmed deletion
                          (tasks-sync.push story-id local-tasks remote-tasks
                                           {:skip_delete false})
                          ;; User declined - push without deletions
                          (do
                            (notify.info "Skipping task deletions")
                            (tasks-sync.push story-id local-tasks remote-tasks
                                             {:skip_delete true}))))
                    ;; No confirmation needed
                    (tasks-sync.push story-id local-tasks remote-tasks
                                     {:skip_delete (or opts.skip_delete false)}))))))))

(fn M.push-story [story-id parsed opts]
  "Push story changes to Shortcut
   story-id: The Shortcut story ID
   parsed: Parsed markdown content
   opts: {:sync_tasks bool :skip_confirm bool :bufnr number}
   Returns: {:ok bool :error string}"
  (let [opts (or opts {})
        cfg (config.get)
        bufnr (or opts.bufnr (vim.api.nvim_get_current_buf))
        errors []
        results {}]

    (notify.push-started)

    ;; Push description
    (let [description (or parsed.description "")
          desc-result (push-story-description story-id description)]
      (set results.description desc-result)
      (when (not desc-result.ok)
        (table.insert errors (string.format "Description: %s" (or desc-result.error "unknown")))))

    ;; Push tasks if enabled
    (when (and cfg.sync_sections.tasks
               (or opts.sync_tasks (not= opts.sync_tasks false)))
      (let [local-tasks (or parsed.tasks [])
            tasks-result (push-story-tasks story-id local-tasks opts)]
        (set results.tasks tasks-result)
        (if tasks-result.ok
            (do
              ;; Update buffer task section if there are tasks to render
              (let [result-tasks (or tasks-result.tasks [])]
                (when (> (length result-tasks) 0)
                  (update-buffer-tasks bufnr result-tasks))
                ;; Always update tasks_hash so status stays accurate
                (let [new-hash (hash.tasks-hash result-tasks)]
                  (update-buffer-frontmatter bufnr {:tasks_hash new-hash}))))
            ;; Task push failed
            (table.insert errors (string.format "Tasks: %s"
                                                (or tasks-result.error
                                                    (table.concat (or tasks-result.errors []) ", ")))))))

    ;; Push comments if enabled
    (when (and cfg.sync_sections.comments
               (or opts.sync_comments (not= opts.sync_comments false)))
      (let [local-comments (or parsed.comments [])
            comments-result (push-story-comments story-id local-comments opts)]
        (set results.comments comments-result)
        (if comments-result.ok
            (do
              ;; Update buffer comment section if there are comments to render
              (let [result-comments (or comments-result.comments [])]
                (when (> (length result-comments) 0)
                  (update-buffer-comments bufnr result-comments))
                ;; Always update comments_hash so status stays accurate
                (let [new-hash (hash.comments-hash result-comments)]
                  (update-buffer-frontmatter bufnr {:comments_hash new-hash}))))
            ;; Comment push failed
            (table.insert errors (string.format "Comments: %s"
                                                (or comments-result.error
                                                    (table.concat (or comments-result.errors []) ", ")))))))

    ;; Report results
    (if (= (length errors) 0)
        (do
          (notify.push-completed)
          {:ok true :results results})
        (do
          (notify.error (string.format "Push completed with errors: %s"
                                       (table.concat errors "; ")))
          {:ok false :errors errors :results results}))))

(fn M.push-current-buffer []
  "Push changes from current buffer to Shortcut
   Returns: {:ok bool :error string}"
  (let [bufnr (vim.api.nvim_get_current_buf)
        filepath (vim.api.nvim_buf_get_name bufnr)]
    (if (= filepath "")
        (do
          (notify.error "No file in current buffer")
          {:ok false :error "No file in current buffer"})
        ;; Read buffer content
        (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
              content (table.concat lines "\n")
              parsed (parser.parse content)
              story-id (. parsed.frontmatter :shortcut_id)
              story-type (or (. parsed.frontmatter :shortcut_type) "story")]
          (if (not story-id)
              (do
                (notify.error "Not a longway-managed file (no shortcut_id in frontmatter)")
                {:ok false :error "Not a longway-managed file"})
              (if (not= story-type "story")
                  (do
                    (notify.warn "Only story push is supported currently")
                    {:ok false :error "Epic push not yet implemented"})
                  ;; Push story (description + tasks)
                  (M.push-story story-id parsed {:bufnr bufnr})))))))

(fn M.push-file [filepath]
  "Push changes from a specific file to Shortcut"
  (let [file (io.open filepath "r")]
    (if (not file)
        (do
          (notify.error (string.format "Cannot read file: %s" filepath))
          {:ok false :error "Cannot read file"})
        (let [content (file:read "*a")
              _ (file:close)
              parsed (parser.parse content)
              story-id (. parsed.frontmatter :shortcut_id)]
          (if (not story-id)
              {:ok false :error "Not a longway-managed file"}
              (M.push-story story-id parsed {}))))))

M
