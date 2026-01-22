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
    (print (string.format "  Token configured: %s" (tostring (config.is-configured))))))

;; Expose core functions
(set M.pull core.pull)
(set M.push core.push)
(set M.refresh core.refresh)
(set M.open core.open-in-browser)
(set M.status core.status)
(set M.get-info core.get-info)

;; Expose config functions
(set M.get-config config.get)
(set M.is-configured config.is-configured)

;; Legacy function for compatibility
(set M.hello core.hello)

M
