;; Core functionality for longway.nvim

(local config (require :longway.config))
(local pull (require :longway.sync.pull))
(local push (require :longway.sync.push))
(local notify (require :longway.ui.notify))
(local cache (require :longway.cache.store))

(local M {})

(fn M.get-info []
  "Get plugin information"
  (let [cfg (config.get)]
    {:name "longway.nvim"
     :version "0.6.0"
     :author "Eric Schmidt"
     :configured (config.is-configured)
     :workspace_dir (config.get-workspace-dir)
     :presets (config.get-presets)
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
          (vim.ui.open url)
          (notify.info (string.format "Opening %s" url)))
        (notify.error "No shortcut_url found in frontmatter"))))

(fn print-task-status [parsed fm]
  "Print task sync status info"
  (let [hash-mod (require :longway.util.hash)
        local-tasks (or parsed.tasks [])
        local-count (length local-tasks)
        complete-count (accumulate [n 0 _ task (ipairs local-tasks)]
                         (if task.complete (+ n 1) n))
        new-count (accumulate [n 0 _ task (ipairs local-tasks)]
                    (if task.is_new (+ n 1) n))
        tasks-hash-stored (hash-mod.normalize-stored-hash fm.tasks_hash)]
    (print (string.format "Tasks: %d local (%d complete, %d new)"
                          local-count complete-count new-count))
    (when (> (length tasks-hash-stored) 0)
      (let [current-hash (hash-mod.tasks-hash local-tasks)
            changed (not= tasks-hash-stored current-hash)]
        (print (string.format "Tasks hash: %s%s"
                              tasks-hash-stored
                              (if changed " (changed)" " (synced)")))))))

(fn print-comment-status [parsed fm]
  "Print comment sync status info"
  (let [hash-mod (require :longway.util.hash)
        local-comments (or parsed.comments [])
        local-count (length local-comments)
        new-count (accumulate [n 0 _ cmt (ipairs local-comments)]
                    (if cmt.is_new (+ n 1) n))
        comments-hash-stored (hash-mod.normalize-stored-hash fm.comments_hash)]
    (print (string.format "Comments: %d local (%d new)"
                          local-count new-count))
    (when (> (length comments-hash-stored) 0)
      (let [current-hash (hash-mod.comments-hash local-comments)
            changed (not= comments-hash-stored current-hash)]
        (print (string.format "Comments hash: %s%s"
                              comments-hash-stored
                              (if changed " (changed)" " (synced)")))))))

(fn print-description-status [parsed fm]
  "Print description sync status info"
  (let [hash-mod (require :longway.util.hash)
        sync-hash-stored (hash-mod.normalize-stored-hash fm.sync_hash)]
    (when (> (length sync-hash-stored) 0)
      (let [content-hash (. hash-mod "content-hash")
            current-hash (content-hash (or parsed.description ""))
            changed (not= sync-hash-stored current-hash)]
        (print (string.format "Description: %s"
                              (if changed "changed" "synced")))))))

(fn print-conflict-status [parsed bufnr]
  "Print conflict status if any conflicts exist.
   Verifies hashes before reporting — clears stale conflict_sections automatically."
  (let [fm parsed.frontmatter]
    (when fm.conflict_sections
      (let [diff (require :longway.sync.diff)
            local-changes (diff.detect-local-changes parsed)
            ;; Only keep conflict sections that still have local changes
            conflict-list (if (= (type fm.conflict_sections) "table")
                              fm.conflict_sections
                              [fm.conflict_sections])
            still-conflicted (icollect [_ section (ipairs conflict-list)]
                               (when (. local-changes section) section))]
        (if (> (length still-conflicted) 0)
            ;; Real conflict — report it
            (do
              (print (string.format "CONFLICT in: %s" (table.concat still-conflicted ", ")))
              (print "  Resolve with: :LongwayResolve <local|remote|manual>"))
            ;; Stale conflict — hashes match, auto-clear
            (do
              (print "Conflict resolved (all sections synced)")
              (let [frontmatter-mod (require :longway.markdown.frontmatter)
                    lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
                    content (table.concat lines "\n")
                    parsed-fm (frontmatter-mod.parse content)]
                (tset parsed-fm.frontmatter :conflict_sections nil)
                (let [new-fm-str (frontmatter-mod.generate parsed-fm.frontmatter)
                      new-content (.. new-fm-str "\n\n" parsed-fm.body)
                      new-lines (vim.split new-content "\n" {:plain true})]
                  (vim.api.nvim_buf_set_lines bufnr 0 -1 false new-lines)))))))))

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
                  (print (string.format "Local updated: %s" fm.local_updated_at)))
                (print-description-status parsed fm)
                (print-task-status parsed fm)
                (print-comment-status parsed fm)
                (print-conflict-status parsed bufnr)))))))

;; Phase 2: Sync and filtering functions

(fn M.pull-epic [epic-id]
  "Pull an epic by ID and open in buffer"
  (if (not (config.is-configured))
      (notify.no-token)
      (pull.pull-epic-to-buffer epic-id)))

(fn M.sync [query-or-preset]
  "Sync stories by query string or preset name
   If query contains ':' it's treated as a query, otherwise as a preset name"
  (if (not (config.is-configured))
      (notify.no-token)
      (if (not query-or-preset)
          ;; No argument, use default preset if set
          (let [default-preset (config.get-default-preset)]
            (if default-preset
                (pull.sync-preset default-preset)
                (do
                  (notify.error "No query or preset specified")
                  {:ok false :error "No query or preset specified"})))
          ;; Check if it's a query (contains :) or preset name
          (if (string.find query-or-preset ":")
              (pull.sync-stories query-or-preset)
              ;; Try as preset first, fall back to query
              (let [preset (config.get-preset query-or-preset)]
                (if preset
                    (pull.sync-preset query-or-preset)
                    (pull.sync-stories query-or-preset)))))))

(fn M.sync-all []
  "Sync all configured presets"
  (if (not (config.is-configured))
      (notify.no-token)
      (pull.sync-all-presets)))

(fn M.cache-refresh [cache-type]
  "Refresh a specific cache or all caches
   cache-type: 'members', 'workflows', 'iterations', 'teams', or nil for all"
  (if (not (config.is-configured))
      (notify.no-token)
      (if cache-type
          (let [api-module (match cache-type
                            :members (require :longway.api.members)
                            :workflows (require :longway.api.workflows)
                            :iterations (require :longway.api.iterations)
                            :teams (require :longway.api.teams)
                            _ nil)]
            (if api-module
                (do
                  (notify.info (string.format "Refreshing %s cache..." cache-type))
                  (let [result (api-module.refresh-cache)]
                    (if result.ok
                        (notify.info (string.format "%s cache refreshed" cache-type))
                        (notify.error (string.format "Failed to refresh %s cache: %s" cache-type (or result.error "unknown"))))))
                (notify.error (string.format "Unknown cache type: %s" cache-type))))
          ;; Refresh all caches
          (do
            (notify.info "Refreshing all caches...")
            (let [members (require :longway.api.members)
                  workflows (require :longway.api.workflows)
                  iterations (require :longway.api.iterations)
                  teams (require :longway.api.teams)]
              (members.refresh-cache)
              (workflows.refresh-cache)
              (iterations.refresh-cache)
              (teams.refresh-cache)
              (notify.info "All caches refreshed"))))))

(fn M.cache-status []
  "Show status of all caches"
  (let [status (cache.get-status)]
    (print "Cache Status:")
    (print "-------------")
    (each [cache-type info (pairs status)]
      (let [state (if (not info.exists) "not cached"
                      info.expired "expired"
                      "valid")
            age-str (if info.age
                        (string.format "%d seconds ago" info.age)
                        "never")]
        (print (string.format "  %s: %s (%s)" cache-type state age-str))))))

(fn M.list-presets []
  "List all configured presets"
  (let [presets (config.get-presets)
        default (config.get-default-preset)]
    (if (= (next presets) nil)
        (notify.info "No presets configured")
        (do
          (print "Configured Presets:")
          (print "-------------------")
          (each [name preset (pairs presets)]
            (let [is-default (= name default)
                  marker (if is-default " (default)" "")]
              (print (string.format "  %s%s" name marker))
              (when preset.query
                (print (string.format "    query: %s" preset.query)))
              (when preset.description
                (print (string.format "    desc: %s" preset.description)))))))))

;; Phase 5: Conflict resolution

(fn M.resolve [strategy]
  "Resolve a sync conflict using the given strategy.
   strategy: 'local' | 'remote' | 'manual'"
  (if (not (config.is-configured))
      (notify.no-token)
      (let [resolve-mod (require :longway.sync.resolve)]
        (resolve-mod.resolve strategy {}))))

;; Phase 6: Picker

(fn M.picker [source opts]
  "Open a Snacks picker for the given source type.
   source: 'stories' | 'epics' | 'presets' | 'modified' | 'comments'"
  (if (not (config.is-configured))
      (notify.no-token)
      (let [picker (require :longway.ui.picker)]
        (if (not (picker.check-snacks))
            nil
            (match source
              :stories (picker.pick-stories (or opts {}))
              :epics (picker.pick-epics (or opts {}))
              :presets (picker.pick-presets)
              :modified (picker.pick-modified (or opts {}))
              :comments (picker.pick-comments (or opts {}))
              _ (notify.error (string.format "Unknown picker source: %s" (tostring source))))))))

M
