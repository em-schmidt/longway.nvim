;; Configuration module for longway.nvim

(local M {})

;; Default configuration
(local default-config
  {:enable true
   :debug false})

;; Current configuration state
(var config default-config)

(fn M.setup [opts]
  "Setup the plugin with user configuration"
  (set config (vim.tbl_deep_extend :force default-config (or opts {})))
  config)

(fn M.get []
  "Get current configuration"
  config)

M
