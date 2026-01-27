-- [nfnl] fnl/longway/sync/resolve.fnl
local config = require("longway.config")
local notify = require("longway.ui.notify")
local parser = require("longway.markdown.parser")
local frontmatter = require("longway.markdown.frontmatter")
local M = {}
local function get_buffer_parsed(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  return parser.parse(content)
end
local function update_buffer_frontmatter(bufnr, new_fm_data)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local parsed_fm = frontmatter.parse(content)
  for k, v in pairs(new_fm_data) do
    parsed_fm.frontmatter[k] = v
  end
  local new_fm_str = frontmatter.generate(parsed_fm.frontmatter)
  local new_content = (new_fm_str .. "\n\n" .. parsed_fm.body)
  local new_lines = vim.split(new_content, "\n", {plain = true})
  return vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end
M["resolve-local"] = function(shortcut_id, parsed, bufnr)
  local push = require("longway.sync.push")
  local result = push["push-story"](shortcut_id, parsed, {force = true, bufnr = bufnr})
  if result.ok then
    notify.info("Conflict resolved: local changes pushed to Shortcut")
    return {ok = true}
  else
    return {error = (result.error or "Push failed"), ok = false}
  end
end
M["resolve-remote"] = function(shortcut_id, bufnr)
  local pull = require("longway.sync.pull")
  local result = pull["refresh-current-buffer"]()
  if result.ok then
    notify.info("Conflict resolved: remote content pulled from Shortcut")
    return {ok = true}
  else
    return {error = (result.error or "Pull failed"), ok = false}
  end
end
M["resolve-manual"] = function(shortcut_id, bufnr)
  local stories_api = require("longway.api.stories")
  local remote_result = stories_api.get(shortcut_id)
  if not remote_result.ok then
    return {error = (remote_result.error or "Failed to fetch remote story"), ok = false}
  else
    local cfg = config.get()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local start_marker = string.gsub(cfg.sync_start_marker, "{section}", "description")
    local end_marker = string.gsub(cfg.sync_end_marker, "{section}", "description")
    local start_escaped = string.gsub(start_marker, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
    local end_escaped = string.gsub(end_marker, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
    local start_line = nil
    local end_line = nil
    for i, line in ipairs(lines) do
      if string.match(line, start_escaped) then
        start_line = i
      else
      end
      if (start_line and not end_line and string.match(line, end_escaped)) then
        end_line = i
      else
      end
    end
    if not (start_line and end_line) then
      return {error = "Could not find description sync section", ok = false}
    else
      local local_desc_lines = {}
      local _
      for i = (start_line + 1), (end_line - 1) do
        table.insert(local_desc_lines, lines[i])
      end
      _ = nil
      local local_desc = table.concat(local_desc_lines, "\n")
      local remote_desc = (remote_result.data.description or "")
      local remote_ts = (remote_result.data.updated_at or "unknown")
      local conflict_lines = {start_marker, "<!-- CONFLICT: Local version -->", local_desc, string.format("<!-- CONFLICT: Remote version (updated %s) -->", remote_ts), remote_desc, "<!-- END CONFLICT -- edit above, then :LongwayPush to resolve -->", end_marker}
      vim.api.nvim_buf_set_lines(bufnr, (start_line - 1), end_line, false, conflict_lines)
      update_buffer_frontmatter(bufnr, {conflict_sections = nil})
      notify.info("Conflict markers inserted. Edit the description, then :LongwayPush to resolve.")
      return {ok = true}
    end
  end
end
M.resolve = function(strategy, opts)
  local opts0 = (opts or {})
  local bufnr = (opts0.bufnr or vim.api.nvim_get_current_buf())
  local parsed = get_buffer_parsed(bufnr)
  local shortcut_id
  if parsed then
    shortcut_id = parsed.frontmatter.shortcut_id
  else
    shortcut_id = nil
  end
  if not shortcut_id then
    notify.error("Not a longway-managed file (no shortcut_id)")
    return {error = "Not a longway-managed file", ok = false}
  else
    local conflict_sections = parsed.frontmatter.conflict_sections
    if (not conflict_sections and (strategy ~= "manual")) then
      notify.warn("No conflict detected. Use :LongwayPush or :LongwayRefresh instead.")
      return {error = "No conflict detected", ok = false}
    else
      if (strategy == "local") then
        return M["resolve-local"](shortcut_id, parsed, bufnr)
      elseif (strategy == "remote") then
        return M["resolve-remote"](shortcut_id, bufnr)
      elseif (strategy == "manual") then
        return M["resolve-manual"](shortcut_id, bufnr)
      else
        local _ = strategy
        notify.error(string.format("Unknown resolve strategy: %s. Use local, remote, or manual.", strategy))
        return {error = string.format("Unknown strategy: %s", strategy), ok = false}
      end
    end
  end
end
return M
