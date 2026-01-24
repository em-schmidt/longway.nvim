-- [nfnl] fnl/longway-spec/mocks/api.fnl
local M = {}
local stories = {}
local epics = {}
local call_log = {}
M.reset = function()
  stories = {}
  epics = {}
  call_log = {}
  return nil
end
M["setup-story"] = function(story)
  stories[story.id] = story
  return nil
end
M["setup-epic"] = function(epic)
  epics[epic.id] = epic
  return nil
end
M["get-story"] = function(id)
  table.insert(call_log, {method = "get-story", id = id})
  return stories[id]
end
M["get-epic"] = function(id)
  table.insert(call_log, {method = "get-epic", id = id})
  return epics[id]
end
M["search-stories"] = function(query)
  table.insert(call_log, {method = "search-stories", query = query})
  local results = {}
  for _, story in pairs(stories) do
    table.insert(results, story)
  end
  return results
end
M["list-stories"] = function()
  table.insert(call_log, {method = "list-stories"})
  local results = {}
  for _, story in pairs(stories) do
    table.insert(results, story)
  end
  return results
end
M["last-call"] = function()
  return call_log[#call_log]
end
M["call-count"] = function()
  return #call_log
end
M["get-calls"] = function()
  return call_log
end
M["make-story-response"] = function(id, name)
  return {id = id, name = name, description = "", story_type = "feature", workflow_state_id = 500000001, workflow_state_name = "Unstarted", app_url = ("https://app.shortcut.com/test/story/" .. id), created_at = "2026-01-01T00:00:00Z", updated_at = "2026-01-15T12:00:00Z", tasks = {}, comments = {}, owners = {}, labels = {}, epic_id = nil, iteration_id = nil, group_id = nil, estimate = nil}
end
M["make-epic-response"] = function(id, name)
  return {id = id, name = name, description = "", state = "to do", app_url = ("https://app.shortcut.com/test/epic/" .. id), created_at = "2026-01-01T00:00:00Z", updated_at = "2026-01-15T12:00:00Z", planned_start_date = nil, deadline = nil, stats = {num_stories_total = 0, num_stories_done = 0}}
end
return M
