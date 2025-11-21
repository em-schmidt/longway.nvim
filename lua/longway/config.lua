-- [nfnl] Compiled from fnl/longway/config.fnl by https://github.com/Olical/nfnl, do not edit.
local M = {}
local default_config = {enable = true, debug = false}
local config = default_config
M.setup = function(opts)
  config = vim.tbl_deep_extend("force", default_config, (opts or {}))
  return config
end
M.get = function()
  return config
end
return M
