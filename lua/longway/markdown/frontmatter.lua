-- YAML frontmatter handling for longway.nvim
-- Compiled from fnl/longway/markdown/frontmatter.fnl

local M = {}

local function serialize_value(value, indent)
  indent = indent or 0
  local spaces = string.rep("  ", indent)

  if type(value) == "string" then
    if value:find("\n") or value:find(":") or value:find('"') or value:find("'") then
      return '"' .. value:gsub('"', '\\"') .. '"'
    elseif value:match("^%d+$") then
      return '"' .. value .. '"'  -- Quote numeric strings
    else
      return value
    end
  elseif type(value) == "number" then
    return tostring(value)
  elseif type(value) == "boolean" then
    return value and "true" or "false"
  elseif value == nil then
    return "null"
  elseif type(value) == "table" then
    if vim.islist(value) then
      -- Array
      local items = {}
      for _, v in ipairs(value) do
        table.insert(items, "\n" .. spaces .. "  - " .. serialize_value(v, indent + 1))
      end
      return table.concat(items, "")
    else
      -- Object
      local items = {}
      for k, v in pairs(value) do
        local key = tostring(k)
        if type(v) == "table" then
          table.insert(items, "\n" .. spaces .. "  " .. key .. ":" .. serialize_value(v, indent + 1))
        else
          table.insert(items, "\n" .. spaces .. "  " .. key .. ": " .. serialize_value(v, indent + 1))
        end
      end
      return table.concat(items, "")
    end
  else
    return tostring(value)
  end
end

function M.generate(data)
  local lines = { "---" }

  for key, value in pairs(data) do
    local k = tostring(key)
    -- Skip internal fields starting with _
    if not k:match("^_") then
      if type(value) == "table" then
        if vim.islist(value) then
          table.insert(lines, k .. ":")
          for _, v in ipairs(value) do
            if type(v) == "table" then
              table.insert(lines, "  -")
              for ik, iv in pairs(v) do
                table.insert(lines, "    " .. tostring(ik) .. ": " .. serialize_value(iv, 2))
              end
            else
              table.insert(lines, "  - " .. serialize_value(v, 1))
            end
          end
        else
          table.insert(lines, k .. ":")
          for ik, iv in pairs(value) do
            table.insert(lines, "  " .. tostring(ik) .. ": " .. serialize_value(iv, 1))
          end
        end
      else
        table.insert(lines, k .. ": " .. serialize_value(value, 0))
      end
    end
  end

  table.insert(lines, "---")
  return table.concat(lines, "\n")
end

local function parse_yaml_value(str)
  local trimmed = str:gsub("^%s*(.-)%s*$", "%1")

  if trimmed == "true" then
    return true
  elseif trimmed == "false" then
    return false
  elseif trimmed == "null" or trimmed == "~" then
    return nil
  end

  -- Quoted string
  local quoted = trimmed:match('^"(.*)"$')
  if quoted then
    return quoted:gsub('\\"', '"')
  end

  quoted = trimmed:match("^'(.*)'$")
  if quoted then
    return quoted
  end

  -- Number
  local num = tonumber(trimmed)
  if num then
    return num
  end

  -- Plain string
  return trimmed
end

function M.parse(content)
  local start_pattern = "^%-%-%-\n"
  local end_pattern = "\n%-%-%-\n"

  local start_match = content:find(start_pattern)
  if start_match ~= 1 then
    return { frontmatter = {}, body = content, raw_frontmatter = nil }
  end

  local end_start = content:find(end_pattern, 4)
  if not end_start then
    return { frontmatter = {}, body = content, raw_frontmatter = nil }
  end

  local yaml_content = content:sub(5, end_start - 1)
  local body = content:sub(end_start + 5)
  local frontmatter = {}
  local current_key = nil
  local current_list = nil
  local current_obj = nil

  -- Simple line-by-line YAML parser
  for line in (yaml_content .. "\n"):gmatch("([^\n]*)\n") do
    local k, v = line:match("^([%w_]+):%s*(.*)$")
    local list_item = line:match("^%s*%-%s*(.*)$")
    local nk, nv = line:match("^%s+([%w_]+):%s*(.*)$")

    if k then
      if v == "" then
        current_key = k
        current_list = {}
        current_obj = nil
      else
        if current_key and current_list and #current_list > 0 then
          frontmatter[current_key] = current_list
        end
        if current_key and current_obj then
          frontmatter[current_key] = current_obj
        end
        current_key = nil
        current_list = nil
        current_obj = nil
        frontmatter[k] = parse_yaml_value(v)
      end
    elseif list_item and current_key and current_list then
      table.insert(current_list, parse_yaml_value(list_item))
    elseif nk and current_key then
      if not current_obj then
        current_obj = {}
      end
      current_obj[nk] = parse_yaml_value(nv)
    end
  end

  -- Flush any remaining list/obj
  if current_key and current_list and #current_list > 0 then
    frontmatter[current_key] = current_list
  end
  if current_key and current_obj then
    frontmatter[current_key] = current_obj
  end

  return { frontmatter = frontmatter, body = body, raw_frontmatter = yaml_content }
end

return M
