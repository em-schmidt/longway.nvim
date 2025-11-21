-- [nfnl] Compiled from fnl/longway/core.fnl by https://github.com/Olical/nfnl, do not edit.
local M = {}
M.hello = function()
  return print("Hello from longway.nvim!")
end
M["get-info"] = function()
  return {name = "longway.nvim", version = "0.1.0", author = "Your Name"}
end
return M
