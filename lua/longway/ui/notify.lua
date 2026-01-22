-- Notification helpers for longway.nvim
-- Compiled from fnl/longway/ui/notify.fnl

local config = require("longway.config")

local M = {}

M.levels = {
  debug = vim.log.levels.DEBUG,
  info = vim.log.levels.INFO,
  warn = vim.log.levels.WARN,
  error = vim.log.levels.ERROR,
}

function M.notify(msg, level)
  local cfg = config.get()
  level = level or vim.log.levels.INFO
  if cfg.notify then
    if level >= (cfg.notify_level or vim.log.levels.INFO) then
      vim.notify("[longway] " .. msg, level)
    end
  end
end

function M.debug(msg)
  local cfg = config.get()
  if cfg.debug then
    M.notify(msg, vim.log.levels.DEBUG)
  end
end

function M.info(msg)
  M.notify(msg, vim.log.levels.INFO)
end

function M.warn(msg)
  M.notify(msg, vim.log.levels.WARN)
end

function M.error(msg)
  M.notify(msg, vim.log.levels.ERROR)
end

function M.success(msg)
  M.info(msg)
end

function M.sync_started(count)
  if count == 1 then
    M.info("Syncing 1 item...")
  else
    M.info(string.format("Syncing %d items...", count))
  end
end

function M.sync_completed(count)
  if count == 1 then
    M.success("Synced 1 item")
  else
    M.success(string.format("Synced %d items", count))
  end
end

function M.push_started()
  M.info("Pushing changes to Shortcut...")
end

function M.push_completed()
  M.success("Changes pushed to Shortcut")
end

function M.pull_started(id)
  M.info(string.format("Pulling story %s from Shortcut...", tostring(id)))
end

function M.pull_completed(id, name)
  M.success(string.format("Pulled: %s", name or tostring(id)))
end

function M.conflict_detected(id)
  M.warn(string.format("Conflict detected for story %s. Use :LongwayResolve to resolve.", tostring(id)))
end

function M.api_error(msg, status)
  if status then
    M.error(string.format("API error (%d): %s", status, msg))
  else
    M.error(string.format("API error: %s", msg))
  end
end

function M.no_token()
  M.error("No Shortcut API token configured. Set SHORTCUT_API_TOKEN or configure token in setup()")
end

return M
