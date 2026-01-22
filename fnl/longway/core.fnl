;; Core functionality for longway.nvim

(local config (require :longway.config))
(local pull (require :longway.sync.pull))
(local push (require :longway.sync.push))
(local notify (require :longway.ui.notify))

(local M {})

(fn M.hello []
  "Simple hello function for testing"
  (print "Hello from longway.nvim!"))

(fn M.get-info []
  "Get plugin information"
  (let [cfg (config.get)]
    {:name "longway.nvim"
     :version "0.1.0"
     :author "Eric Schmidt"
     :configured (config.is-configured)
     :workspace_dir (config.get-workspace-dir)
     :debug cfg.debug}))

(fn M.pull [story-id]
  "Pull a story by ID and open in buffer"
  (if (not (config.is-configured))
      (notify.no-token)
      (pull.pull-story-to-buffer story-id)))

(fn M.push []
  "Push current buffer to Shortcut"
  (if (not (config.is-configured))
      (notify.no-token)
      (push.push-current-buffer)))

(fn M.refresh []
  "Refresh current buffer from Shortcut"
  (if (not (config.is-configured))
      (notify.no-token)
      (pull.refresh-current-buffer)))

(fn M.open-in-browser []
  "Open current story in browser"
  (let [bufnr (vim.api.nvim_get_current_buf)
        lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        content (table.concat lines "\n")
        parser (require :longway.markdown.parser)
        parsed (parser.parse content)
        url (. parsed.frontmatter :shortcut_url)]
    (if url
        (do
          (vim.fn.system [(or vim.g.longway_browser "xdg-open") url])
          (notify.info (string.format "Opening %s" url)))
        (notify.error "No shortcut_url found in frontmatter"))))

(fn M.status []
  "Show sync status of current file"
  (let [bufnr (vim.api.nvim_get_current_buf)
        filepath (vim.api.nvim_buf_get_name bufnr)]
    (if (= filepath "")
        (notify.error "No file in current buffer")
        (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
              content (table.concat lines "\n")
              parser (require :longway.markdown.parser)
              parsed (parser.parse content)
              fm parsed.frontmatter]
          (if (not fm.shortcut_id)
              (notify.info "Not a longway-managed file")
              (do
                (print (string.format "Shortcut ID: %s" (tostring fm.shortcut_id)))
                (print (string.format "Type: %s" (or fm.shortcut_type "story")))
                (print (string.format "State: %s" (or fm.state "unknown")))
                (when fm.shortcut_url
                  (print (string.format "URL: %s" fm.shortcut_url)))
                (when fm.updated_at
                  (print (string.format "Last updated: %s" fm.updated_at)))
                (when fm.local_updated_at
                  (print (string.format "Local updated: %s" fm.local_updated_at)))))))))

M
