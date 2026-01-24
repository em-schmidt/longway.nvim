-- [nfnl] fnl/longway/api/workflows.fnl
local client = require("longway.api.client")
local cache = require("longway.cache.store")
local M = {}
M.list = function()
  return client.get("/workflows")
end
M["list-cached"] = function()
  return cache["get-or-fetch"]("workflows", M.list)
end
M["refresh-cache"] = function()
  return cache.refresh("workflows", M.list)
end
M["get-states"] = function(workflow)
  return (workflow.states or {})
end
M["get-all-states"] = function()
  local result = M["list-cached"]()
  if not result.ok then
    return result
  else
    local all_states = {}
    for _, workflow in ipairs(result.data) do
      for _0, state in ipairs(M["get-states"](workflow)) do
        table.insert(all_states, state)
      end
    end
    return {ok = true, data = all_states}
  end
end
M["find-state-by-name"] = function(name, workflows)
  local workflows0
  local or_2_ = workflows
  if not or_2_ then
    local result = M["list-cached"]()
    if result.ok then
      or_2_ = result.data
    else
      or_2_ = nil
    end
  end
  workflows0 = or_2_
  local lower_name = string.lower(name)
  if workflows0 then
    local found = nil
    for _, workflow in ipairs(workflows0) do
      if found then break end
      for _0, state in ipairs(M["get-states"](workflow)) do
        if found then break end
        local lower_state = string.lower((state.name or ""))
        if string.find(lower_state, lower_name, 1, true) then
          found = state
        else
        end
      end
    end
    return found
  else
    return nil
  end
end
M["find-state-by-id"] = function(id, workflows)
  local workflows0
  local or_7_ = workflows
  if not or_7_ then
    local result = M["list-cached"]()
    if result.ok then
      or_7_ = result.data
    else
      or_7_ = nil
    end
  end
  workflows0 = or_7_
  if workflows0 then
    local found = nil
    for _, workflow in ipairs(workflows0) do
      if found then break end
      for _0, state in ipairs(M["get-states"](workflow)) do
        if found then break end
        if (state.id == id) then
          found = state
        else
        end
      end
    end
    return found
  else
    return nil
  end
end
M["get-state-type"] = function(state)
  return (state.type or "unstarted")
end
M["is-done-state"] = function(state)
  return (M["get-state-type"](state) == "done")
end
M["is-started-state"] = function(state)
  return (M["get-state-type"](state) == "started")
end
M["resolve-state-name"] = function(state_id)
  local state = M["find-state-by-id"](state_id)
  if state then
    return state.name
  else
    return state_id
  end
end
return M
