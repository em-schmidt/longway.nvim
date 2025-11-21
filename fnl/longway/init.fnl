;; Main entry point for longway.nvim

(local config (require :longway.config))
(local core (require :longway.core))

(local M {})

(fn M.setup [opts]
  "Setup function called by users"
  (config.setup opts)
  (when (. (config.get) :debug)
    (print "longway.nvim initialized with config:" (vim.inspect (config.get)))))

;; Expose core functions
(set M.hello core.hello)
(set M.get-info core.get-info)

M
