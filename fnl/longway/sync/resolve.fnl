;; Conflict resolution for longway.nvim
;; Provides strategies for resolving sync conflicts between local and remote.

(local notify (require :longway.ui.notify))
(local parser (require :longway.markdown.parser))
(local frontmatter (require :longway.markdown.frontmatter))

(local M {})

(fn get-buffer-parsed [bufnr]
  "Parse the current buffer content.
   Returns: parsed table or nil"
  (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        content (table.concat lines "\n")]
    (parser.parse content)))

(fn update-buffer-frontmatter [bufnr new-fm-data]
  "Update frontmatter in a buffer with new data (mirrors push.fnl helper)"
  (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        content (table.concat lines "\n")
        parsed-fm (frontmatter.parse content)]
    ;; Merge new data into existing frontmatter
    (each [k v (pairs new-fm-data)]
      (tset parsed-fm.frontmatter k v))
    ;; Generate new frontmatter string
    (let [new-fm-str (frontmatter.generate parsed-fm.frontmatter)
          new-content (.. new-fm-str "\n\n" parsed-fm.body)
          new-lines (vim.split new-content "\n" {:plain true})]
      (vim.api.nvim_buf_set_lines bufnr 0 -1 false new-lines))))

(fn M.resolve-local [shortcut-id parsed bufnr]
  "Force push local content to Shortcut, ignoring remote changes.
   Returns: {:ok bool :error string}"
  (let [push (require :longway.sync.push)
        result (push.push-story shortcut-id parsed {:force true :bufnr bufnr})]
    (if result.ok
        (do
          ;; push-story already clears conflict_sections on success
          (notify.info "Conflict resolved: local changes pushed to Shortcut")
          {:ok true})
        {:ok false :error (or result.error "Push failed")})))

(fn M.resolve-remote [shortcut-id bufnr]
  "Force pull remote content, discarding local changes.
   Returns: {:ok bool :error string}"
  (let [pull (require :longway.sync.pull)
        result (pull.refresh-current-buffer)]
    (if result.ok
        (do
          ;; refresh-current-buffer replaces the entire buffer,
          ;; so conflict_sections is naturally cleared (not in fresh frontmatter)
          (notify.info "Conflict resolved: remote content pulled from Shortcut")
          {:ok true})
        {:ok false :error (or result.error "Pull failed")})))

(fn M.resolve-manual [shortcut-id bufnr]
  "Insert conflict markers into the description section.
   Fetches remote description and shows both versions side by side.
   Returns: {:ok bool :error string}"
  (let [stories-api (require :longway.api.stories)
        remote-result (stories-api.get shortcut-id)]
    (if (not remote-result.ok)
        {:ok false :error (or remote-result.error "Failed to fetch remote story")}
        ;; Find the description section by ## header
        (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)]
          ;; Find ## Description header and the next ## header
          (var header-line nil)
          (var next-header-line nil)
          (each [i line (ipairs lines)]
            (when (and (not header-line) (= line "## Description"))
              (set header-line i))
            (when (and header-line (not next-header-line)
                      (> i header-line)
                      (string.match line "^## "))
              (set next-header-line i)))

          (if (not header-line)
              {:ok false :error "Could not find ## Description section"}
              ;; Extract local description (between header and next header)
              (let [content-start (+ header-line 1)
                    content-end (if next-header-line
                                    (- next-header-line 1)
                                    (length lines))
                    local-desc-lines []
                    _ (for [i content-start content-end]
                        (table.insert local-desc-lines (. lines i)))
                    local-desc (string.gsub (table.concat local-desc-lines "\n") "^%s+(.-)%s+$" "%1")
                    remote-desc (or remote-result.data.description "")
                    remote-ts (or remote-result.data.updated_at "unknown")
                    ;; Build conflict section content (keep the header, replace content)
                    conflict-lines [""
                                    "<!-- CONFLICT: Local version -->"
                                    local-desc
                                    (string.format "<!-- CONFLICT: Remote version (updated %s) -->" remote-ts)
                                    remote-desc
                                    "<!-- END CONFLICT -- edit above, then :LongwayPush to resolve -->"]]
                ;; Replace content between header and next section
                (vim.api.nvim_buf_set_lines bufnr content-start
                                            (if next-header-line (- next-header-line 1) (length lines))
                                            false conflict-lines)
                ;; Clear conflict_sections from frontmatter (user is now manually resolving)
                (update-buffer-frontmatter bufnr {:conflict_sections nil})
                (notify.info "Conflict markers inserted. Edit the description, then :LongwayPush to resolve.")
                {:ok true}))))))

(fn M.resolve [strategy opts]
  "Resolve a sync conflict using the given strategy.
   strategy: 'local' | 'remote' | 'manual'
   opts: {:bufnr number}
   Returns: {:ok bool :error string}"
  (let [opts (or opts {})
        bufnr (or opts.bufnr (vim.api.nvim_get_current_buf))
        parsed (get-buffer-parsed bufnr)
        shortcut-id (when parsed (. parsed.frontmatter :shortcut_id))]
    (if (not shortcut-id)
        (do
          (notify.error "Not a longway-managed file (no shortcut_id)")
          {:ok false :error "Not a longway-managed file"})
        ;; Verify conflict exists (or allow resolution anyway for manual)
        (let [conflict-sections (. parsed.frontmatter :conflict_sections)]
          (if (and (not conflict-sections)
                   (not= strategy "manual"))
              (do
                (notify.warn "No conflict detected. Use :LongwayPush or :LongwayRefresh instead.")
                {:ok false :error "No conflict detected"})
              ;; Dispatch to strategy
              (match strategy
                "local" (M.resolve-local shortcut-id parsed bufnr)
                "remote" (M.resolve-remote shortcut-id bufnr)
                "manual" (M.resolve-manual shortcut-id bufnr)
                _ (do
                    (notify.error (string.format "Unknown resolve strategy: %s. Use local, remote, or manual." strategy))
                    {:ok false :error (string.format "Unknown strategy: %s" strategy)})))))))

M
