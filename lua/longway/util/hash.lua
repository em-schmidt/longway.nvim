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
M["tasks-hash"] = function(tasks)
  if (not tasks or (#tasks == 0)) then
    return M.djb2("")
  else
    local sorted = vim.deepcopy(tasks)
    local function _1_(a, b)
      if (a.id and b.id) then
        return (a.id < b.id)
      else
        if a.id then
          return false
        else
          if b.id then
            return true
          else
            return ((a.description or "") < (b.description or ""))
          end
        end
      end
    end
    table.sort(sorted, _1_)
    local parts = {}
    for _, task in ipairs(sorted) do
      local function _5_()
        if task.complete then
          return "true"
        else
          return "false"
        end
      end
      table.insert(parts, string.format("%s|%s|%s", (task.id or "new"), (task.description or ""), _5_()))
    end
    return M.djb2(table.concat(parts, "\n"))
  end
end
M["tasks-changed?"] = function(old_hash, tasks)
  local new_hash = M["tasks-hash"](tasks)
  return (old_hash ~= new_hash)
end
return M
