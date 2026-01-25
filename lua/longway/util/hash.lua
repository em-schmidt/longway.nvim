-- [nfnl] fnl/longway/util/hash.fnl
local M = {}
M.djb2 = function(str)
  local hash = 5381
  for i = 1, #str do
    local c = string.byte(str, i)
    hash = ((hash * 33) + c)
    hash = (hash % 2147483647)
  end
  return string.format("%08x", hash)
end
M["content-hash"] = function(content)
  local normalized = string.gsub(string.gsub(string.gsub(string.gsub(content, "\r\n", "\n"), "[ \t]+\n", "\n"), "^%s+", ""), "%s+$", "")
  return M.djb2(normalized)
end
M["has-changed"] = function(old_hash, new_content)
  local new_hash = M["content-hash"](new_content)
  return (old_hash ~= new_hash)
end
return M
