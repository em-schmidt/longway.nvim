-- Pull operations for longway.nvim
-- Compiled from fnl/longway/sync/pull.fnl

local config = require("longway.config")
local stories_api = require("longway.api.stories")
local epics_api = require("longway.api.epics")
local search_api = require("longway.api.search")
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
  local shortcut_type = parsed.frontmatter.shortcut_type or "story"

  if not story_id then
    notify.error("Not a longway-managed file")
    return { ok = false, error = "Not a longway-managed file" }
  end

  -- Pull fresh data based on type
  if shortcut_type == "epic" then
    -- Epic refresh
    local result = epics_api.get_with_stories(story_id)
    if not result.ok then
      notify.api_error(result.error, result.status)
      return { ok = false, error = result.error }
    end
    local epic = result.data.epic
    local stories = result.data.stories
    local markdown = renderer.render_epic(epic, stories)
    local lines = vim.split(markdown, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    notify.pull_completed(epic.id, epic.name)
    return { ok = true, epic = epic }
  else
    -- Story refresh
    local result = stories_api.get(story_id)
    if not result.ok then
      notify.api_error(result.error, result.status)
      return { ok = false, error = result.error }
    end
    local story = result.data
    local markdown = renderer.render_story(story)
    local lines = vim.split(markdown, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    notify.pull_completed(story.id, story.name)
    return { ok = true, story = story }
  end
end

function M.pull_epic(epic_id)
  notify.info(string.format("Pulling epic %s...", epic_id))

  local result = epics_api.get_with_stories(epic_id)
  if not result.ok then
    notify.api_error(result.error, result.status)
    return { ok = false, error = result.error }
  end

  local epic = result.data.epic
  local stories = result.data.stories
  local epics_dir = config.get_epics_dir()
  local filename = slug.make_filename(epic.id, epic.name, "epic")
  local filepath = epics_dir .. "/" .. filename
  local markdown = renderer.render_epic(epic, stories)

  ensure_directory(epics_dir)

  if write_file(filepath, markdown) then
    notify.pull_completed(epic.id, epic.name)
    return { ok = true, path = filepath, epic = epic, stories = stories }
  else
    notify.error(string.format("Failed to write file: %s", filepath))
    return { ok = false, error = "Failed to write file" }
  end
end

function M.pull_epic_to_buffer(epic_id)
  local result = M.pull_epic(epic_id)
  if result.ok then
    vim.cmd("edit " .. result.path)
  end
  return result
end

function M.sync_stories(query, opts)
  opts = opts or {}
  local max_results = opts.max_results or 100
  notify.info(string.format("Syncing stories matching: %s", query or "all"))

  local result = search_api.search_stories_all(query, { max_results = max_results })
  if not result.ok then
    notify.api_error(result.error)
    return { ok = false, error = result.error, synced = 0, failed = 0 }
  end

  local stories = result.data
  local total = #stories
  notify.info(string.format("Found %d stories to sync", total))

  local synced = 0
  local failed = 0
  local errors = {}

  for _, story in ipairs(stories) do
    local pull_result = M.pull_story(story.id)
    if pull_result.ok then
      synced = synced + 1
    else
      failed = failed + 1
      table.insert(errors, string.format("Story %s: %s", story.id, pull_result.error or "unknown error"))
    end
  end

  notify.info(string.format("Sync complete: %d synced, %d failed", synced, failed))
  return { ok = true, synced = synced, failed = failed, errors = errors, total = total }
end

function M.sync_preset(preset_name)
  local cfg = config.get()
  local presets = cfg.presets or {}
  local preset = presets[preset_name]

  if not preset then
    notify.error(string.format("Preset '%s' not found", preset_name))
    return { ok = false, error = "Preset not found" }
  end

  local query = preset.query or ""
  local opts = { max_results = preset.max_results or 100 }
  notify.info(string.format("Running preset '%s'", preset_name))
  return M.sync_stories(query, opts)
end

function M.sync_all_presets()
  local cfg = config.get()
  local presets = cfg.presets or {}
  local results = {}

  local has_presets = false
  for _ in pairs(presets) do
    has_presets = true
    break
  end

  if not has_presets then
    notify.warn("No presets configured")
    return { ok = false, error = "No presets configured" }
  end

  for name, _ in pairs(presets) do
    results[name] = M.sync_preset(name)
  end

  return { ok = true, results = results }
end

return M
