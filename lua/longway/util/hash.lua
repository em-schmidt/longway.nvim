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
M["normalize-stored-hash"] = function(value)
  local s = tostring((value or ""))
  if (s == "") then
    return ""
  elseif (string.match(s, "^%x+$") and (#s < 8)) then
    return (string.rep("0", (8 - #s)) .. s)
  else
    return s
  end
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
    local function _2_(a, b)
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
    table.sort(sorted, _2_)
    local parts = {}
    for _, task in ipairs(sorted) do
      local function _6_()
        if task.complete then
          return "true"
        else
          return "false"
        end
      end
      table.insert(parts, string.format("%s|%s|%s", (task.id or "new"), (task.description or ""), _6_()))
    end
    return M.djb2(table.concat(parts, "\n"))
  end
end
M["tasks-changed?"] = function(old_hash, tasks)
  local new_hash = M["tasks-hash"](tasks)
  return (old_hash ~= new_hash)
end
M["comments-hash"] = function(comments)
  if (not comments or (#comments == 0)) then
    return M.djb2("")
  else
    local sorted = vim.deepcopy(comments)
    local function _8_(a, b)
      if (a.id and b.id) then
        return (a.id < b.id)
      else
        if a.id then
          return false
        else
          if b.id then
            return true
          else
            return ((a.text or "") < (b.text or ""))
          end
        end
      end
    end
    table.sort(sorted, _8_)
    local parts = {}
    for _, cmt in ipairs(sorted) do
      table.insert(parts, string.format("%s|%s", (cmt.id or "new"), (cmt.text or "")))
    end
    return M.djb2(table.concat(parts, "\n"))
  end
end
M["comments-changed?"] = function(old_hash, comments)
  local new_hash = M["comments-hash"](comments)
  return (old_hash ~= new_hash)
end
return M
