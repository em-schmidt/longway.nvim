-- [nfnl] fnl/longway/markdown/frontmatter.fnl
local M = {}
local function nil_value_3f(value)
  return ((value == nil) or ((type(value) == "userdata") and (value == vim.NIL)))
end
local function serialize_value(value, indent)
  local indent0 = (indent or 0)
  local spaces = string.rep("  ", indent0)
  if nil_value_3f(value) then
    return "null"
  elseif (type(value) == "string") then
    if (string.find(value, "\n") or string.find(value, ":") or string.find(value, "\"") or string.find(value, "'")) then
      return ("\"" .. string.gsub(value, "\"", "\\\"") .. "\"")
    else
      if (string.match(value, "^%d+$") or tonumber(value)) then
        return ("\"" .. value .. "\"")
      else
        return value
      end
    end
  elseif (type(value) == "number") then
    return tostring(value)
  elseif (type(value) == "boolean") then
    if value then
      return "true"
    else
      return "false"
    end
  elseif (type(value) == "table") then
    if vim.islist(value) then
      local items = {}
      for _, v in ipairs(value) do
        table.insert(items, ("\n" .. spaces .. "  - " .. serialize_value(v, (indent0 + 1))))
      end
      return table.concat(items, "")
    else
      local items = {}
      for k, v in pairs(value) do
        local key = tostring(k)
        if (type(v) == "table") then
          table.insert(items, ("\n" .. spaces .. "  " .. key .. ":" .. serialize_value(v, (indent0 + 1))))
        else
          table.insert(items, ("\n" .. spaces .. "  " .. key .. ": " .. serialize_value(v, (indent0 + 1))))
        end
      end
      return table.concat(items, "")
    end
  else
    return tostring(value)
  end
end
M.generate = function(data)
  local lines = {"---"}
  for key, value in pairs(data) do
    local k = tostring(key)
    if (not string.match(k, "^_") and not nil_value_3f(value)) then
      if (type(value) == "table") then
        if vim.islist(value) then
          table.insert(lines, (k .. ":"))
          for _, v in ipairs(value) do
            if (type(v) == "table") then
              table.insert(lines, "  -")
              for ik, iv in pairs(v) do
                if not nil_value_3f(iv) then
                  table.insert(lines, ("    " .. tostring(ik) .. ": " .. serialize_value(iv, 2)))
                else
                end
              end
            else
              if not nil_value_3f(v) then
                table.insert(lines, ("  - " .. serialize_value(v, 1)))
              else
              end
            end
          end
        else
          table.insert(lines, (k .. ":"))
          for ik, iv in pairs(value) do
            if not nil_value_3f(iv) then
              table.insert(lines, ("  " .. tostring(ik) .. ": " .. serialize_value(iv, 1)))
            else
            end
          end
        end
      else
        table.insert(lines, (k .. ": " .. serialize_value(value, 0)))
      end
    else
    end
  end
  table.insert(lines, "---")
  return table.concat(lines, "\n")
end
local function parse_yaml_value(str)
  local trimmed = string.gsub(str, "^%s*(.-)%s*$", "%1")
  if (trimmed == "true") then
    return true
  elseif (trimmed == "false") then
    return false
  elseif (trimmed == "null") then
    return nil
  elseif (trimmed == "~") then
    return nil
  elseif string.match(trimmed, "^\"(.*)\"$") then
    return string.gsub(string.match(trimmed, "^\"(.*)\"$"), "\\\"", "\"")
  elseif string.match(trimmed, "^'(.*)'$") then
    return string.match(trimmed, "^'(.*)'$")
  elseif (string.match(trimmed, "^%-?%d+%.?%d*$") and not string.match(trimmed, "^%-?0%d")) then
    return tonumber(trimmed)
  else
    return trimmed
  end
end
M.parse = function(content)
  local start_pattern = "^%-%-%-\n"
  local end_pattern = "\n%-%-%-\n"
  local start_match = string.find(content, start_pattern)
  if (start_match ~= 1) then
    return {frontmatter = {}, body = content, raw_frontmatter = nil}
  else
    local end_start = string.find(content, end_pattern, 4)
    if not end_start then
      return {frontmatter = {}, body = content, raw_frontmatter = nil}
    else
      local yaml_content = string.sub(content, 5, (end_start - 1))
      local body = string.sub(content, (end_start + 5))
      local frontmatter = {}
      local current_key = nil
      local current_list = nil
      local current_obj = nil
      for line in string.gmatch((yaml_content .. "\n"), "([^\n]*)\n") do
        local key_value = string.match(line, "^([%w_]+):%s*(.*)$")
        local list_item = string.match(line, "^%s*%-%s*(.*)$")
        local nested_kv = string.match(line, "^%s+([%w_]+):%s*(.*)$")
        if key_value then
          local k, v = string.match(line, "^([%w_]+):%s*(.*)$")
          if (v == "") then
            current_key = k
            current_list = {}
            current_obj = nil
          else
            if (current_key and current_list) then
              frontmatter[current_key] = current_list
            else
            end
            if (current_key and current_obj) then
              frontmatter[current_key] = current_obj
            else
            end
            current_key = nil
            current_list = nil
            current_obj = nil
            frontmatter[k] = parse_yaml_value(v)
          end
        elseif (list_item and current_key and current_list) then
          table.insert(current_list, parse_yaml_value(list_item))
        elseif (nested_kv and current_key) then
          local nk, nv = string.match(line, "^%s+([%w_]+):%s*(.*)$")
          if not current_obj then
            current_obj = {}
          else
          end
          current_obj[nk] = parse_yaml_value(nv)
        else
        end
      end
      if (current_key and current_list and (#current_list > 0)) then
        frontmatter[current_key] = current_list
      else
      end
      if (current_key and current_obj) then
        frontmatter[current_key] = current_obj
      else
      end
      return {frontmatter = frontmatter, body = body, raw_frontmatter = yaml_content}
    end
  end
end
return M
