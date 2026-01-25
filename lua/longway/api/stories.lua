-- [nfnl] fnl/longway/api/stories.fnl
local client = require("longway.api.client")
local M = {}
M.get = function(story_id)
  return client.get(string.format("/stories/%s", tostring(story_id)))
end
M.update = function(story_id, data)
  return client.put(string.format("/stories/%s", tostring(story_id)), {body = data})
end
M.search = function(query, opts)
  local params = {query = query}
  if opts then
    if opts.page_size then
      params.page_size = opts.page_size
    else
    end
    if opts.next then
      params.next = opts.next
    else
    end
  else
  end
  return client.get("/search/stories", {query = params})
end
M["list-for-epic"] = function(epic_id)
  return client.get(string.format("/epics/%s/stories", tostring(epic_id)))
end
M["create-task"] = function(story_id, task_data)
  return client.post(string.format("/stories/%s/tasks", tostring(story_id)), {body = task_data})
end
M["update-task"] = function(story_id, task_id, task_data)
  return client.put(string.format("/stories/%s/tasks/%s", tostring(story_id), tostring(task_id)), {body = task_data})
end
M["delete-task"] = function(story_id, task_id)
  return client.delete(string.format("/stories/%s/tasks/%s", tostring(story_id), tostring(task_id)))
end
M["list-comments"] = function(story_id)
  return client.get(string.format("/stories/%s/comments", tostring(story_id)))
end
M["create-comment"] = function(story_id, text)
  return client.post(string.format("/stories/%s/comments", tostring(story_id)), {body = {text = text}})
end
M["delete-comment"] = function(story_id, comment_id)
  return client.delete(string.format("/stories/%s/comments/%s", tostring(story_id), tostring(comment_id)))
end
return M
