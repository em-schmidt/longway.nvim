-- Main entry point for longway.nvim
-- Compiled from fnl/longway/init.fnl

local config = require("longway.config")
local core = require("longway.core")

local M = {}

function M.setup(opts)
  config.setup(opts)

  -- Validate configuration
  local ok, errors = config.validate()
  if not ok and config.get().debug then
    for _, err in ipairs(errors) do
      vim.notify("[longway] " .. err, vim.log.levels.WARN)
    end
  end

  -- Log initialization in debug mode
  if config.get().debug then
    print("longway.nvim initialized")
    print(string.format("  Workspace: %s", config.get_workspace_dir()))
    print(string.format("  Token configured: %s", tostring(config.is_configured())))
  end
end

-- Expose core functions (Phase 1)
M.pull = core.pull
M.push = core.push
M.refresh = core.refresh
M.open = core.open_in_browser
M.status = core.status
M.get_info = core.get_info

-- Expose core functions (Phase 2)
M.pull_epic = core.pull_epic
M.sync = core.sync
M.sync_all = core.sync_all
M.cache_refresh = core.cache_refresh
M.cache_status = core.cache_status
M.list_presets = core.list_presets

-- Expose config functions
M.get_config = config.get
M.is_configured = config.is_configured
M.get_presets = config.get_presets

-- Legacy function for compatibility
M.hello = core.hello

return M
