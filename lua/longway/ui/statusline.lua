-- [nfnl] fnl/longway/ui/statusline.fnl
local config = require("longway.config")
local M = {}
local augroup_name = "longway_statusline"
local setup_done = false
local function refresh_buffer_vars(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if not string.match(filepath, "%.md$") then
    return vim.api.nvim_buf_set_var(bufnr, "longway_id", vim.NIL)
  else
    local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
    if ok then
      local content = table.concat(lines, "\n")
      local parser = require("longway.markdown.parser")
      local parsed = parser.parse(content)
      local fm = parsed.frontmatter
      local shortcut_id = fm.shortcut_id
      if not shortcut_id then
        return vim.api.nvim_buf_set_var(bufnr, "longway_id", vim.NIL)
      else
        local diff = require("longway.sync.diff")
        local first_sync = diff["first-sync?"](fm)
        local sync_status
        if first_sync then
          sync_status = "new"
        else
          local has_conflict = (fm.conflict_sections ~= nil)
          if has_conflict then
            sync_status = "conflict"
          else
            if diff["any-local-change?"](parsed) then
              sync_status = "modified"
            else
              sync_status = "synced"
            end
          end
        end
        vim.api.nvim_buf_set_var(bufnr, "longway_id", shortcut_id)
        vim.api.nvim_buf_set_var(bufnr, "longway_type", (fm.shortcut_type or "story"))
        vim.api.nvim_buf_set_var(bufnr, "longway_state", (fm.state or ""))
        vim.api.nvim_buf_set_var(bufnr, "longway_sync_status", sync_status)
        local function _4_()
          if fm.conflict_sections then
            return true
          else
            return false
          end
        end
        return vim.api.nvim_buf_set_var(bufnr, "longway_conflict", _4_())
      end
    else
      return nil
    end
  end
end
local function get_buf_var(bufnr, name)
  local ok, val = pcall(vim.api.nvim_buf_get_var, bufnr, name)
  if ok then
    return val
  else
    return nil
  end
end
M["is-longway-buffer"] = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local id = get_buf_var(bufnr, "longway_id")
  return ((id ~= nil) and (id ~= vim.NIL))
end
M["get-status"] = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local id = get_buf_var(bufnr, "longway_id")
  if (id and (id ~= vim.NIL)) then
    local sync_status = (get_buf_var(bufnr, "longway_sync_status") or "unknown")
    local display_status
    if (sync_status == "conflict") then
      display_status = "CONFLICT"
    else
      display_status = sync_status
    end
    return string.format("SC:%s [%s]", tostring(id), display_status)
  else
    return nil
  end
end
M["get-status-data"] = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local id = get_buf_var(bufnr, "longway_id")
  if (id and (id ~= vim.NIL)) then
    return {shortcut_id = id, shortcut_type = (get_buf_var(bufnr, "longway_type") or "story"), state = (get_buf_var(bufnr, "longway_state") or ""), sync_status = (get_buf_var(bufnr, "longway_sync_status") or "unknown"), conflict = (get_buf_var(bufnr, "longway_conflict") or false)}
  else
    return nil
  end
end
M["lualine-component"] = function()
  local color_fn
  local function _12_()
    local bufnr = vim.api.nvim_get_current_buf()
    local sync_status = (get_buf_var(bufnr, "longway_sync_status") or "unknown")
    if (sync_status == "synced") then
      return {fg = "#a6e3a1"}
    elseif (sync_status == "modified") then
      return {fg = "#f9e2af"}
    elseif (sync_status == "conflict") then
      return {fg = "#f38ba8"}
    elseif (sync_status == "new") then
      return {fg = "#89b4fa"}
    else
      return {fg = "#cdd6f4"}
    end
  end
  color_fn = _12_
  local tbl = {cond = M["is-longway-buffer"], color = color_fn}
  tbl[1] = M["get-status"]
  return tbl
end
M.setup = function()
  if not setup_done then
    setup_done = true
    local group = vim.api.nvim_create_augroup(augroup_name, {clear = true})
    local function _14_(ev)
      local ok, err = pcall(refresh_buffer_vars, ev.buf)
      if not ok then
        if config.get().debug then
          return vim.notify(("[longway] statusline refresh error: " .. tostring(err)), vim.log.levels.DEBUG)
        else
          return nil
        end
      else
        return nil
      end
    end
    vim.api.nvim_create_autocmd("BufEnter", {group = group, pattern = "*.md", callback = _14_})
    local function _17_(ev)
      local ok, err = pcall(refresh_buffer_vars, ev.buf)
      if not ok then
        if config.get().debug then
          return vim.notify(("[longway] statusline refresh error: " .. tostring(err)), vim.log.levels.DEBUG)
        else
          return nil
        end
      else
        return nil
      end
    end
    return vim.api.nvim_create_autocmd("BufWritePost", {group = group, pattern = "*.md", callback = _17_})
  else
    return nil
  end
end
M.teardown = function()
  local ok, _ = pcall(vim.api.nvim_del_augroup_by_name, augroup_name)
  setup_done = false
  return nil
end
return M
