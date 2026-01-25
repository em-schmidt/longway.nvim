-- [nfnl] fnl/longway/api/iterations.fnl
local client = require("longway.api.client")
local cache = require("longway.cache.store")
local M = {}
M.list = function()
  return client.get("/iterations")
end
M.get = function(iteration_id)
  return client.get(string.format("/iterations/%s", iteration_id))
end
M["list-cached"] = function()
  return cache["get-or-fetch"]("iterations", M.list)
end
M["refresh-cache"] = function()
  return cache.refresh("iterations", M.list)
end
M["find-by-name"] = function(name, iterations)
  local iterations0
  local or_1_ = iterations
  if not or_1_ then
    local result = M["list-cached"]()
    if result.ok then
      or_1_ = result.data
    else
      or_1_ = nil
    end
  end
  iterations0 = or_1_
  local lower_name = string.lower(name)
  if iterations0 then
    local found = nil
    for _, iteration in ipairs(iterations0) do
      if found then break end
      local lower_iter_name = string.lower((iteration.name or ""))
      if string.find(lower_iter_name, lower_name, 1, true) then
        found = iteration
      else
      end
    end
    return found
  else
    return nil
  end
end
M["find-by-id"] = function(id, iterations)
  local iterations0
  local or_6_ = iterations
  if not or_6_ then
    local result = M["list-cached"]()
    if result.ok then
      or_6_ = result.data
    else
      or_6_ = nil
    end
  end
  iterations0 = or_6_
  if iterations0 then
    local found = nil
    for _, iteration in ipairs(iterations0) do
      if found then break end
      if (iteration.id == id) then
        found = iteration
      else
      end
    end
    return found
  else
    return nil
  end
end
M["get-current"] = function()
  local result = M["list-cached"]()
  local now = os.time()
  if result.ok then
    local current = nil
    for _, iteration in ipairs(result.data) do
      if current then break end
      local start_date = iteration.start_date
      local end_date = iteration.end_date
      if (start_date and end_date and iteration.status and (iteration.status == "started")) then
        current = iteration
      else
      end
    end
    return current
  else
    return nil
  end
end
M["get-upcoming"] = function()
  local result = M["list-cached"]()
  local upcoming = {}
  if result.ok then
    for _, iteration in ipairs(result.data) do
      if (iteration.status == "unstarted") then
        table.insert(upcoming, iteration)
      else
      end
    end
  else
  end
  return upcoming
end
M["resolve-name"] = function(iteration_id)
  local iteration = M["find-by-id"](iteration_id)
  if iteration then
    return iteration.name
  else
    return tostring(iteration_id)
  end
end
return M
