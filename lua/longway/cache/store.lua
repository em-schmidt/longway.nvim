-- [nfnl] fnl/longway/cache/store.fnl
local config = require("longway.config")
local notify = require("longway.ui.notify")
local M = {}
local DEFAULT_TTL = 3600
local CACHE_TYPES = {members = 3600, workflows = 86400, iterations = 3600, teams = 3600, labels = 3600, projects = 3600}
local function get_cache_dir()
  return (config["get-workspace-dir"]() .. "/.longway/cache")
end
local function get_cache_path(cache_type)
  return (get_cache_dir() .. "/" .. cache_type .. ".json")
end
local function ensure_cache_dir()
  local cache_dir = get_cache_dir()
  if (vim.fn.isdirectory(cache_dir) ~= 1) then
    return vim.fn.mkdir(cache_dir, "p")
  else
    return nil
  end
end
local function read_json_file(path)
  if (vim.fn.filereadable(path) == 1) then
    local content = vim.fn.readfile(path)
    local text = table.concat(content, "\n")
    if (#text > 0) then
      local ok, data = pcall(vim.json.decode, text)
      if ok then
        return data
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
local function write_json_file(path, data)
  ensure_cache_dir()
  local ok, json = pcall(vim.json.encode, data)
  if ok then
    vim.fn.writefile({json}, path)
    return true
  else
    return nil
  end
end
local function is_expired(cache_entry, ttl)
  if not cache_entry then
    return true
  elseif not cache_entry.timestamp then
    return true
  else
    local now = os.time()
    local age = (now - cache_entry.timestamp)
    local effective_ttl = (ttl or CACHE_TYPES[cache_entry.type] or DEFAULT_TTL)
    return (age > effective_ttl)
  end
end
M.get = function(cache_type)
  local path = get_cache_path(cache_type)
  local cache_entry = read_json_file(path)
  if not cache_entry then
    return {data = nil, expired = true, ok = false}
  elseif is_expired(cache_entry, CACHE_TYPES[cache_type]) then
    return {ok = true, data = cache_entry.data, expired = true}
  else
    return {ok = true, data = cache_entry.data, expired = false}
  end
end
M.set = function(cache_type, data)
  local cache_entry = {type = cache_type, timestamp = os.time(), data = data}
  local path = get_cache_path(cache_type)
  local ok = write_json_file(path, cache_entry)
  if ok then
    return {ok = true}
  else
    return {error = "Failed to write cache file", ok = false}
  end
end
M.invalidate = function(cache_type)
  local path = get_cache_path(cache_type)
  if (vim.fn.filereadable(path) == 1) then
    vim.fn.delete(path)
  else
  end
  return {ok = true}
end
M["invalidate-all"] = function()
  for cache_type, _ in pairs(CACHE_TYPES) do
    M.invalidate(cache_type)
  end
  return {ok = true}
end
M["get-or-fetch"] = function(cache_type, fetch_fn)
  local cached = M.get(cache_type)
  if (cached.ok and not cached.expired) then
    return {ok = true, data = cached.data, ["from-cache"] = true}
  else
    local result = fetch_fn()
    if result.ok then
      M.set(cache_type, result.data)
      return {ok = true, data = result.data, ["from-cache"] = false}
    else
      if (cached.ok and cached.data) then
        notify.debug("Using stale cache due to fetch failure")
        return {ok = true, data = cached.data, ["from-cache"] = true, stale = true}
      else
        return result
      end
    end
  end
end
M["get-age"] = function(cache_type)
  local path = get_cache_path(cache_type)
  local cache_entry = read_json_file(path)
  if (cache_entry and cache_entry.timestamp) then
    return (os.time() - cache_entry.timestamp)
  else
    return nil
  end
end
M["get-status"] = function()
  local status = {}
  for cache_type, ttl in pairs(CACHE_TYPES) do
    local path = get_cache_path(cache_type)
    local cache_entry = read_json_file(path)
    local _14_
    if not cache_entry then
      _14_ = {age = nil, expired = true, exists = false}
    else
      local age = (os.time() - (cache_entry.timestamp or 0))
      _14_ = {exists = true, age = age, expired = (age > ttl)}
    end
    status[cache_type] = _14_
  end
  return status
end
M.refresh = function(cache_type, fetch_fn)
  local result = fetch_fn()
  if result.ok then
    M.set(cache_type, result.data)
  else
  end
  return result
end
return M
