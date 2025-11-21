-- [nfnl] Compiled from fnl/longway/init.fnl by https://github.com/Olical/nfnl, do not edit.
local config = require("longway.config")
local core = require("longway.core")
local M = {}
M.setup = function(opts)
  config.setup(opts)
  if config.get().debug then
    return print("longway.nvim initialized with config:", vim.inspect(config.get()))
  else
    return nil
  end
end
M.hello = core.hello
M.get_info = core["get-info"]
return M
