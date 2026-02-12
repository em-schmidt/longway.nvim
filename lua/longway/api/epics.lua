-- [nfnl] fnl/longway/api/epics.fnl
local client = require("longway.api.client")
local M = {}
M.get = function(epic_id)
  return client.get(string.format("/epics/%s", tostring(epic_id)))
end
M.list = function()
  return client.get("/epics")
end
M.update = function(epic_id, data)
  return client.put(string.format("/epics/%s", tostring(epic_id)), {body = data})
end
M.create = function(data)
  return client.post("/epics", {body = data})
end
M.delete = function(epic_id)
  return client.delete(string.format("/epics/%s", tostring(epic_id)))
end
M["list-stories"] = function(epic_id, opts)
  local query_params
  if (opts and opts.includes_description) then
    query_params = {includes_description = "true"}
  else
    query_params = nil
  end
  local function _2_()
    if query_params then
      return {query = query_params}
    else
      return nil
    end
  end
  return client.get(string.format("/epics/%s/stories", tostring(epic_id)), _2_())
end
M["get-with-stories"] = function(epic_id)
  local epic_result = M.get(epic_id)
  if not epic_result.ok then
    return epic_result
  else
    local stories_result = M["list-stories"](epic_id)
    if not stories_result.ok then
      return {ok = true, data = {epic = epic_result.data, stories = {}}}
    else
      return {ok = true, data = {epic = epic_result.data, stories = stories_result.data}}
    end
  end
end
M["get-stats"] = function(epic)
  local stats = (epic.stats or {})
  return {total = (stats.num_stories_total or 0), started = (stats.num_stories_started or 0), done = (stats.num_stories_done or 0), unstarted = (stats.num_stories_unstarted or 0), points_total = (stats.num_points or 0), points_done = (stats.num_points_done or 0)}
end
M["get-progress"] = function(epic)
  local stats = M["get-stats"](epic)
  local total = stats.total
  if (total > 0) then
    return math.floor(((stats.done / total) * 100))
  else
    return 0
  end
end
return M
