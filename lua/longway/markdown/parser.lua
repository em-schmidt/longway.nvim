-- [nfnl] fnl/longway/markdown/parser.fnl
local frontmatter = require("longway.markdown.frontmatter")
local tasks_md = require("longway.markdown.tasks")
local comments_md = require("longway.markdown.comments")
local M = {}
local known_headers = {"Description", "Tasks", "Comments", "Local Notes", "Stories"}
local function extract_header_section(content, header_name)
  local header_with_nl = ("\n## " .. header_name .. "\n")
  local header_at_start = ("## " .. header_name .. "\n")
  local pos = string.find(content, header_with_nl, 1, true)
  local pos0, header_len
  if pos then
    pos0, header_len = pos, #header_with_nl
  else
    local start_pos = string.find(content, header_at_start, 1, true)
    if (start_pos == 1) then
      pos0, header_len = 1, #header_at_start
    else
      pos0, header_len = nil, 0
    end
  end
  if pos0 then
    local content_start = (pos0 + header_len)
    local next_header_pos = string.find(content, "\n## ", content_start, true)
    local raw
    if next_header_pos then
      raw = string.sub(content, content_start, next_header_pos)
    else
      raw = string.sub(content, content_start)
    end
    local trimmed = string.gsub(string.gsub(raw, "^[\n]+", ""), "[\n%s]+$", "")
    if (trimmed == "") then
      return ""
    else
      return trimmed
    end
  else
    return nil
  end
end
local function has_legacy_sync_markers(content)
  return (nil ~= string.find(content, "<!-- BEGIN SHORTCUT SYNC:", 1, true))
end
local function extract_legacy_sync_section(content, section_name)
  local start_marker = ("<!-- BEGIN SHORTCUT SYNC:" .. section_name .. " -->")
  local end_marker = ("<!-- END SHORTCUT SYNC:" .. section_name .. " -->")
  local start_escaped = string.gsub(start_marker, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
  local end_escaped = string.gsub(end_marker, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
  local pattern = (start_escaped .. "\n(.-)\n" .. end_escaped)
  local result = string.match(content, pattern)
  if result then
    do
      local notify = require("longway.ui.notify")
      notify.warn("File uses legacy sync markers. Run :LongwayRefresh to migrate to header-based format.")
    end
    return result
  else
    return nil
  end
end
local function extract_section(content, section_name)
  local result = extract_header_section(content, section_name)
  if (result ~= nil) then
    return result
  else
    if has_legacy_sync_markers(content) then
      return extract_legacy_sync_section(content, string.lower(section_name))
    else
      return nil
    end
  end
end
M["extract-description"] = function(content)
  return extract_section(content, "Description")
end
M["extract-tasks"] = function(content)
  local tasks_content = extract_section(content, "Tasks")
  if (not tasks_content or (tasks_content == "")) then
    return {}
  else
    return tasks_md["parse-section"](tasks_content)
  end
end
M["extract-comments"] = function(content)
  local comments_content = extract_section(content, "Comments")
  if (not comments_content or (comments_content == "")) then
    return {}
  else
    return comments_md["parse-section"](comments_content)
  end
end
M["extract-local-notes"] = function(content)
  local pattern = "\n## Local Notes\n"
  local pos = string.find(content, pattern, 1, true)
  if pos then
    return string.sub(content, (pos + 1))
  else
    return nil
  end
end
M.parse = function(content)
  local parsed_fm = frontmatter.parse(content)
  local description = M["extract-description"](content)
  local tasks = M["extract-tasks"](content)
  local comments = M["extract-comments"](content)
  local local_notes = M["extract-local-notes"](content)
  return {frontmatter = parsed_fm.frontmatter, description = description, tasks = tasks, comments = comments, local_notes = local_notes, body = parsed_fm.body, raw_frontmatter = parsed_fm.raw_frontmatter}
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
