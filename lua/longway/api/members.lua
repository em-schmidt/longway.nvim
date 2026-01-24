-- Members API module for longway.nvim
-- Compiled from fnl/longway/api/members.fnl

local client = require("longway.api.client")
local cache = require("longway.cache.store")

local M = {}

function M.list()
  return client.get("/members")
end

function M.get_current()
  return client.get("/member")
end

function M.get(member_id)
  return client.get(string.format("/members/%s", member_id))
end

function M.list_cached()
  return cache.get_or_fetch("members", M.list)
end

function M.refresh_cache()
  return cache.refresh("members", M.list)
end

function M.find_by_name(name, members)
  if not members then
    local result = M.list_cached()
    if result.ok then
      members = result.data
    end
  end
  if not members then
    return nil
  end
  local lower_name = string.lower(name)
  for _, member in ipairs(members) do
    local profile = member.profile or {}
    local display_name = profile.name or profile.mention_name or member.id or ""
    local lower_display = string.lower(display_name)
    if string.find(lower_display, lower_name, 1, true) then
      return member
    end
  end
  return nil
end

function M.find_by_id(id, members)
  if not members then
    local result = M.list_cached()
    if result.ok then
      members = result.data
    end
  end
  if not members then
    return nil
  end
  for _, member in ipairs(members) do
    if member.id == id then
      return member
    end
  end
  return nil
end

function M.get_display_name(member)
  local profile = member.profile or {}
  return profile.name or profile.mention_name or member.id or "Unknown"
end

function M.resolve_name(member_id)
  local member = M.find_by_id(member_id)
  if member then
    return M.get_display_name(member)
  end
  return member_id
end

return M
