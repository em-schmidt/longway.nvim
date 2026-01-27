-- [nfnl] fnl/longway/ui/notify.fnl
local config = require("longway.config")
local M = {}
M.levels = {debug = vim.log.levels.DEBUG, info = vim.log.levels.INFO, warn = vim.log.levels.WARN, error = vim.log.levels.ERROR}
local function snacks_available_3f()
  local ok, snacks = pcall(require, "snacks")
  return (ok and (snacks ~= nil) and (snacks.notify ~= nil))
end
M.notify = function(msg, level, opts)
  local cfg = config.get()
  local level0 = (level or vim.log.levels.INFO)
  if cfg.notify then
    if (level0 >= (cfg.notify_level or vim.log.levels.INFO)) then
      if (opts and snacks_available_3f()) then
        local Snacks = require("snacks")
        local snacks_opts = vim.tbl_extend("force", {title = "longway"}, opts)
        return Snacks.notify(("[longway] " .. msg), snacks_opts)
      else
        return vim.notify(("[longway] " .. msg), level0)
      end
    else
      return nil
    end
  else
    return nil
  end
end
M.debug = function(msg)
  local cfg = config.get()
  if cfg.debug then
    return M.notify(msg, vim.log.levels.DEBUG)
  else
    return nil
  end
end
M.info = function(msg)
  return M.notify(msg, vim.log.levels.INFO)
end
M.warn = function(msg)
  return M.notify(msg, vim.log.levels.WARN)
end
M.error = function(msg)
  return M.notify(msg, vim.log.levels.ERROR)
end
M.success = function(msg)
  return M.info(msg)
end
M["sync-started"] = function(count)
  if (count == 1) then
    return M.info("Syncing 1 item...")
  else
    return M.info(string.format("Syncing %d items...", count))
  end
end
M["sync-completed"] = function(count)
  if (count == 1) then
    return M.success("Synced 1 item")
  else
    return M.success(string.format("Synced %d items", count))
  end
end
M["push-started"] = function()
  return M.info("Pushing changes to Shortcut...")
end
M["push-completed"] = function()
  return M.success("Changes pushed to Shortcut")
end
M["pull-started"] = function(id)
  return M.info(string.format("Pulling story %s from Shortcut...", tostring(id)))
end
M["pull-completed"] = function(id, name)
  return M.success(string.format("Pulled: %s", (name or tostring(id))))
end
M["conflict-detected"] = function(id)
  return M.warn(string.format("Conflict detected for story %s. Use :LongwayResolve to resolve.", tostring(id)))
end
M["api-error"] = function(msg, status)
  if status then
    return M.error(string.format("API error (%d): %s", status, msg))
  else
    return M.error(string.format("API error: %s", msg))
  end
end
M["no-token"] = function()
  return M.error("No Shortcut API token configured. Set SHORTCUT_API_TOKEN or configure token in setup()")
end
M["picker-error"] = function()
  return M.error("snacks.nvim is required for :LongwayPicker. Install folke/snacks.nvim")
end
return M
