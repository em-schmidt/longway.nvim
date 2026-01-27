;; Main entry point for longway.nvim

(local config (require :longway.config))
(local core (require :longway.core))

(local M {})

(fn M.setup [opts]
  "Setup function called by users"
  (config.setup opts)

  ;; Validate configuration
  (let [[ok errors] (config.validate)]
    (when (and (not ok) (. (config.get) :debug))
      (each [_ err (ipairs errors)]
        (vim.notify (.. "[longway] " err) vim.log.levels.WARN))))

  ;; Log initialization in debug mode
  (when (. (config.get) :debug)
    (print "longway.nvim initialized")
    (print (string.format "  Workspace: %s" (config.get-workspace-dir)))
    (print (string.format "  Token configured: %s" (tostring (config.is-configured)))))

  ;; Phase 5: Setup auto-push on save if enabled
  (when (. (config.get) :auto_push_on_save)
    (let [auto (require :longway.sync.auto)]
      (auto.setup)))

  ;; Phase 6: Setup statusline buffer variable caching
  (let [statusline (require :longway.ui.statusline)]
    (statusline.setup)))

;; Expose core functions (Phase 1)
(set M.pull core.pull)
(set M.push core.push)
(set M.refresh core.refresh)
(set M.open core.open-in-browser)
(set M.status core.status)
(set M.get-info core.get-info)

;; Expose core functions (Phase 2)
(set M.pull-epic core.pull-epic)
(set M.sync core.sync)
(set M.sync-all core.sync-all)
(set M.cache-refresh core.cache-refresh)
(set M.cache-status core.cache-status)
(set M.list-presets core.list-presets)

;; Lua-friendly aliases (underscores)
(set M.pull_epic core.pull-epic)
(set M.sync_all core.sync-all)
(set M.cache_refresh core.cache-refresh)
(set M.cache_status core.cache-status)
(set M.list_presets core.list-presets)
(set M.get_info core.get-info)

;; Expose core functions (Phase 5)
(set M.resolve core.resolve)

;; Expose core functions (Phase 6)
(set M.picker core.picker)

;; Expose config functions
(set M.get-config config.get)
(set M.is-configured config.is-configured)
(set M.get-presets config.get-presets)

;; Legacy function for compatibility
(set M.hello core.hello)

M
