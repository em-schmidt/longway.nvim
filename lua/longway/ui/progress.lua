-- [nfnl] fnl/longway/ui/progress.fnl
local config = require("longway.config")
local M = {}
local active_progress = {}
local function snacks_available_3f()
  local ok, snacks = pcall(require, "snacks")
  return (ok and (snacks ~= nil) and (snacks.notify ~= nil))
end
M["is-available"] = function()
  return snacks_available_3f()
end
M.start = function(operation, total)
  local progress_id = ("longway_progress_" .. operation)
  local msg = string.format("%s: 0/%d...", operation, total)
  local cfg = config.get()
  active_progress[progress_id] = {operation = operation, total = total, current = 0}
  if cfg.notify then
    if snacks_available_3f() then
      local Snacks = require("snacks")
      Snacks.notify(("[longway] " .. msg), {id = progress_id, title = "longway", level = vim.log.levels.INFO})
    else
      vim.notify(("[longway] " .. msg), vim.log.levels.INFO)
    end
  else
  end
  return progress_id
end
M.update = function(progress_id, current, total, item_name)
  local cfg = config.get()
  if (cfg.notify and cfg.progress) then
    local state = active_progress[progress_id]
    local operation
    if state then
      operation = state.operation
    else
      operation = "Working"
    end
    local msg
    if item_name then
      msg = string.format("%s: %d/%d \226\128\148 %s", operation, current, total, item_name)
    else
      msg = string.format("%s: %d/%d...", operation, current, total)
    end
    if state then
      state["current"] = current
    else
    end
    if snacks_available_3f() then
      local Snacks = require("snacks")
      return Snacks.notify(("[longway] " .. msg), {id = progress_id, title = "longway", level = vim.log.levels.INFO})
    else
      if ((current == 1) or (current == total) or ((current % 5) == 0)) then
        return vim.notify(("[longway] " .. msg), vim.log.levels.INFO)
      else
        return nil
      end
    end
  else
    return nil
  end
end
M.finish = function(progress_id, synced, failed)
  local cfg = config.get()
  local state = active_progress[progress_id]
  local operation
  if state then
    operation = state.operation
  else
    operation = "Operation"
  end
  local msg
  if (failed and (failed > 0)) then
    msg = string.format("%s complete: %d synced, %d failed", operation, synced, failed)
  else
    msg = string.format("%s complete: %d synced", operation, synced)
  end
  active_progress[progress_id] = nil
  if cfg.notify then
    if snacks_available_3f() then
      local Snacks = require("snacks")
      return Snacks.notify(("[longway] " .. msg), {id = progress_id, title = "longway", level = vim.log.levels.INFO, timeout = 3000})
    else
      return vim.notify(("[longway] " .. msg), vim.log.levels.INFO)
    end
  else
    return nil
  end
end
return M
