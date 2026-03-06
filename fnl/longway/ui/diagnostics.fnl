;; Diagnostics module for longway.nvim
;; Provides vim.diagnostic warnings when users add unsupported headers
;; inside synced sections of longway-managed markdown files.

(local M {})

;; Module state
(var augroup-id nil)

;; Known section headers that are valid at the ## level
(local known-headers {"Description" true
                      "Tasks" true
                      "Comments" true
                      "Local Notes" true
                      "Stories" true})

(local ns (vim.api.nvim_create_namespace "longway"))

(fn find-title-line [lines]
  "Find the line number (0-indexed) of the # Title line (first h1 after frontmatter).
   Returns the line index or nil."
  (var in-frontmatter false)
  (var past-frontmatter false)
  (var result nil)
  (each [i line (ipairs lines) &until result]
    (let [idx (- i 1)]
      (if (and (= i 1) (= line "---"))
          (set in-frontmatter true)
          (and in-frontmatter (= line "---"))
          (do
            (set in-frontmatter false)
            (set past-frontmatter true))
          (and (not in-frontmatter)
               (string.match line "^# "))
          (set result idx))))
  result)

(fn check-buffer [bufnr]
  "Check a buffer for unsupported headers and set diagnostics."
  (when (vim.api.nvim_buf_is_valid bufnr)
    (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
          content (table.concat lines "\n")
          ;; Quick check: is this a longway file?
          frontmatter (require :longway.markdown.frontmatter)
          parsed (frontmatter.parse content)]
      (if (not (. parsed.frontmatter :shortcut_id))
          ;; Not a longway file — clear any existing diagnostics
          (vim.diagnostic.set ns bufnr [])
          ;; Longway file — scan for problematic headers
          (let [diagnostics []
                title-line (find-title-line lines)]
            (each [i line (ipairs lines)]
              (let [lnum (- i 1)] ;; 0-indexed
                ;; Check for h1 headers (# ) that aren't the title
                (when (and (string.match line "^# [^#]")
                           (not= lnum title-line))
                  (table.insert diagnostics
                                {:lnum lnum
                                 :col 0
                                 :severity vim.diagnostic.severity.WARN
                                 :source "longway"
                                 :message "Top-level heading (# ) may break section parsing — use ## or lower"}))
                ;; Check for ## headers that aren't known sections
                (let [header-name (string.match line "^## (.+)$")]
                  (when (and header-name (not (. known-headers header-name)))
                    (table.insert diagnostics
                                  {:lnum lnum
                                   :col 0
                                   :severity vim.diagnostic.severity.WARN
                                   :source "longway"
                                   :message "Unsupported heading level in synced section — use ### or lower to avoid parsing issues"})))))
            (vim.diagnostic.set ns bufnr diagnostics))))))

(fn on-buf-event [ev]
  "Autocmd callback for BufEnter/TextChanged/TextChangedI"
  (check-buffer ev.buf))

(fn M.setup []
  "Set up diagnostics for longway-managed markdown files."
  (M.teardown)
  (set augroup-id (vim.api.nvim_create_augroup "longway_diagnostics" {:clear true}))
  (vim.api.nvim_create_autocmd ["BufEnter" "TextChanged" "TextChangedI"]
    {:group augroup-id
     :pattern "*.md"
     :callback on-buf-event
     :desc "longway.nvim: header diagnostics for synced sections"}))

(fn M.teardown []
  "Remove diagnostics autocmds."
  (when augroup-id
    (vim.api.nvim_del_augroup_by_id augroup-id)
    (set augroup-id nil)))

(fn M.check [bufnr]
  "Manually check a buffer for diagnostics (exposed for testing)."
  (check-buffer (or bufnr (vim.api.nvim_get_current_buf))))

M
