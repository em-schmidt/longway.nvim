;; Push operations for longway.nvim
;; Pushes local changes back to Shortcut

(local config (require :longway.config))
(local stories-api (require :longway.api.stories))
(local parser (require :longway.markdown.parser))
(local notify (require :longway.ui.notify))

(local M {})

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
                    (notify.warn "Only story push is supported in Phase 1")
                    {:ok false :error "Epic push not yet implemented"})
                  ;; Push story description
                  (M.push-story story-id parsed)))))))

(fn M.push-story [story-id parsed]
  "Push story changes to Shortcut"
  (notify.push-started)

  ;; For Phase 1, we only push description changes
  (let [description (or parsed.description "")
        update-data {:description description}
        result (stories-api.update story-id update-data)]
    (if result.ok
        (do
          (notify.push-completed)
          {:ok true :story result.data})
        (do
          (notify.api-error result.error result.status)
          {:ok false :error result.error}))))

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
              (M.push-story story-id parsed))))))

M
