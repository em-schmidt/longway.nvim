local tasks_api = require("longway.api.tasks")
local tasks_md = require("longway.markdown.tasks")
local config = require("longway.config")
local notify = require("longway.ui.notify")
local M = {}
local function build_remote_task_map(remote_tasks)
  local task_map = {}
  for _, task in ipairs((remote_tasks or {})) do
    if task.id then
      task_map[task.id] = task
    else
    end
  end
  return task_map
end
M.diff = function(local_tasks, remote_tasks)
  local remote_map = build_remote_task_map(remote_tasks)
  local seen_ids = {}
  local created = {}
  local updated = {}
  local deleted = {}
  local unchanged = {}
  for _, local_task in ipairs((local_tasks or {})) do
    if local_task.is_new then
      table.insert(created, local_task)
    else
      if local_task.id then
        seen_ids[local_task.id] = true
        local remote_task = remote_map[local_task.id]
        if not remote_task then
          local_task.is_new = true
          local_task.id = nil
          table.insert(created, local_task)
        else
          if tasks_md["task-changed?"](local_task, remote_task) then
            table.insert(updated, local_task)
          else
            table.insert(unchanged, local_task)
          end
        end
      else
      end
    end
  end
  for _, remote_task in ipairs((remote_tasks or {})) do
    if (remote_task.id and not seen_ids[remote_task.id]) then
      table.insert(deleted, remote_task.id)
    else
    end
  end
  return {created = created, updated = updated, deleted = deleted, unchanged = unchanged}
end
M["has-changes?"] = function(diff)
  return ((#diff.created > 0) or (#diff.updated > 0) or (#diff.deleted > 0))
end
local function push_created_tasks(story_id, tasks)
  local result_tasks = {}
  local errors = {}
  for _, task in ipairs(tasks) do
    tasks_md["resolve-task-owners"](task)
    local task_data = {description = task.description, complete = task.complete}
    if (task.owner_ids and (#task.owner_ids > 0)) then
      task_data.owner_ids = task.owner_ids
    else
    end
    local result = tasks_api.create(story_id, task_data)
    if result.ok then
      task.id = result.data.id
      task.is_new = false
      table.insert(result_tasks, task)
    else
      table.insert(errors, string.format("Create '%s': %s", task.description, (result.error or "unknown error")))
    end
  end
  return {ok = (#errors == 0), tasks = result_tasks, errors = errors}
end
local function push_updated_tasks(story_id, tasks)
  local result_tasks = {}
  local errors = {}
  for _, task in ipairs(tasks) do
    local task_data = {description = task.description, complete = task.complete}
    local result = tasks_api.update(story_id, task.id, task_data)
    if result.ok then
      table.insert(result_tasks, task)
    else
      table.insert(errors, string.format("Update task %s: %s", tostring(task.id), (result.error or "unknown error")))
    end
  end
  return {ok = (#errors == 0), tasks = result_tasks, errors = errors}
end
local function push_deleted_tasks(story_id, task_ids)
  local deleted = {}
  local errors = {}
  for _, task_id in ipairs(task_ids) do
    local result = tasks_api.delete(story_id, task_id)
    if result.ok then
      table.insert(deleted, task_id)
    else
      table.insert(errors, string.format("Delete task %s: %s", tostring(task_id), (result.error or "unknown error")))
    end
  end
  return {ok = (#errors == 0), deleted = deleted, errors = errors}
end
M.push = function(story_id, local_tasks, remote_tasks, opts)
  local opts0 = (opts or {})
  local diff = M.diff(local_tasks, remote_tasks)
  local all_errors = {}
  local result_tasks = {}
  if not M["has-changes?"](diff) then
    return {ok = true, created = 0, updated = 0, deleted = 0, errors = {}, tasks = local_tasks}
  else
  end
  if (#diff.created > 0) then
    notify.info(string.format("Creating %d new task(s)...", #diff.created))
    local create_result = push_created_tasks(story_id, diff.created)
    for _, task in ipairs(create_result.tasks) do
      table.insert(result_tasks, task)
    end
    for _, err in ipairs(create_result.errors) do
      table.insert(all_errors, err)
    end
  else
  end
  if (#diff.updated > 0) then
    notify.info(string.format("Updating %d task(s)...", #diff.updated))
    local update_result = push_updated_tasks(story_id, diff.updated)
    for _, task in ipairs(update_result.tasks) do
      table.insert(result_tasks, task)
    end
    for _, err in ipairs(update_result.errors) do
      table.insert(all_errors, err)
    end
  else
  end
  for _, task in ipairs(diff.unchanged) do
    table.insert(result_tasks, task)
  end
  local deleted_count = 0
  if ((#diff.deleted > 0) and not opts0.skip_delete) then
    notify.info(string.format("Deleting %d task(s)...", #diff.deleted))
    local delete_result = push_deleted_tasks(story_id, diff.deleted)
    deleted_count = #delete_result.deleted
    for _, err in ipairs(delete_result.errors) do
      table.insert(all_errors, err)
    end
  else
  end
  local created_count = #diff.created
  local updated_count = #diff.updated
  if (#all_errors == 0) then
    notify.info(string.format("Tasks synced: %d created, %d updated, %d deleted", created_count, updated_count, deleted_count))
  else
    notify.warn(string.format("Task sync completed with %d error(s)", #all_errors))
  end
  return {ok = (#all_errors == 0), created = created_count, updated = updated_count, deleted = deleted_count, errors = all_errors, tasks = result_tasks}
end
M.pull = function(story)
  local raw_tasks = (story.tasks or {})
  local formatted = {}
  for i, task in ipairs(raw_tasks) do
    local owner_mention
    if (task.owner_ids and (#task.owner_ids > 0)) then
      local owner_name = tasks_md["resolve-owner-id"](task.owner_ids[1])
      if owner_name then
        owner_mention = string.gsub(owner_name, " ", "_")
      else
        owner_mention = nil
      end
    else
      owner_mention = nil
    end
    table.insert(formatted, {id = task.id, description = task.description, complete = task.complete, owner_ids = (task.owner_ids or {}), owner_mention = owner_mention, position = (task.position or i), is_new = false})
  end
  return {ok = true, tasks = formatted}
end
M.merge = function(local_tasks, remote_tasks, previous_tasks)
  local prev_map = build_remote_task_map(previous_tasks)
  local remote_map = build_remote_task_map(remote_tasks)
  local local_map = build_remote_task_map(local_tasks)
  local merged = {}
  local conflicts = {}
  local remote_added = {}
  local remote_deleted = {}
  for _, task in ipairs(local_tasks) do
    if task.is_new then
      table.insert(merged, task)
    else
      if task.id then
        local remote = remote_map[task.id]
        local prev = prev_map[task.id]
        if not remote then
          if prev then
            table.insert(remote_deleted, task.id)
          else
            table.insert(merged, task)
          end
        else
          local local_changed = (prev and tasks_md["task-changed?"](task, prev))
          local remote_changed = (prev and tasks_md["task-changed?"](remote, prev))
          if (local_changed and remote_changed) then
            table.insert(conflicts, task.id)
            table.insert(merged, task)
          else
            table.insert(merged, task)
          end
        end
      else
      end
    end
  end
  for _, remote_task in ipairs(remote_tasks) do
    if not local_map[remote_task.id] then
      if prev_map[remote_task.id] then
      else
        table.insert(remote_added, remote_task)
        table.insert(merged, {id = remote_task.id, description = remote_task.description, complete = remote_task.complete, owner_ids = (remote_task.owner_ids or {}), position = remote_task.position, is_new = false})
      end
    else
    end
  end
  return {tasks = merged, conflicts = conflicts, remote_added = remote_added, remote_deleted = remote_deleted}
end
return M
