;; Pull operations for longway.nvim
;; Fetches stories/epics from Shortcut and writes markdown files

(local config (require :longway.config))
(local stories-api (require :longway.api.stories))
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
              story-id (. parsed.frontmatter :shortcut_id)]
          (if (not story-id)
              (do
                (notify.error "Not a longway-managed file")
                {:ok false :error "Not a longway-managed file"})
              ;; Pull fresh data
              (let [result (stories-api.get story-id)]
                (if (not result.ok)
                    (do
                      (notify.api-error result.error result.status)
                      {:ok false :error result.error})
                    ;; Update the buffer
                    (let [story result.data
                          markdown (renderer.render-story story)
                          lines (vim.split markdown "\n" {:plain true})]
                      (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
                      (notify.pull-completed story.id story.name)
                      {:ok true :story story}))))))))

M
