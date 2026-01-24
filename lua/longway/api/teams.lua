-- [nfnl] fnl/longway/api/teams.fnl
local client = require("longway.api.client")
local cache = require("longway.cache.store")
local M = {}
M.list = function()
  return client.get("/groups")
end
M.get = function(team_id)
  return client.get(string.format("/groups/%s", team_id))
end
M["list-cached"] = function()
  return cache["get-or-fetch"]("teams", M.list)
end
M["refresh-cache"] = function()
  return cache.refresh("teams", M.list)
end
M["find-by-name"] = function(name, teams)
  local teams0
  local or_1_ = teams
  if not or_1_ then
    local result = M["list-cached"]()
    if result.ok then
      or_1_ = result.data
    else
      or_1_ = nil
    end
  end
  teams0 = or_1_
  local lower_name = string.lower(name)
  if teams0 then
    local found = nil
    for _, team in ipairs(teams0) do
      if found then break end
      local lower_team_name = string.lower((team.name or ""))
      if string.find(lower_team_name, lower_name, 1, true) then
        found = team
      else
      end
    end
    return found
  else
    return nil
  end
end
M["find-by-id"] = function(id, teams)
  local teams0
  local or_6_ = teams
  if not or_6_ then
    local result = M["list-cached"]()
    if result.ok then
      or_6_ = result.data
    else
      or_6_ = nil
    end
  end
  teams0 = or_6_
  if teams0 then
    local found = nil
    for _, team in ipairs(teams0) do
      if found then break end
      if (team.id == id) then
        found = team
      else
      end
    end
    return found
  else
    return nil
  end
end
M["get-members"] = function(team)
  return (team.member_ids or {})
end
M["resolve-name"] = function(team_id)
  local team = M["find-by-id"](team_id)
  if team then
    return team.name
  else
    return tostring(team_id)
  end
end
return M
