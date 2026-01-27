;; Statusline component for longway.nvim
;; Provides functions for statusline plugins (lualine, etc.) and custom statuslines.
;; Uses buffer variables for fast rendering — re-parses only on BufEnter/BufWritePost.

(local config (require :longway.config))

(local M {})

;; Augroup name for statusline autocmds
(local augroup-name "longway_statusline")

;; Track whether setup has been called
(var setup-done false)

(fn refresh-buffer-vars [bufnr]
  "Parse frontmatter and update buffer variables for the given buffer.
   Sets vim.b.longway_id, vim.b.longway_type, vim.b.longway_state,
   vim.b.longway_sync_status, vim.b.longway_conflict"
  (let [filepath (vim.api.nvim_buf_get_name bufnr)]
    ;; Only process markdown files
    (if (not (string.match filepath "%.md$"))
        (vim.api.nvim_buf_set_var bufnr "longway_id" vim.NIL)
        ;; It's a markdown file — try to parse
        (let [(ok lines) (pcall vim.api.nvim_buf_get_lines bufnr 0 -1 false)]
          (when ok
            (let [content (table.concat lines "\n")
                  parser (require :longway.markdown.parser)
                  parsed (parser.parse content)
                  fm parsed.frontmatter
                  shortcut-id fm.shortcut_id]
              (if (not shortcut-id)
                  ;; Not a longway file
                  (vim.api.nvim_buf_set_var bufnr "longway_id" vim.NIL)
                  ;; Longway file — compute sync status
                  (let [diff (require :longway.sync.diff)
                        first-sync ((. diff "first-sync?") fm)
                        sync-status (if first-sync
                                        "new"
                                        (let [has-conflict (not= fm.conflict_sections nil)]
                                          (if has-conflict
                                              "conflict"
                                              (if ((. diff "any-local-change?") parsed)
                                                  "modified"
                                                  "synced"))))]
                    (vim.api.nvim_buf_set_var bufnr "longway_id" shortcut-id)
                    (vim.api.nvim_buf_set_var bufnr "longway_type" (or fm.shortcut_type "story"))
                    (vim.api.nvim_buf_set_var bufnr "longway_state" (or fm.state ""))
                    (vim.api.nvim_buf_set_var bufnr "longway_sync_status" sync-status)
                    (vim.api.nvim_buf_set_var bufnr "longway_conflict"
                                              (if fm.conflict_sections true false))))))))))

(fn get-buf-var [bufnr name]
  "Safely get a buffer variable, returning nil on error"
  (let [(ok val) (pcall vim.api.nvim_buf_get_var bufnr name)]
    (if ok val nil)))

(fn M.is-longway-buffer []
  "Fast check: is the current buffer a longway-managed file?
   Returns: bool"
  (let [bufnr (vim.api.nvim_get_current_buf)
        id (get-buf-var bufnr "longway_id")]
    (and (not= id nil) (not= id vim.NIL))))

(fn M.get-status []
  "Returns a status string for the current buffer, or nil if not a longway file.
   Example: 'SC:12345 [synced]' or 'SC:12345 [modified]' or 'SC:12345 [CONFLICT]'"
  (let [bufnr (vim.api.nvim_get_current_buf)
        id (get-buf-var bufnr "longway_id")]
    (when (and id (not= id vim.NIL))
      (let [sync-status (or (get-buf-var bufnr "longway_sync_status") "unknown")
            display-status (if (= sync-status "conflict") "CONFLICT" sync-status)]
        (string.format "SC:%s [%s]" (tostring id) display-status)))))

(fn M.get-status-data []
  "Returns structured data for the current buffer, or nil if not a longway file.
   Returns: {:shortcut_id number :shortcut_type string :state string
             :sync_status string :conflict bool}"
  (let [bufnr (vim.api.nvim_get_current_buf)
        id (get-buf-var bufnr "longway_id")]
    (when (and id (not= id vim.NIL))
      {:shortcut_id id
       :shortcut_type (or (get-buf-var bufnr "longway_type") "story")
       :state (or (get-buf-var bufnr "longway_state") "")
       :sync_status (or (get-buf-var bufnr "longway_sync_status") "unknown")
       :conflict (or (get-buf-var bufnr "longway_conflict") false)})))

(fn M.lualine-component []
  "Returns a table compatible with lualine's component API.
   Usage: lualine_x = { require('longway.ui.statusline').lualine_component() }"
  (let [color-fn (fn []
                   (let [bufnr (vim.api.nvim_get_current_buf)
                         sync-status (or (get-buf-var bufnr "longway_sync_status") "unknown")]
                     (if (= sync-status "synced") {:fg "#a6e3a1"}
                         (= sync-status "modified") {:fg "#f9e2af"}
                         (= sync-status "conflict") {:fg "#f38ba8"}
                         (= sync-status "new") {:fg "#89b4fa"}
                         {:fg "#cdd6f4"})))
        tbl {:cond M.is-longway-buffer
             :color color-fn}]
    ;; lualine expects numeric key [1] for the component function
    (tset tbl 1 M.get-status)
    tbl))

(fn M.setup []
  "Register autocmds for buffer variable caching.
   Called from init.fnl during plugin setup."
  (when (not setup-done)
    (set setup-done true)
    (let [group (vim.api.nvim_create_augroup augroup-name {:clear true})]
      ;; Refresh on buffer enter
      (vim.api.nvim_create_autocmd "BufEnter"
        {:group group
         :pattern "*.md"
         :callback (fn [ev]
                     (let [(ok err) (pcall refresh-buffer-vars ev.buf)]
                       (when (not ok)
                         (when (. (config.get) :debug)
                           (vim.notify (.. "[longway] statusline refresh error: " (tostring err))
                                       vim.log.levels.DEBUG)))))})
      ;; Refresh after write
      (vim.api.nvim_create_autocmd "BufWritePost"
        {:group group
         :pattern "*.md"
         :callback (fn [ev]
                     (let [(ok err) (pcall refresh-buffer-vars ev.buf)]
                       (when (not ok)
                         (when (. (config.get) :debug)
                           (vim.notify (.. "[longway] statusline refresh error: " (tostring err))
                                       vim.log.levels.DEBUG)))))}))))

(fn M.teardown []
  "Remove statusline autocmds"
  (let [(ok _) (pcall vim.api.nvim_del_augroup_by_name augroup-name)]
    (set setup-done false)))

M
