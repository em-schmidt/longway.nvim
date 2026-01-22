-- Stories API module for longway.nvim
-- Compiled from fnl/longway/api/stories.fnl

local client = require("longway.api.client")

local M = {}

function M.get(story_id)
  return client.get(string.format("/stories/%s", tostring(story_id)))
end

function M.update(story_id, data)
  return client.put(string.format("/stories/%s", tostring(story_id)), { body = data })
end

function M.search(query, opts)
  local params = { query = query }
  if opts then
    if opts.page_size then
      params.page_size = opts.page_size
    end
    if opts.next then
      params.next = opts.next
    end
  end
  return client.get("/search/stories", { query = params })
end

function M.list_for_epic(epic_id)
  return client.get(string.format("/epics/%s/stories", tostring(epic_id)))
end

-- Task-related functions

function M.create_task(story_id, task_data)
  return client.post(string.format("/stories/%s/tasks", tostring(story_id)), { body = task_data })
end

function M.update_task(story_id, task_id, task_data)
  return client.put(string.format("/stories/%s/tasks/%s", tostring(story_id), tostring(task_id)), { body = task_data })
end

function M.delete_task(story_id, task_id)
  return client.delete(string.format("/stories/%s/tasks/%s", tostring(story_id), tostring(task_id)))
end

-- Comment-related functions

function M.list_comments(story_id)
  return client.get(string.format("/stories/%s/comments", tostring(story_id)))
end

function M.create_comment(story_id, text)
  return client.post(string.format("/stories/%s/comments", tostring(story_id)), { body = { text = text } })
end

function M.delete_comment(story_id, comment_id)
  return client.delete(string.format("/stories/%s/comments/%s", tostring(story_id), tostring(comment_id)))
end

return M
