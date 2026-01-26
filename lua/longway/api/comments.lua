-- [nfnl] fnl/longway/api/comments.fnl
local client = require("longway.api.client")
local M = {}
M.list = function(story_id)
  return client.get(string.format("/stories/%s/comments", tostring(story_id)))
end
M.get = function(story_id, comment_id)
  return client.get(string.format("/stories/%s/comments/%s", tostring(story_id), tostring(comment_id)))
end
M.create = function(story_id, data)
  return client.post(string.format("/stories/%s/comments", tostring(story_id)), {body = data})
end
M.delete = function(story_id, comment_id)
  return client.delete(string.format("/stories/%s/comments/%s", tostring(story_id), tostring(comment_id)))
end
M["batch-create"] = function(story_id, comments)
  local created = {}
  local errors = {}
  for i, cmt in ipairs(comments) do
    local result = M.create(story_id, cmt)
    if result.ok then
      table.insert(created, result.data)
    else
      table.insert(errors, string.format("Comment %d: %s", i, (result.error or "unknown error")))
    end
  end
  return {ok = (#errors == 0), created = created, errors = errors}
end
M["batch-delete"] = function(story_id, comment_ids)
  local deleted = {}
  local errors = {}
  for _, comment_id in ipairs(comment_ids) do
    local result = M.delete(story_id, comment_id)
    if result.ok then
      table.insert(deleted, comment_id)
    else
      table.insert(errors, string.format("Comment %s: %s", tostring(comment_id), (result.error or "unknown error")))
    end
  end
  return {ok = (#errors == 0), deleted = deleted, errors = errors}
end
return M
