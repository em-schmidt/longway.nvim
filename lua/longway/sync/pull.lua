-- [nfnl] fnl/longway/sync/pull.fnl
local config = require("longway.config")
local stories_api = require("longway.api.stories")
local comments_api = require("longway.api.comments")
local epics_api = require("longway.api.epics")
local search_api = require("longway.api.search")
local comments_md = require("longway.markdown.comments")
local renderer = require("longway.markdown.renderer")
local slug = require("longway.util.slug")
local notify = require("longway.ui.notify")
local M = {}
local function ensure_directory(path)
  local exists = vim.fn.isdirectory(path)
  if (exists == 0) then
    return vim.fn.mkdir(path, "p")
  else
    return nil
  end
end
local function write_file(path, content)
  local file = io.open(path, "w")
  if file then
    file:write(content)
    file:close()
    return true
  else
    return nil
  end
end
local function fetch_story_comments(story)
  do
    local cfg = config.get()
    if cfg.sync_sections.comments then
      local result = comments_api.list(story.id)
      if result.ok then
        local raw_comments = (result.data or {})
        local limited
        if (cfg.comments.max_pull and (#raw_comments > cfg.comments.max_pull)) then
          local trimmed = {}
          for i = 1, cfg.comments.max_pull do
            table.insert(trimmed, raw_comments[i])
          end
          limited = trimmed
        else
          limited = raw_comments
        end
        local formatted = comments_md["format-api-comments"](limited)
        story.comments = formatted
      else
      end
    else
    end
  end
  return story
end
M["pull-story"] = function(story_id)
  notify["pull-started"](story_id)
  local result = stories_api.get(story_id)
  if not result.ok then
    notify["api-error"](result.error, result.status)
    return {error = result.error, ok = false}
  else
    local story = fetch_story_comments(result.data)
    local stories_dir = config["get-stories-dir"]()
    local filename = slug["make-filename"](story.id, story.name, "story")
    local filepath = (stories_dir .. "/" .. filename)
    local markdown = renderer["render-story"](story)
    ensure_directory(stories_dir)
    if write_file(filepath, markdown) then
      notify["pull-completed"](story.id, story.name)
      return {ok = true, path = filepath, story = story}
    else
      notify.error(string.format("Failed to write file: %s", filepath))
      return {error = "Failed to write file", ok = false}
    end
  end
end
M["pull-story-to-buffer"] = function(story_id)
  local result = M["pull-story"](story_id)
  if result.ok then
    vim.cmd(("edit " .. result.path))
  else
  end
  return result
end
M["refresh-current-buffer"] = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if (filepath == "") then
    notify.error("No file in current buffer")
    return {error = "No file in current buffer", ok = false}
  else
    local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
    local parser = require("longway.markdown.parser")
    local parsed = parser.parse(content)
    local story_id = parsed.frontmatter.shortcut_id
    local shortcut_type = (parsed.frontmatter.shortcut_type or "story")
    if not story_id then
      notify.error("Not a longway-managed file")
      return {error = "Not a longway-managed file", ok = false}
    else
      if (shortcut_type == "epic") then
        local result = epics_api["get-with-stories"](story_id)
        if not result.ok then
          notify["api-error"](result.error, result.status)
          return {error = result.error, ok = false}
        else
          local epic = result.data.epic
          local stories = result.data.stories
          local markdown = renderer["render-epic"](epic, stories)
          local lines = vim.split(markdown, "\n", {plain = true})
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
          notify["pull-completed"](epic.id, epic.name)
          return {ok = true, epic = epic}
        end
      else
        local result = stories_api.get(story_id)
        if not result.ok then
          notify["api-error"](result.error, result.status)
          return {error = result.error, ok = false}
        else
          local story = fetch_story_comments(result.data)
          local markdown = renderer["render-story"](story)
          local lines = vim.split(markdown, "\n", {plain = true})
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
          notify["pull-completed"](story.id, story.name)
          return {ok = true, story = story}
        end
      end
    end
  end
end
M["pull-epic"] = function(epic_id)
  notify.info(string.format("Pulling epic %s...", epic_id))
  local result = epics_api["get-with-stories"](epic_id)
  if not result.ok then
    notify["api-error"](result.error, result.status)
    return {error = result.error, ok = false}
  else
    local epic = result.data.epic
    local stories = result.data.stories
    local epics_dir = config["get-epics-dir"]()
    local filename = slug["make-filename"](epic.id, epic.name, "epic")
    local filepath = (epics_dir .. "/" .. filename)
    local markdown = renderer["render-epic"](epic, stories)
    ensure_directory(epics_dir)
    if write_file(filepath, markdown) then
      notify["pull-completed"](epic.id, epic.name)
      return {ok = true, path = filepath, epic = epic, stories = stories}
    else
      notify.error(string.format("Failed to write file: %s", filepath))
      return {error = "Failed to write file", ok = false}
    end
  end
end
M["pull-epic-to-buffer"] = function(epic_id)
  local result = M["pull-epic"](epic_id)
  if result.ok then
    vim.cmd(("edit " .. result.path))
  else
  end
  return result
end
M["sync-stories"] = function(query, opts)
  local opts0 = (opts or {})
  local max_results = (opts0.max_results or 100)
  notify.info(string.format("Syncing stories matching: %s", (query or "all")))
  local result = search_api["search-stories-all"](query, {max_results = max_results})
  if not result.ok then
    notify["api-error"](result.error)
    return {error = result.error, synced = 0, failed = 0, ok = false}
  else
    local stories = result.data
    local total = #stories
    local synced_count = vim.fn.ref(0)
    local failed_count = vim.fn.ref(0)
    local errors = {}
    notify.info(string.format("Found %d stories to sync", total))
    for i, story in ipairs(stories) do
      local pull_result = M["pull-story"](story.id)
      if pull_result.ok then
        vim.fn.setreg(synced_count, (vim.fn.getreg(synced_count) + 1))
      else
        vim.fn.setreg(failed_count, (vim.fn.getreg(failed_count) + 1))
        table.insert(errors, string.format("Story %s: %s", story.id, (pull_result.error or "unknown error")))
      end
    end
    local synced = vim.fn.getreg(synced_count)
    local failed = vim.fn.getreg(failed_count)
    notify.info(string.format("Sync complete: %d synced, %d failed", synced, failed))
    return {ok = true, synced = synced, failed = failed, errors = errors, total = total}
  end
end
M["sync-preset"] = function(preset_name)
  local cfg = config.get()
  local presets = (cfg.presets or {})
  local preset = presets[preset_name]
  if not preset then
    notify.error(string.format("Preset '%s' not found", preset_name))
    return {error = "Preset not found", ok = false}
  else
    local query = (preset.query or "")
    local opts = {max_results = (preset.max_results or 100)}
    notify.info(string.format("Running preset '%s'", preset_name))
    return M["sync-stories"](query, opts)
  end
end
M["sync-all-presets"] = function()
  local cfg = config.get()
  local presets = (cfg.presets or {})
  local results = {}
  if (next(presets) == nil) then
    notify.warn("No presets configured")
    return {error = "No presets configured", ok = false}
  else
    for name, _ in pairs(presets) do
      results[name] = M["sync-preset"](name)
    end
    return {ok = true, results = results}
  end
end
return M
