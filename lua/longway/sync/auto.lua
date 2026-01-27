-- [nfnl] fnl/longway/sync/auto.fnl
local config = require("longway.config")
local notify = require("longway.ui.notify")
local M = {}
local augroup_id = nil
local timers = {}
M["is-active"] = function()
  return (augroup_id ~= nil)
end
local function cancel_timer(bufnr)
  local timer = timers[bufnr]
  if timer then
    if timer:is_active() then
      timer:stop()
    else
    end
    timer:close()
    timers[bufnr] = nil
    return nil
  else
    return nil
  end
end
local function schedule_push(bufnr)
  local cfg = config.get()
  local delay = (cfg.auto_push_delay or 2000)
  cancel_timer(bufnr)
  local timer = vim.uv.new_timer()
  timers[bufnr] = timer
  local function _3_()
    timers[bufnr] = nil
    if timer:is_active() then
      timer:stop()
    else
    end
    timer:close()
    if vim.api.nvim_buf_is_valid(bufnr) then
      local diff = require("longway.sync.diff")
      local parser = require("longway.markdown.parser")
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local content = table.concat(lines, "\n")
      local parsed = parser.parse(content)
      local any_change_3f = diff["any-local-change?"]
      if (parsed.frontmatter.shortcut_id and any_change_3f(parsed)) then
        local push = require("longway.sync.push")
        notify.debug("Auto-pushing changes...")
        return push["push-current-buffer"]()
      else
        return nil
      end
    else
      return nil
    end
  end
  return timer:start(delay, 0, vim.schedule_wrap(_3_))
end
local function on_buf_write(ev)
  local bufnr = ev.buf
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local workspace_dir = config["get-workspace-dir"]()
  if ((filepath ~= "") and string.find(filepath, workspace_dir, 1, true)) then
    local parser = require("longway.markdown.parser")
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local content = table.concat(lines, "\n")
    local parsed = parser.parse(content)
    if (parsed.frontmatter and parsed.frontmatter.shortcut_id) then
      return schedule_push(bufnr)
    else
      return nil
    end
  else
    return nil
  end
end
M.setup = function()
  M.teardown()
  augroup_id = vim.api.nvim_create_augroup("longway_auto_push", {clear = true})
  vim.api.nvim_create_autocmd("BufWritePost", {group = augroup_id, pattern = "*.md", callback = on_buf_write, desc = "longway.nvim: auto-push on save"})
  return notify.debug("Auto-push on save enabled")
end
M.teardown = function()
  for bufnr, _ in pairs(timers) do
    cancel_timer(bufnr)
  end
  timers = {}
  if augroup_id then
    vim.api.nvim_del_augroup_by_id(augroup_id)
    augroup_id = nil
    return nil
  else
    return nil
  end
end
return M
