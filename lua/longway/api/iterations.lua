-- Iterations API module for longway.nvim
-- Compiled from fnl/longway/api/iterations.fnl

local client = require("longway.api.client")
local cache = require("longway.cache.store")

local M = {}

function M.list()
  return client.get("/iterations")
end

function M.get(iteration_id)
  return client.get(string.format("/iterations/%s", iteration_id))
end

function M.list_cached()
  return cache.get_or_fetch("iterations", M.list)
end

function M.refresh_cache()
  return cache.refresh("iterations", M.list)
end

function M.find_by_name(name, iterations)
  if not iterations then
    local result = M.list_cached()
    if result.ok then
      iterations = result.data
    end
  end
  if not iterations then
    return nil
  end
  local lower_name = string.lower(name)
  for _, iteration in ipairs(iterations) do
    local lower_iter_name = string.lower(iteration.name or "")
    if string.find(lower_iter_name, lower_name, 1, true) then
      return iteration
    end
  end
  return nil
end

function M.find_by_id(id, iterations)
  if not iterations then
    local result = M.list_cached()
    if result.ok then
      iterations = result.data
    end
  end
  if not iterations then
    return nil
  end
  for _, iteration in ipairs(iterations) do
    if iteration.id == id then
      return iteration
    end
  end
  return nil
end

function M.get_current()
  local result = M.list_cached()
  if not result.ok then
    return nil
  end
  for _, iteration in ipairs(result.data) do
    if iteration.status and iteration.status == "started" then
      return iteration
    end
  end
  return nil
end

function M.get_upcoming()
  local result = M.list_cached()
  local upcoming = {}
  if result.ok then
    for _, iteration in ipairs(result.data) do
      if iteration.status == "unstarted" then
        table.insert(upcoming, iteration)
      end
    end
  end
  return upcoming
end

function M.resolve_name(iteration_id)
  local iteration = M.find_by_id(iteration_id)
  if iteration then
    return iteration.name
  end
  return tostring(iteration_id)
end

return M
