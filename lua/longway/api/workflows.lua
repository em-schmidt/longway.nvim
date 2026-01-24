-- Workflows API module for longway.nvim
-- Compiled from fnl/longway/api/workflows.fnl

local client = require("longway.api.client")
local cache = require("longway.cache.store")

local M = {}

function M.list()
  return client.get("/workflows")
end

function M.list_cached()
  return cache.get_or_fetch("workflows", M.list)
end

function M.refresh_cache()
  return cache.refresh("workflows", M.list)
end

function M.get_states(workflow)
  return workflow.states or {}
end

function M.get_all_states()
  local result = M.list_cached()
  if not result.ok then
    return result
  end
  local all_states = {}
  for _, workflow in ipairs(result.data) do
    for _, state in ipairs(M.get_states(workflow)) do
      table.insert(all_states, state)
    end
  end
  return { ok = true, data = all_states }
end

function M.find_state_by_name(name, workflows)
  if not workflows then
    local result = M.list_cached()
    if result.ok then
      workflows = result.data
    end
  end
  if not workflows then
    return nil
  end
  local lower_name = string.lower(name)
  for _, workflow in ipairs(workflows) do
    for _, state in ipairs(M.get_states(workflow)) do
      local lower_state = string.lower(state.name or "")
      if string.find(lower_state, lower_name, 1, true) then
        return state
      end
    end
  end
  return nil
end

function M.find_state_by_id(id, workflows)
  if not workflows then
    local result = M.list_cached()
    if result.ok then
      workflows = result.data
    end
  end
  if not workflows then
    return nil
  end
  for _, workflow in ipairs(workflows) do
    for _, state in ipairs(M.get_states(workflow)) do
      if state.id == id then
        return state
      end
    end
  end
  return nil
end

function M.get_state_type(state)
  return state.type or "unstarted"
end

function M.is_done_state(state)
  return M.get_state_type(state) == "done"
end

function M.is_started_state(state)
  return M.get_state_type(state) == "started"
end

function M.resolve_state_name(state_id)
  local state = M.find_state_by_id(state_id)
  if state then
    return state.name
  end
  return state_id
end

return M
