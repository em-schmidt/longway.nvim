-- [nfnl] fnl/longway/ui/diagnostics.fnl
local M = {}
local augroup_id = nil
local known_headers = {Description = true, Tasks = true, Comments = true, ["Local Notes"] = true, Stories = true}
local ns = vim.api.nvim_create_namespace("longway")
local function find_title_line(lines)
  local in_frontmatter = false
  local past_frontmatter = false
  local result = nil
  for i, line in ipairs(lines) do
    if result then break end
    local idx = (i - 1)
    if ((i == 1) and (line == "---")) then
      in_frontmatter = true
    elseif (in_frontmatter and (line == "---")) then
      in_frontmatter = false
      past_frontmatter = true
    elseif (not in_frontmatter and string.match(line, "^# ")) then
      result = idx
    else
    end
  end
  return result
end
local function check_buffer(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local content = table.concat(lines, "\n")
    local frontmatter = require("longway.markdown.frontmatter")
    local parsed = frontmatter.parse(content)
    if not parsed.frontmatter.shortcut_id then
      return vim.diagnostic.set(ns, bufnr, {})
    else
      local diagnostics = {}
      local title_line = find_title_line(lines)
      for i, line in ipairs(lines) do
        local lnum = (i - 1)
        if (string.match(line, "^# [^#]") and (lnum ~= title_line)) then
          table.insert(diagnostics, {lnum = lnum, col = 0, severity = vim.diagnostic.severity.WARN, source = "longway", message = "Top-level heading (# ) may break section parsing \226\128\148 use ## or lower"})
        else
        end
        local header_name = string.match(line, "^## (.+)$")
        if (header_name and not known_headers[header_name]) then
          table.insert(diagnostics, {lnum = lnum, col = 0, severity = vim.diagnostic.severity.WARN, source = "longway", message = "Unsupported heading level in synced section \226\128\148 use ### or lower to avoid parsing issues"})
        else
        end
      end
      return vim.diagnostic.set(ns, bufnr, diagnostics)
    end
  else
    return nil
  end
end
local function on_buf_event(ev)
  return check_buffer(ev.buf)
end
M.setup = function()
  M.teardown()
  augroup_id = vim.api.nvim_create_augroup("longway_diagnostics", {clear = true})
  return vim.api.nvim_create_autocmd({"BufEnter", "TextChanged", "TextChangedI"}, {group = augroup_id, pattern = "*.md", callback = on_buf_event, desc = "longway.nvim: header diagnostics for synced sections"})
end
M.teardown = function()
  if augroup_id then
    vim.api.nvim_del_augroup_by_id(augroup_id)
    augroup_id = nil
    return nil
  else
    return nil
  end
end
M.check = function(bufnr)
  return check_buffer((bufnr or vim.api.nvim_get_current_buf()))
end
return M
