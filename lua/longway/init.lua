-- [nfnl] fnl/longway/init.fnl
local config = require("longway.config")
local core = require("longway.core")
local M = {}
M.setup = function(opts)
  config.setup(opts)
  do
    local _let_1_ = config.validate()
    local ok = _let_1_[1]
    local errors = _let_1_[2]
    if (not ok and config.get().debug) then
      for _, err in ipairs(errors) do
        vim.notify(("[longway] " .. err), vim.log.levels.WARN)
      end
    else
    end
  end
  if config.get().debug then
    print("longway.nvim initialized")
    print(string.format("  Workspace: %s", config["get-workspace-dir"]()))
    print(string.format("  Token configured: %s", tostring(config["is-configured"]())))
  else
  end
  if config.get().auto_push_on_save then
    local auto = require("longway.sync.auto")
    return auto.setup()
  else
    return nil
  end
end
M.pull = core.pull
M.push = core.push
M.refresh = core.refresh
M.open = core["open-in-browser"]
M.status = core.status
M["get-info"] = core["get-info"]
M["pull-epic"] = core["pull-epic"]
M.sync = core.sync
M["sync-all"] = core["sync-all"]
M["cache-refresh"] = core["cache-refresh"]
M["cache-status"] = core["cache-status"]
M["list-presets"] = core["list-presets"]
M.pull_epic = core["pull-epic"]
M.sync_all = core["sync-all"]
M.cache_refresh = core["cache-refresh"]
M.cache_status = core["cache-status"]
M.list_presets = core["list-presets"]
M.get_info = core["get-info"]
M.resolve = core.resolve
M["get-config"] = config.get
M["is-configured"] = config["is-configured"]
M["get-presets"] = config["get-presets"]
M.hello = core.hello
return M
