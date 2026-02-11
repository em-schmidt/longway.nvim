-- [nfnl] fnl/longway/markdown/parser.fnl
local config = require("longway.config")
local frontmatter = require("longway.markdown.frontmatter")
local tasks_md = require("longway.markdown.tasks")
local comments_md = require("longway.markdown.comments")
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
M["extract-tasks"] = function(content)
  local tasks_content = extract_sync_section(content, "tasks")
  if not tasks_content then
    return {}
  else
    return tasks_md["parse-section"](tasks_content)
  end
end
M["extract-comments"] = function(content)
  local comments_content = extract_sync_section(content, "comments")
  if not comments_content then
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
