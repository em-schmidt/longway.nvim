-- Teams API module for longway.nvim
-- Compiled from fnl/longway/api/teams.fnl

local client = require("longway.api.client")
local cache = require("longway.cache.store")

local M = {}

function M.list()
  return client.get("/groups")
end

function M.get(team_id)
  return client.get(string.format("/groups/%s", team_id))
end

function M.list_cached()
  return cache.get_or_fetch("teams", M.list)
end

function M.refresh_cache()
  return cache.refresh("teams", M.list)
end

function M.find_by_name(name, teams)
  if not teams then
    local result = M.list_cached()
    if result.ok then
      teams = result.data
    end
  end
  if not teams then
    return nil
  end
  local lower_name = string.lower(name)
  for _, team in ipairs(teams) do
    local lower_team_name = string.lower(team.name or "")
    if string.find(lower_team_name, lower_name, 1, true) then
      return team
    end
  end
  return nil
end

function M.find_by_id(id, teams)
  if not teams then
    local result = M.list_cached()
    if result.ok then
      teams = result.data
    end
  end
  if not teams then
    return nil
  end
  for _, team in ipairs(teams) do
    if team.id == id then
      return team
    end
  end
  return nil
end

function M.get_members(team)
  return team.member_ids or {}
end

function M.resolve_name(team_id)
  local team = M.find_by_id(team_id)
  if team then
    return team.name
  end
  return tostring(team_id)
end

return M
