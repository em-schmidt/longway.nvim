;; Conflict resolution for longway.nvim
;; Provides strategies for resolving sync conflicts between local and remote.

(local config (require :longway.config))
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
  "Insert conflict markers into the description sync section.
   Fetches remote description and shows both versions side by side.
   Returns: {:ok bool :error string}"
  (let [stories-api (require :longway.api.stories)
        remote-result (stories-api.get shortcut-id)]
    (if (not remote-result.ok)
        {:ok false :error (or remote-result.error "Failed to fetch remote story")}
        ;; Find the description sync section in the buffer and insert markers
        (let [cfg (config.get)
              lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
              start-marker (string.gsub cfg.sync_start_marker "{section}" "description")
              end-marker (string.gsub cfg.sync_end_marker "{section}" "description")
              start-escaped (string.gsub start-marker "[%-%.%+%[%]%(%)%$%^%%%?%*]" "%%%1")
              end-escaped (string.gsub end-marker "[%-%.%+%[%]%(%)%$%^%%%?%*]" "%%%1")]
          (var start-line nil)
          (var end-line nil)
          (each [i line (ipairs lines)]
            (when (string.match line start-escaped)
              (set start-line i))
            (when (and start-line (not end-line) (string.match line end-escaped))
              (set end-line i)))

          (if (not (and start-line end-line))
              {:ok false :error "Could not find description sync section"}
              ;; Extract local description (between markers)
              (let [local-desc-lines []
                    _ (for [i (+ start-line 1) (- end-line 1)]
                        (table.insert local-desc-lines (. lines i)))
                    local-desc (table.concat local-desc-lines "\n")
                    remote-desc (or remote-result.data.description "")
                    remote-ts (or remote-result.data.updated_at "unknown")
                    ;; Build conflict section
                    conflict-lines [start-marker
                                    "<!-- CONFLICT: Local version -->"
                                    local-desc
                                    (string.format "<!-- CONFLICT: Remote version (updated %s) -->" remote-ts)
                                    remote-desc
                                    "<!-- END CONFLICT -- edit above, then :LongwayPush to resolve -->"
                                    end-marker]]
                ;; Replace the description sync section
                (vim.api.nvim_buf_set_lines bufnr (- start-line 1) end-line false conflict-lines)
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
