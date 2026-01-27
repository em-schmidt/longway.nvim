;; Auto-push on save for longway.nvim
;; Registers BufWritePost autocmd to push changes after saving.

(local config (require :longway.config))
(local notify (require :longway.ui.notify))

(local M {})

;; Module state
(var augroup-id nil)
(var timers {})   ;; keyed by bufnr

(fn M.is-active []
  "Returns true if auto-push is currently active"
  (not= augroup-id nil))

(fn cancel-timer [bufnr]
  "Cancel any pending auto-push timer for a buffer"
  (let [timer (. timers bufnr)]
    (when timer
      (when (timer:is_active)
        (timer:stop))
      (timer:close)
      (tset timers bufnr nil))))

(fn schedule-push [bufnr]
  "Schedule a debounced push for a buffer"
  (let [cfg (config.get)
        delay (or cfg.auto_push_delay 2000)]
    ;; Cancel any existing timer for this buffer
    (cancel-timer bufnr)
    ;; Create new timer
    (let [timer (vim.uv.new_timer)]
      (tset timers bufnr timer)
      (timer:start delay 0
        (vim.schedule_wrap
          (fn []
            ;; Clean up timer reference
            (tset timers bufnr nil)
            (when (timer:is_active)
              (timer:stop))
            (timer:close)
            ;; Verify buffer is still valid
            (when (vim.api.nvim_buf_is_valid bufnr)
              ;; Re-parse the buffer to check for changes
              (let [diff (require :longway.sync.diff)
                    parser (require :longway.markdown.parser)
                    lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
                    content (table.concat lines "\n")
                    parsed (parser.parse content)
                    any-change? (. diff "any-local-change?")]
                ;; Only push if there are actual local changes
                ;; (prevents push-back loop after pull/refresh)
                (when (and parsed.frontmatter.shortcut_id
                          (any-change? parsed))
                  (let [push (require :longway.sync.push)]
                    (notify.debug "Auto-pushing changes...")
                    (push.push-current-buffer)))))))))))

(fn on-buf-write [ev]
  "BufWritePost callback — check if file is longway-managed and schedule push"
  (let [bufnr ev.buf
        filepath (vim.api.nvim_buf_get_name bufnr)
        workspace-dir (config.get-workspace-dir)]
    ;; Only process files within the workspace directory
    (when (and (not= filepath "")
              (string.find filepath workspace-dir 1 true))
      ;; Quick check: parse frontmatter to see if this is a longway file
      (let [parser (require :longway.markdown.parser)
            lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
            content (table.concat lines "\n")
            parsed (parser.parse content)]
        (when (and parsed.frontmatter
                   parsed.frontmatter.shortcut_id)
          (schedule-push bufnr))))))

(fn M.setup []
  "Set up auto-push on save.
   Creates an augroup with a BufWritePost autocmd for markdown files."
  ;; Clean up any existing setup
  (M.teardown)
  (set augroup-id (vim.api.nvim_create_augroup "longway_auto_push" {:clear true}))
  (vim.api.nvim_create_autocmd "BufWritePost"
    {:group augroup-id
     :pattern "*.md"
     :callback on-buf-write
     :desc "longway.nvim: auto-push on save"})
  (notify.debug "Auto-push on save enabled"))

(fn M.teardown []
  "Remove auto-push autocmds and cancel all pending timers."
  ;; Cancel all pending timers
  (each [bufnr _ (pairs timers)]
    (cancel-timer bufnr))
  (set timers {})
  ;; Remove augroup
  (when augroup-id
    (vim.api.nvim_del_augroup_by_id augroup-id)
    (set augroup-id nil)))

M
