-- [nfnl] fnl/longway/sync/push.fnl
local config = require("longway.config")
local stories_api = require("longway.api.stories")
local parser = require("longway.markdown.parser")
local notify = require("longway.ui.notify")
local tasks_sync = require("longway.sync.tasks")
local tasks_md = require("longway.markdown.tasks")
local comments_sync = require("longway.sync.comments")
local comments_md = require("longway.markdown.comments")
local confirm = require("longway.ui.confirm")
local hash = require("longway.util.hash")
local frontmatter = require("longway.markdown.frontmatter")
local diff = require("longway.sync.diff")
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
local function update_buffer_comments(bufnr, comments)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local cfg = config.get()
  local start_marker = string.gsub(cfg.sync_start_marker, "{section}", "comments")
  local end_marker = string.gsub(cfg.sync_end_marker, "{section}", "comments")
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
    local new_comment_content = comments_md["render-comments"](comments)
    local new_section_lines = {start_marker}
    local comment_lines = vim.split(new_comment_content, "\n", {plain = true})
    for _, line in ipairs(comment_lines) do
      table.insert(new_section_lines, line)
    end
    table.insert(new_section_lines, end_marker)
    return vim.api.nvim_buf_set_lines(bufnr, (start_line - 1), end_line, false, new_section_lines)
  else
    return nil
  end
end
local function push_story_comments(story_id, local_comments, opts)
  local cfg = config.get()
  local comments_api = require("longway.api.comments")
  local remote_result = comments_api.list(story_id)
  if not remote_result.ok then
    return {error = remote_result.error, ok = false}
  else
    local remote_comments = comments_md["format-api-comments"]((remote_result.data or {}))
    local diff0 = comments_sync.diff(local_comments, remote_comments)
    local has_changes = comments_sync["has-changes?"]
    if (not has_changes(diff0) and (#diff0.edited == 0)) then
      return {ok = true, comments = local_comments}
    else
      if ((#diff0.deleted > 0) and cfg.comments.confirm_delete and not opts.skip_confirm) then
        local delete_count = #diff0.deleted
        local msg
        local function _7_()
          if (delete_count == 1) then
            return ""
          else
            return "s"
          end
        end
        msg = string.format("Push will delete %d comment%s from Shortcut. Continue?", delete_count, _7_())
        local confirmed = confirm["confirm-sync"](msg)
        if confirmed then
          return comments_sync.push(story_id, local_comments, remote_comments, {skip_delete = false})
        else
          notify.info("Skipping comment deletions")
          return comments_sync.push(story_id, local_comments, remote_comments, {skip_delete = true})
        end
      else
        return comments_sync.push(story_id, local_comments, remote_comments, {skip_delete = (opts.skip_delete or false)})
      end
    end
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
    local diff0 = tasks_sync.diff(local_tasks, remote_tasks)
    local has_changes = tasks_sync["has-changes?"]
    if not has_changes(diff0) then
      return {ok = true, tasks = local_tasks}
    else
      if ((#diff0.deleted > 0) and cfg.tasks.confirm_delete and not opts.skip_confirm) then
        local delete_count = #diff0.deleted
        local msg
        local function _13_()
          if (delete_count == 1) then
            return ""
          else
            return "s"
          end
        end
        msg = string.format("Push will delete %d task%s from Shortcut. Continue?", delete_count, _13_())
        local confirmed = confirm["confirm-sync"](msg)
        if confirmed then
          return tasks_sync.push(story_id, local_tasks, remote_tasks, {skip_delete = false})
        else
          notify.info("Skipping task deletions")
          return tasks_sync.push(story_id, local_tasks, remote_tasks, {skip_delete = true})
        end
      else
        return tasks_sync.push(story_id, local_tasks, remote_tasks, {skip_delete = (opts.skip_delete or false)})
      end
    end
  end
end
local function check_remote_before_push(story_id, parsed)
  local first_sync_3f = diff["first-sync?"]
  if first_sync_3f(parsed.frontmatter) then
    return {ok = true, conflict = false}
  else
    local remote_result = stories_api.get(story_id)
    if not remote_result.ok then
      return {error = remote_result.error, ok = false}
    else
      local classification = diff.classify(parsed, remote_result.data.updated_at)
      return {ok = true, conflict = (classification.status == "conflict"), classification = classification, ["remote-story"] = remote_result.data}
    end
  end
end
M["push-story"] = function(story_id, parsed, opts)
  local opts0 = (opts or {})
  local cfg = config.get()
  local bufnr = (opts0.bufnr or vim.api.nvim_get_current_buf())
  local and_20_ = not opts0.force
  if and_20_ then
    local _21_
    do
      local first_sync_3f = diff["first-sync?"]
      _21_ = first_sync_3f(parsed.frontmatter)
    end
    and_20_ = not _21_
  end
  if and_20_ then
    local check_result = check_remote_before_push(story_id, parsed)
    if not check_result.ok then
      return {error = check_result.error, ok = false}
    else
      if check_result.conflict then
        local classification = check_result.classification
        local changed_sections = {}
        if classification.local_changes.description then
          table.insert(changed_sections, "description")
        else
        end
        if classification.local_changes.tasks then
          table.insert(changed_sections, "tasks")
        else
        end
        if classification.local_changes.comments then
          table.insert(changed_sections, "comments")
        else
        end
        update_buffer_frontmatter(bufnr, {conflict_sections = changed_sections})
        notify["conflict-detected"](story_id)
        return {conflict = true, sections = changed_sections, ok = false}
      else
        return M["do-push"](story_id, parsed, opts0, bufnr)
      end
    end
  else
    return M["do-push"](story_id, parsed, opts0, bufnr)
  end
end
M["do-push"] = function(story_id, parsed, opts, bufnr)
  local cfg = config.get()
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
  if (cfg.sync_sections.tasks and (opts.sync_tasks or (opts.sync_tasks ~= false))) then
    local local_tasks = (parsed.tasks or {})
    local tasks_result = push_story_tasks(story_id, local_tasks, opts)
    results.tasks = tasks_result
    if tasks_result.ok then
      local result_tasks = (tasks_result.tasks or {})
      if (#result_tasks > 0) then
        update_buffer_tasks(bufnr, result_tasks)
      else
      end
      local new_hash = hash["tasks-hash"](result_tasks)
      update_buffer_frontmatter(bufnr, {tasks_hash = new_hash})
    else
      table.insert(errors, string.format("Tasks: %s", (tasks_result.error or table.concat((tasks_result.errors or {}), ", "))))
    end
  else
  end
  if (cfg.sync_sections.comments and (opts.sync_comments or (opts.sync_comments ~= false))) then
    local local_comments = (parsed.comments or {})
    local comments_result = push_story_comments(story_id, local_comments, opts)
    results.comments = comments_result
    if comments_result.ok then
      local result_comments = (comments_result.comments or {})
      if (#result_comments > 0) then
        update_buffer_comments(bufnr, result_comments)
      else
      end
      local new_hash = hash["comments-hash"](result_comments)
      update_buffer_frontmatter(bufnr, {comments_hash = new_hash})
    else
      table.insert(errors, string.format("Comments: %s", (comments_result.error or table.concat((comments_result.errors or {}), ", "))))
    end
  else
  end
  if (#errors == 0) then
    do
      local content_hash = hash["content-hash"]
      local fm_update = {sync_hash = content_hash((parsed.description or ""))}
      if (results.description and results.description.story) then
        fm_update["updated_at"] = results.description.story.updated_at
      else
      end
      fm_update["conflict_sections"] = nil
      update_buffer_frontmatter(bufnr, fm_update)
    end
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
