-- Cache module for longway.nvim
-- Compiled from fnl/longway/cache/store.fnl

local config = require("longway.config")
local notify = require("longway.ui.notify")

local M = {}

local DEFAULT_TTL = 3600

local CACHE_TYPES = {
  members = 3600,
  workflows = 86400,
  iterations = 3600,
  teams = 3600,
  labels = 3600,
  projects = 3600
}

local function get_cache_dir()
  return config.get_workspace_dir() .. "/.longway/cache"
end

local function get_cache_path(cache_type)
  return get_cache_dir() .. "/" .. cache_type .. ".json"
end

local function ensure_cache_dir()
  local cache_dir = get_cache_dir()
  if vim.fn.isdirectory(cache_dir) ~= 1 then
    vim.fn.mkdir(cache_dir, "p")
  end
end

local function read_json_file(path)
  if vim.fn.filereadable(path) == 1 then
    local content = vim.fn.readfile(path)
    local text = table.concat(content, "\n")
    if #text > 0 then
      local ok, data = pcall(vim.json.decode, text)
      if ok then
        return data
      end
    end
  end
  return nil
end

local function write_json_file(path, data)
  ensure_cache_dir()
  local ok, json = pcall(vim.json.encode, data)
  if ok then
    vim.fn.writefile({ json }, path)
    return true
  end
  return false
end

local function is_expired(cache_entry, ttl)
  if not cache_entry then
    return true
  end
  if not cache_entry.timestamp then
    return true
  end
  local now = os.time()
  local age = now - cache_entry.timestamp
  local effective_ttl = ttl or CACHE_TYPES[cache_entry.type] or DEFAULT_TTL
  return age > effective_ttl
end

function M.get(cache_type)
  local path = get_cache_path(cache_type)
  local cache_entry = read_json_file(path)
  if not cache_entry then
    return { ok = false, data = nil, expired = true }
  elseif is_expired(cache_entry, CACHE_TYPES[cache_type]) then
    return { ok = true, data = cache_entry.data, expired = true }
  else
    return { ok = true, data = cache_entry.data, expired = false }
  end
end

function M.set(cache_type, data)
  local cache_entry = {
    type = cache_type,
    timestamp = os.time(),
    data = data
  }
  local path = get_cache_path(cache_type)
  local ok = write_json_file(path, cache_entry)
  if ok then
    return { ok = true }
  else
    return { ok = false, error = "Failed to write cache file" }
  end
end

function M.invalidate(cache_type)
  local path = get_cache_path(cache_type)
  if vim.fn.filereadable(path) == 1 then
    vim.fn.delete(path)
  end
  return { ok = true }
end

function M.invalidate_all()
  for cache_type, _ in pairs(CACHE_TYPES) do
    M.invalidate(cache_type)
  end
  return { ok = true }
end

function M.get_or_fetch(cache_type, fetch_fn)
  local cached = M.get(cache_type)
  if cached.ok and not cached.expired then
    return { ok = true, data = cached.data, from_cache = true }
  end
  local result = fetch_fn()
  if result.ok then
    M.set(cache_type, result.data)
    return { ok = true, data = result.data, from_cache = false }
  else
    if cached.ok and cached.data then
      notify.debug("Using stale cache due to fetch failure")
      return { ok = true, data = cached.data, from_cache = true, stale = true }
    end
    return result
  end
end

function M.get_age(cache_type)
  local path = get_cache_path(cache_type)
  local cache_entry = read_json_file(path)
  if cache_entry and cache_entry.timestamp then
    return os.time() - cache_entry.timestamp
  end
  return nil
end

function M.get_status()
  local status = {}
  for cache_type, ttl in pairs(CACHE_TYPES) do
    local path = get_cache_path(cache_type)
    local cache_entry = read_json_file(path)
    if not cache_entry then
      status[cache_type] = { exists = false, age = nil, expired = true }
    else
      local age = os.time() - (cache_entry.timestamp or 0)
      status[cache_type] = { exists = true, age = age, expired = age > ttl }
    end
  end
  return status
end

function M.refresh(cache_type, fetch_fn)
  local result = fetch_fn()
  if result.ok then
    M.set(cache_type, result.data)
  end
  return result
end

return M
