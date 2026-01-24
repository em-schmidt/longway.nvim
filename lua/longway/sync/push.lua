-- [nfnl] fnl/longway/sync/push.fnl
local config = require("longway.config")
local stories_api = require("longway.api.stories")
local parser = require("longway.markdown.parser")
local notify = require("longway.ui.notify")
local M = {}
M["push-current-buffer"] = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if (filepath == "") then
    notify.error("No file in current buffer")
    return {error = "No file in current buffer", ok = false}
  else
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local content = table.concat(lines, "\n")
    local parsed = parser.parse(content)
    local story_id = parsed.frontmatter.shortcut_id
    local story_type = (parsed.frontmatter.shortcut_type or "story")
    if not story_id then
      notify.error("Not a longway-managed file (no shortcut_id in frontmatter)")
      return {error = "Not a longway-managed file", ok = false}
    else
      if (story_type ~= "story") then
        notify.warn("Only story push is supported in Phase 1")
        return {error = "Epic push not yet implemented", ok = false}
      else
        return M["push-story"](story_id, parsed)
      end
    end
  end
end
M["push-story"] = function(story_id, parsed)
  notify["push-started"]()
  local description = (parsed.description or "")
  local update_data = {description = description}
  local result = stories_api.update(story_id, update_data)
  if result.ok then
    notify["push-completed"]()
    return {ok = true, story = result.data}
  else
    notify["api-error"](result.error, result.status)
    return {error = result.error, ok = false}
  end
end
M["push-file"] = function(filepath)
  local file = io.open(filepath, "r")
  if not file then
    notify.error(string.format("Cannot read file: %s", filepath))
    return {error = "Cannot read file", ok = false}
  else
    local content = file:read("*a")
    local _ = file:close()
    local parsed = parser.parse(content)
    local story_id = parsed.frontmatter.shortcut_id
    if not story_id then
      return {error = "Not a longway-managed file", ok = false}
    else
      return M["push-story"](story_id, parsed)
    end
  end
end
return M
