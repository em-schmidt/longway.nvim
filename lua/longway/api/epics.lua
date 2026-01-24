-- Epics API module for longway.nvim
-- Compiled from fnl/longway/api/epics.fnl

local client = require("longway.api.client")

local M = {}

function M.get(epic_id)
  return client.get(string.format("/epics/%s", tostring(epic_id)))
end

function M.list()
  return client.get("/epics")
end

function M.update(epic_id, data)
  return client.put(string.format("/epics/%s", tostring(epic_id)), { body = data })
end

function M.create(data)
  return client.post("/epics", { body = data })
end

function M.delete(epic_id)
  return client.delete(string.format("/epics/%s", tostring(epic_id)))
end

function M.list_stories(epic_id, opts)
  local query_params = nil
  if opts and opts.includes_description then
    query_params = { includes_description = "true" }
  end
  local endpoint = string.format("/epics/%s/stories", tostring(epic_id))
  if query_params then
    return client.get(endpoint, { query = query_params })
  end
  return client.get(endpoint)
end

function M.get_with_stories(epic_id)
  local epic_result = M.get(epic_id)
  if not epic_result.ok then
    return epic_result
  end
  local stories_result = M.list_stories(epic_id)
  if not stories_result.ok then
    return { ok = true, data = { epic = epic_result.data, stories = {} } }
  end
  return { ok = true, data = { epic = epic_result.data, stories = stories_result.data } }
end

function M.get_stats(epic)
  local stats = epic.stats or {}
  return {
    total = stats.num_stories or 0,
    started = stats.num_stories_started or 0,
    done = stats.num_stories_done or 0,
    unstarted = stats.num_stories_unstarted or 0,
    points_total = stats.num_points or 0,
    points_done = stats.num_points_done or 0
  }
end

function M.get_progress(epic)
  local stats = M.get_stats(epic)
  local total = stats.total
  if total > 0 then
    return math.floor((stats.done / total) * 100)
  end
  return 0
end

return M
