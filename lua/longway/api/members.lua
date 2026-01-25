-- [nfnl] fnl/longway/api/members.fnl
local client = require("longway.api.client")
local cache = require("longway.cache.store")
local M = {}
M.list = function()
  return client.get("/members")
end
M["get-current"] = function()
  return client.get("/member")
end
M.get = function(member_id)
  return client.get(string.format("/members/%s", member_id))
end
M["list-cached"] = function()
  return cache["get-or-fetch"]("members", M.list)
end
M["refresh-cache"] = function()
  return cache.refresh("members", M.list)
end
M["find-by-name"] = function(name, members)
  local members0
  local or_1_ = members
  if not or_1_ then
    local result = M["list-cached"]()
    if result.ok then
      or_1_ = result.data
    else
      or_1_ = nil
    end
  end
  members0 = or_1_
  local lower_name = string.lower(name)
  if members0 then
    local found = nil
    for _, member in ipairs(members0) do
      if found then break end
      local profile = (member.profile or {})
      local display_name = (profile.name or profile.mention_name or member.id or "")
      local lower_display = string.lower(display_name)
      if string.find(lower_display, lower_name, 1, true) then
        found = member
      else
      end
    end
    return found
  else
    return nil
  end
end
M["find-by-id"] = function(id, members)
  local members0
  local or_6_ = members
  if not or_6_ then
    local result = M["list-cached"]()
    if result.ok then
      or_6_ = result.data
    else
      or_6_ = nil
    end
  end
  members0 = or_6_
  if members0 then
    local found = nil
    for _, member in ipairs(members0) do
      if found then break end
      if (member.id == id) then
        found = member
      else
      end
    end
    return found
  else
    return nil
  end
end
M["get-display-name"] = function(member)
  local profile = (member.profile or {})
  return (profile.name or profile.mention_name or member.id or "Unknown")
end
M["resolve-name"] = function(member_id)
  local member = M["find-by-id"](member_id)
  if member then
    return M["get-display-name"](member)
  else
    return member_id
  end
end
return M
