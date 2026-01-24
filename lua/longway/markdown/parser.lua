-- [nfnl] fnl/longway/markdown/parser.fnl
local config = require("longway.config")
local frontmatter = require("longway.markdown.frontmatter")
local M = {}
local function get_sync_markers(section_name)
  local cfg = config.get()
  local start_marker = string.gsub(cfg.sync_start_marker, "{section}", section_name)
  local end_marker = string.gsub(cfg.sync_end_marker, "{section}", section_name)
  return {start_marker, end_marker}
end
local function extract_sync_section(content, section_name)
  local _let_1_ = get_sync_markers(section_name)
  local start_marker = _let_1_[1]
  local end_marker = _let_1_[2]
  local start_escaped = string.gsub(start_marker, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
  local end_escaped = string.gsub(end_marker, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
  local pattern = (start_escaped .. "\n(.-)\n" .. end_escaped)
  local result = string.match(content, pattern)
  return result
end
M["extract-description"] = function(content)
  return extract_sync_section(content, "description")
end
local function parse_task_line(line)
  local checkbox_pattern = "^%s*%-%s*%[([x ])%]%s*(.+)$"
  local checkbox, rest = string.match(line, checkbox_pattern)
  if checkbox then
    local complete = (checkbox == "x")
    local metadata_pattern = "(.-)%s*<!%-%-%s*task:(%S+)%s*(.-)%s*complete:(%S+)%s*%-%->"
    local description, id, extras, complete_str = string.match(rest, metadata_pattern)
    if description then
      local _2_
      if (id == "new") then
        _2_ = nil
      else
        _2_ = tonumber(id)
      end
      return {description = string.gsub(description, "%s+$", ""), id = _2_, complete = complete, is_new = (id == "new"), owner_mention = string.match(extras, "@(%S+)")}
    else
      return {description = string.gsub(rest, "%s+$", ""), id = nil, complete = complete, is_new = true, owner_mention = nil}
    end
  else
    return nil
  end
end
M["extract-tasks"] = function(content)
  local tasks_content = extract_sync_section(content, "tasks")
  if not tasks_content then
    return {}
  else
    local tasks = {}
    for line in string.gmatch(tasks_content, "[^\n]+") do
      local task = parse_task_line(line)
      if task then
        table.insert(tasks, task)
      else
      end
    end
    return tasks
  end
end
local function parse_comment_block(block)
  local header_pattern = "%*%*(.-)%*%*%s*\194\183%s*([%d%-]+%s*[%d:]+)%s*<!%-%-%s*comment:(%S+)%s*%-%->"
  local lines = {}
  local found_header = false
  local header_line = nil
  for line in string.gmatch((block .. "\n"), "([^\n]*)\n") do
    if not found_header then
      local author, timestamp, id = string.match(line, header_pattern)
      if author then
        found_header = true
        local _8_
        if (id == "new") then
          _8_ = nil
        else
          _8_ = tonumber(id)
        end
        header_line = {author = author, timestamp = timestamp, id = _8_, is_new = (id == "new")}
      else
      end
    else
      if ((#lines > 0) or not string.match(line, "^%s*$")) then
        table.insert(lines, line)
      else
      end
    end
  end
  if header_line then
    header_line.text = table.concat(lines, "\n")
    return header_line
  else
    return nil
  end
end
M["extract-comments"] = function(content)
  local comments_content = extract_sync_section(content, "comments")
  if not comments_content then
    return {}
  else
    local comments = {}
    local blocks = vim.split(comments_content, "\n%-%-%-\n", {trimempty = true, plain = false})
    for _, block in ipairs(blocks) do
      local cmt = parse_comment_block(block)
      if cmt then
        table.insert(comments, cmt)
      else
      end
    end
    return comments
  end
end
M.parse = function(content)
  local parsed_fm = frontmatter.parse(content)
  local description = M["extract-description"](content)
  local tasks = M["extract-tasks"](content)
  local comments = M["extract-comments"](content)
  return {frontmatter = parsed_fm.frontmatter, description = description, tasks = tasks, comments = comments, body = parsed_fm.body, raw_frontmatter = parsed_fm.raw_frontmatter}
end
M["get-shortcut-id"] = function(content)
  local parsed = frontmatter.parse(content)
  return parsed.frontmatter.shortcut_id
end
M["get-shortcut-type"] = function(content)
  local parsed = frontmatter.parse(content)
  return (parsed.frontmatter.shortcut_type or "story")
end
M["is-longway-file"] = function(content)
  local parsed = frontmatter.parse(content)
  return not not parsed.frontmatter.shortcut_id
end
return M
