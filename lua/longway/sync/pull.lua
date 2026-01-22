-- Pull operations for longway.nvim
-- Compiled from fnl/longway/sync/pull.fnl

local config = require("longway.config")
local stories_api = require("longway.api.stories")
local renderer = require("longway.markdown.renderer")
local slug = require("longway.util.slug")
local notify = require("longway.ui.notify")

local M = {}

local function ensure_directory(path)
  local exists = vim.fn.isdirectory(path)
  if exists == 0 then
    vim.fn.mkdir(path, "p")
  end
end

local function write_file(path, content)
  local file = io.open(path, "w")
  if file then
    file:write(content)
    file:close()
    return true
  end
  return false
end

function M.pull_story(story_id)
  notify.pull_started(story_id)

  local result = stories_api.get(story_id)
  if not result.ok then
    notify.api_error(result.error, result.status)
    return { ok = false, error = result.error }
  end

  -- Got the story
  local story = result.data
  local stories_dir = config.get_stories_dir()
  local filename = slug.make_filename(story.id, story.name, "story")
  local filepath = stories_dir .. "/" .. filename
  local markdown = renderer.render_story(story)

  -- Ensure directory exists
  ensure_directory(stories_dir)

  -- Write the file
  if write_file(filepath, markdown) then
    notify.pull_completed(story.id, story.name)
    return { ok = true, path = filepath, story = story }
  else
    notify.error(string.format("Failed to write file: %s", filepath))
    return { ok = false, error = "Failed to write file" }
  end
end

function M.pull_story_to_buffer(story_id)
  local result = M.pull_story(story_id)
  if result.ok then
    vim.cmd("edit " .. result.path)
  end
  return result
end

function M.refresh_current_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  if filepath == "" then
    notify.error("No file in current buffer")
    return { ok = false, error = "No file in current buffer" }
  end

  -- Read current content to get shortcut_id
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local parser = require("longway.markdown.parser")
  local parsed = parser.parse(content)
  local story_id = parsed.frontmatter.shortcut_id

  if not story_id then
    notify.error("Not a longway-managed file")
    return { ok = false, error = "Not a longway-managed file" }
  end

  -- Pull fresh data
  local result = stories_api.get(story_id)
  if not result.ok then
    notify.api_error(result.error, result.status)
    return { ok = false, error = result.error }
  end

  -- Update the buffer
  local story = result.data
  local markdown = renderer.render_story(story)
  local lines = vim.split(markdown, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  notify.pull_completed(story.id, story.name)
  return { ok = true, story = story }
end

return M
