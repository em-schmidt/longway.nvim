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

-- Expose core functions
M.pull = core.pull
M.push = core.push
M.refresh = core.refresh
M.open = core.open_in_browser
M.status = core.status
M.get_info = core.get_info

-- Expose config functions
M.get_config = config.get
M.is_configured = config.is_configured

-- Legacy function for compatibility
M.hello = core.hello

return M
