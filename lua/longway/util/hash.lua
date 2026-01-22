-- Content hashing utilities for longway.nvim
-- Compiled from fnl/longway/util/hash.fnl

local M = {}

function M.djb2(str)
  local hash = 5381
  for i = 1, #str do
    local c = str:byte(i)
    hash = ((hash * 33) + c) % 0x7FFFFFFF
  end
  return string.format("%08x", hash)
end

function M.content_hash(content)
  local normalized = content
  -- Normalize line endings
  normalized = normalized:gsub("\r\n", "\n")
  -- Trim trailing whitespace from lines
  normalized = normalized:gsub("[ \t]+\n", "\n")
  -- Trim leading/trailing whitespace
  normalized = normalized:gsub("^%s+", "")
  normalized = normalized:gsub("%s+$", "")
  return M.djb2(normalized)
end

function M.has_changed(old_hash, new_content)
  local new_hash = M.content_hash(new_content)
  return old_hash ~= new_hash
end

return M
