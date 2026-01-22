-- Push operations for longway.nvim
-- Compiled from fnl/longway/sync/push.fnl

local config = require("longway.config")
local stories_api = require("longway.api.stories")
local parser = require("longway.markdown.parser")
local notify = require("longway.ui.notify")

local M = {}

function M.push_current_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  if filepath == "" then
    notify.error("No file in current buffer")
    return { ok = false, error = "No file in current buffer" }
  end

  -- Read buffer content
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local parsed = parser.parse(content)
  local story_id = parsed.frontmatter.shortcut_id
  local story_type = parsed.frontmatter.shortcut_type or "story"

  if not story_id then
    notify.error("Not a longway-managed file (no shortcut_id in frontmatter)")
    return { ok = false, error = "Not a longway-managed file" }
  end

  if story_type ~= "story" then
    notify.warn("Only story push is supported in Phase 1")
    return { ok = false, error = "Epic push not yet implemented" }
  end

  -- Push story description
  return M.push_story(story_id, parsed)
end

function M.push_story(story_id, parsed)
  notify.push_started()

  -- For Phase 1, we only push description changes
  local description = parsed.description or ""
  local update_data = { description = description }
  local result = stories_api.update(story_id, update_data)

  if result.ok then
    notify.push_completed()
    return { ok = true, story = result.data }
  else
    notify.api_error(result.error, result.status)
    return { ok = false, error = result.error }
  end
end

function M.push_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    notify.error(string.format("Cannot read file: %s", filepath))
    return { ok = false, error = "Cannot read file" }
  end

  local content = file:read("*a")
  file:close()

  local parsed = parser.parse(content)
  local story_id = parsed.frontmatter.shortcut_id

  if not story_id then
    return { ok = false, error = "Not a longway-managed file" }
  end

  return M.push_story(story_id, parsed)
end

return M
