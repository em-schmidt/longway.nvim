-- [nfnl] fnl/longway/api/tasks.fnl
local client = require("longway.api.client")
local M = {}
M.create = function(story_id, task_data)
  return client.post(string.format("/stories/%s/tasks", tostring(story_id)), {body = task_data})
end
M.update = function(story_id, task_id, data)
  return client.put(string.format("/stories/%s/tasks/%s", tostring(story_id), tostring(task_id)), {body = data})
end
M.delete = function(story_id, task_id)
  return client.delete(string.format("/stories/%s/tasks/%s", tostring(story_id), tostring(task_id)))
end
M.get = function(story_id, task_id)
  return client.get(string.format("/stories/%s/tasks/%s", tostring(story_id), tostring(task_id)))
end
M["batch-create"] = function(story_id, tasks)
  local created = {}
  local errors = {}
  for i, task in ipairs(tasks) do
    local result = M.create(story_id, task)
    if result.ok then
      table.insert(created, result.data)
    else
      table.insert(errors, string.format("Task %d: %s", i, (result.error or "unknown error")))
    end
  end
  return {ok = (#errors == 0), created = created, errors = errors}
end
M["batch-update"] = function(story_id, updates)
  local updated = {}
  local errors = {}
  for _, update in ipairs(updates) do
    local result = M.update(story_id, update.id, update.data)
    if result.ok then
      table.insert(updated, result.data)
    else
      table.insert(errors, string.format("Task %s: %s", tostring(update.id), (result.error or "unknown error")))
    end
  end
  return {ok = (#errors == 0), updated = updated, errors = errors}
end
M["batch-delete"] = function(story_id, task_ids)
  local deleted = {}
  local errors = {}
  for _, task_id in ipairs(task_ids) do
    local result = M.delete(story_id, task_id)
    if result.ok then
      table.insert(deleted, task_id)
    else
      table.insert(errors, string.format("Task %s: %s", tostring(task_id), (result.error or "unknown error")))
    end
  end
  return {ok = (#errors == 0), deleted = deleted, errors = errors}
end
return M
