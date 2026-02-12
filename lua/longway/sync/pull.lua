-- [nfnl] fnl/longway/sync/pull.fnl
local config = require("longway.config")
local stories_api = require("longway.api.stories")
local comments_api = require("longway.api.comments")
local epics_api = require("longway.api.epics")
local members_api = require("longway.api.members")
local workflows_api = require("longway.api.workflows")
local search_api = require("longway.api.search")
local comments_md = require("longway.markdown.comments")
local parser = require("longway.markdown.parser")
local renderer = require("longway.markdown.renderer")
local slug = require("longway.util.slug")
local notify = require("longway.ui.notify")
local progress = require("longway.ui.progress")
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
local function enrich_story_slim(story)
  if (story.workflow_state_id and not story.workflow_state_name) then
    story.workflow_state_name = workflows_api["resolve-state-name"](story.workflow_state_id)
  else
  end
  if (story.owner_ids and not story.owners and (#story.owner_ids > 0)) then
    local owners = {}
    for _, owner_id in ipairs(story.owner_ids) do
      local name = members_api["resolve-name"](owner_id)
      table.insert(owners, {id = owner_id, profile = {name = name}})
    end
    story.owners = owners
  else
  end
  return story
end
local function enrich_epic_stories(stories)
  for _, story in ipairs(stories) do
    enrich_story_slim(story)
  end
  return stories
end
local function preserve_local_notes(new_markdown, old_local_notes)
  if not old_local_notes then
    return new_markdown
  else
    local template = renderer["render-local-notes"]()
    local start, _end = string.find(new_markdown, template, 1, true)
    if start then
      return (string.sub(new_markdown, 1, (start - 1)) .. old_local_notes .. string.sub(new_markdown, (_end + 1)))
    else
      return new_markdown
    end
  end
end
M["pull-story"] = function(story_id, opts)
  local silent = (opts and opts.silent)
  if not silent then
    notify["pull-started"](story_id)
  else
  end
  local result = stories_api.get(story_id)
  if not result.ok then
    if not silent then
      notify["api-error"](result.error, result.status)
    else
    end
    return {error = result.error, ok = false}
  else
    local story = fetch_story_comments(result.data)
    local stories_dir = config["get-stories-dir"]()
    local filename = slug["make-filename"](story.id, story.name, "story")
    local filepath = (stories_dir .. "/" .. filename)
    local markdown = renderer["render-story"](story)
    local old_local_notes
    if (vim.fn.filereadable(filepath) == 1) then
      local f = io.open(filepath, "r")
      if f then
        local existing = f:read("*a")
        f:close()
        old_local_notes = parser["extract-local-notes"](existing)
      else
        old_local_notes = nil
      end
    else
      old_local_notes = nil
    end
    local final_markdown = preserve_local_notes(markdown, old_local_notes)
    ensure_directory(stories_dir)
    if write_file(filepath, final_markdown) then
      if not silent then
        notify["pull-completed"](story.id, story.name)
      else
      end
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
    vim.cmd(("confirm edit " .. vim.fn.fnameescape(result.path)))
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
    local parsed = parser.parse(content)
    local story_id = parsed.frontmatter.shortcut_id
    local shortcut_type = (parsed.frontmatter.shortcut_type or "story")
    if not story_id then
      notify.error("Not a longway-managed file")
      return {error = "Not a longway-managed file", ok = false}
    else
      local old_local_notes = parser["extract-local-notes"](content)
      if (shortcut_type == "epic") then
        local result = epics_api["get-with-stories"](story_id)
        if not result.ok then
          notify["api-error"](result.error, result.status)
          return {error = result.error, ok = false}
        else
          local epic = result.data.epic
          local stories = enrich_epic_stories((result.data.stories or {}))
          local markdown = renderer["render-epic"](epic, stories)
          local final_markdown = preserve_local_notes(markdown, old_local_notes)
          local lines = vim.split(final_markdown, "\n", {plain = true})
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
          local final_markdown = preserve_local_notes(markdown, old_local_notes)
          local lines = vim.split(final_markdown, "\n", {plain = true})
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
    local stories = enrich_epic_stories((result.data.stories or {}))
    local epics_dir = config["get-epics-dir"]()
    local filename = slug["make-filename"](epic.id, epic.name, "epic")
    local filepath = (epics_dir .. "/" .. filename)
    local markdown = renderer["render-epic"](epic, stories)
    local old_local_notes
    if (vim.fn.filereadable(filepath) == 1) then
      local f = io.open(filepath, "r")
      if f then
        local existing = f:read("*a")
        f:close()
        old_local_notes = parser["extract-local-notes"](existing)
      else
        old_local_notes = nil
      end
    else
      old_local_notes = nil
    end
    local final_markdown = preserve_local_notes(markdown, old_local_notes)
    ensure_directory(epics_dir)
    if write_file(filepath, final_markdown) then
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
    vim.cmd(("confirm edit " .. vim.fn.fnameescape(result.path)))
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
    local progress_id = progress.start("Syncing", total)
    local errors = {}
    local synced_count, failed_count
    do
      local synced, failed = 0, 0
      for i, story in ipairs(stories) do
        progress.update(progress_id, i, total, (story.name or tostring(story.id)))
        vim.cmd.redraw()
        local pull_result = M["pull-story"](story.id, {silent = true})
        if pull_result.ok then
          synced, failed = (synced + 1), failed
        else
          table.insert(errors, string.format("Story %s: %s", story.id, (pull_result.error or "unknown error")))
          synced, failed = synced, (failed + 1)
        end
      end
      synced_count, failed_count = synced, failed
    end
    progress.finish(progress_id, synced_count, failed_count)
    return {ok = true, synced = synced_count, failed = failed_count, errors = errors, total = total}
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
    local preset_names = vim.tbl_keys(presets)
    local total = #preset_names
    local progress_id = progress.start("Syncing presets", total)
    for i, name in ipairs(preset_names) do
      progress.update(progress_id, i, total, name)
      results[name] = M["sync-preset"](name)
    end
    progress.finish(progress_id, total, 0)
    return {ok = true, results = results}
  end
end
return M
