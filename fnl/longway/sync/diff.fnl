;; Change detection for longway.nvim
;; Compares local content against frontmatter hashes and remote timestamps
;; to determine sync status per section.

(local hash (require :longway.util.hash))

(local M {})

(fn M.first-sync? [frontmatter]
  "Returns true if this file has never been synced (no stored hash).
   On first render, sync_hash is set to empty string."
  (let [sync-hash (or (. frontmatter :sync_hash) "")]
    (= sync-hash "")))

(fn M.compute-section-hashes [parsed]
  "Compute current hashes for all sections from parsed content.
   Returns: {:description hash :tasks hash :comments hash}"
  (let [content-hash (. hash "content-hash")]
    {:description (content-hash (or parsed.description ""))
     :tasks (hash.tasks-hash (or parsed.tasks []))
     :comments (hash.comments-hash (or parsed.comments []))}))

(fn M.detect-local-changes [parsed]
  "Compare current parsed content against frontmatter hashes.
   Returns: {:description bool :tasks bool :comments bool}
            (true = section has local changes)"
  (let [fm parsed.frontmatter
        current (M.compute-section-hashes parsed)
        stored-desc (or fm.sync_hash "")
        stored-tasks (or fm.tasks_hash "")
        stored-comments (or fm.comments_hash "")]
    {:description (not= current.description stored-desc)
     :tasks (not= current.tasks stored-tasks)
     :comments (not= current.comments stored-comments)}))

(fn M.any-local-change? [parsed]
  "Returns true if ANY section has local changes vs. frontmatter hashes.
   Convenience wrapper over detect-local-changes."
  (let [changes (M.detect-local-changes parsed)]
    (or changes.description changes.tasks changes.comments)))

(fn M.detect-remote-change [frontmatter remote-updated-at]
  "Compare remote updated_at against frontmatter.updated_at.
   Returns: bool (true = remote has changed since last sync)"
  (let [stored (or frontmatter.updated_at "")]
    (and (not= remote-updated-at nil)
         (not= remote-updated-at "")
         (not= remote-updated-at stored))))

(fn M.classify [parsed remote-updated-at]
  "Full classification combining local and remote change detection.
   Returns: {:status :clean|:local-only|:remote-only|:conflict
             :local_changes {:description bool :tasks bool :comments bool}
             :remote_changed bool}"
  (let [fm parsed.frontmatter
        local-changes (M.detect-local-changes parsed)
        has-local (or local-changes.description
                      local-changes.tasks
                      local-changes.comments)
        remote-changed (M.detect-remote-change fm remote-updated-at)
        status (if (and has-local remote-changed) :conflict
                   has-local :local-only
                   remote-changed :remote-only
                   :clean)]
    {:status status
     :local_changes local-changes
     :remote_changed remote-changed}))

M
