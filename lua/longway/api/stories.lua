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
M.query = function(params)
  return client.post("/stories/search", {body = (params or {})})
end
M["list-for-epic"] = function(epic_id)
  return client.get(string.format("/epics/%s/stories", tostring(epic_id)))
end
local comments_api = require("longway.api.comments")
M["list-comments"] = function(story_id)
  return comments_api.list(story_id)
end
M["create-comment"] = function(story_id, text)
  return comments_api.create(story_id, {text = text})
end
M["delete-comment"] = function(story_id, comment_id)
  return comments_api.delete(story_id, comment_id)
end
return M
