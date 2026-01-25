local config = require("longway.config")
local stories_api = require("longway.api.stories")
local parser = require("longway.markdown.parser")
local notify = require("longway.ui.notify")
local tasks_sync = require("longway.sync.tasks")
local tasks_md = require("longway.markdown.tasks")
local confirm = require("longway.ui.confirm")
local hash = require("longway.util.hash")
local frontmatter = require("longway.markdown.frontmatter")
local M = {}
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
local function update_buffer_tasks(bufnr, tasks)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local cfg = config.get()
  local start_marker = string.gsub(cfg.sync_start_marker, "{section}", "tasks")
  local end_marker = string.gsub(cfg.sync_end_marker, "{section}", "tasks")
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
  if (start_line and end_line) then
    local new_task_content = tasks_md["render-tasks"](tasks)
    local new_section_lines = {start_marker}
    local task_lines = vim.split(new_task_content, "\n", {plain = true})
    for _, line in ipairs(task_lines) do
      table.insert(new_section_lines, line)
    end
    table.insert(new_section_lines, end_marker)
    return vim.api.nvim_buf_set_lines(bufnr, (start_line - 1), end_line, false, new_section_lines)
  else
    return nil
  end
end
local function push_story_description(story_id, description)
  local update_data = {description = description}
  local result = stories_api.update(story_id, update_data)
  if result.ok then
    return {ok = true, story = result.data}
  else
    return {error = result.error, status = result.status, ok = false}
  end
end
local function push_story_tasks(story_id, local_tasks, opts)
  local cfg = config.get()
  local story_result = stories_api.get(story_id)
  if not story_result.ok then
    return {error = story_result.error, ok = false}
  else
    local remote_tasks = (story_result.data.tasks or {})
    local diff = tasks_sync.diff(local_tasks, remote_tasks)
    if ((#diff.deleted > 0) and cfg.tasks.confirm_delete and not opts.skip_confirm) then
      return tasks_sync.push(story_id, local_tasks, remote_tasks, {skip_delete = false})
    else
      return tasks_sync.push(story_id, local_tasks, remote_tasks, {skip_delete = (opts.skip_delete or false)})
    end
  end
end
M["push-story"] = function(story_id, parsed, opts)
  local opts0 = (opts or {})
  local cfg = config.get()
  local bufnr = (opts0.bufnr or vim.api.nvim_get_current_buf())
  local errors = {}
  local results = {}
  notify["push-started"]()
  do
    local description = (parsed.description or "")
    local desc_result = push_story_description(story_id, description)
    results.description = desc_result
    if not desc_result.ok then
      table.insert(errors, string.format("Description: %s", (desc_result.error or "unknown")))
    else
    end
  end
  if (cfg.sync_sections.tasks and (opts0.sync_tasks or (opts0.sync_tasks ~= false))) then
    local local_tasks = (parsed.tasks or {})
    if (#local_tasks > 0) then
      local tasks_result = push_story_tasks(story_id, local_tasks, opts0)
      results.tasks = tasks_result
      if tasks_result.ok then
        if (tasks_result.tasks and (#tasks_result.tasks > 0)) then
          update_buffer_tasks(bufnr, tasks_result.tasks)
          local new_hash = hash["tasks-hash"](tasks_result.tasks)
          update_buffer_frontmatter(bufnr, {tasks_hash = new_hash})
        else
        end
      else
        table.insert(errors, string.format("Tasks: %s", (tasks_result.error or table.concat((tasks_result.errors or {}), ", "))))
      end
    else
    end
  else
  end
  if (#errors == 0) then
    notify["push-completed"]()
    return {ok = true, results = results}
  else
    notify.error(string.format("Push completed with errors: %s", table.concat(errors, "; ")))
    return {errors = errors, results = results, ok = false}
  end
end
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
        notify.warn("Only story push is supported currently")
        return {error = "Epic push not yet implemented", ok = false}
      else
        return M["push-story"](story_id, parsed, {bufnr = bufnr})
      end
    end
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
      return M["push-story"](story_id, parsed, {})
    end
  end
end
return M
