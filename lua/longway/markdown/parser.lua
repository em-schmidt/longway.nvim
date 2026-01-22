-- Markdown parser for longway.nvim
-- Compiled from fnl/longway/markdown/parser.fnl

local config = require("longway.config")
local frontmatter = require("longway.markdown.frontmatter")

local M = {}

local function get_sync_markers(section_name)
  local cfg = config.get()
  local start_marker = cfg.sync_start_marker:gsub("{section}", section_name)
  local end_marker = cfg.sync_end_marker:gsub("{section}", section_name)
  return start_marker, end_marker
end

local function extract_sync_section(content, section_name)
  local start_marker, end_marker = get_sync_markers(section_name)

  -- Escape special pattern characters
  local start_escaped = start_marker:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
  local end_escaped = end_marker:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")

  local pattern = start_escaped .. "\n(.-)\n" .. end_escaped
  return content:match(pattern)
end

function M.extract_description(content)
  return extract_sync_section(content, "description")
end

local function parse_task_line(line)
  -- Format: - [x] Task description <!-- task:123 @owner complete:true -->
  local checkbox_pattern = "^%s*%-%s*%[([x ])%]%s*(.+)$"
  local checkbox, rest = line:match(checkbox_pattern)

  if not checkbox then
    return nil
  end

  local complete = checkbox == "x"

  -- Extract metadata comment
  local metadata_pattern = "(.-)%s*<!%-%-%s*task:(%S+)%s*(.-)%s*complete:(%S+)%s*%-%->"
  local description, id, extras, complete_str = rest:match(metadata_pattern)

  if description then
    return {
      description = description:gsub("%s+$", ""),
      id = (id == "new") and nil or tonumber(id),
      complete = complete,
      is_new = (id == "new"),
      owner_mention = extras:match("@(%S+)"),
    }
  else
    -- No metadata - might be a new task without proper format
    return {
      description = rest:gsub("%s+$", ""),
      id = nil,
      complete = complete,
      is_new = true,
      owner_mention = nil,
    }
  end
end

function M.extract_tasks(content)
  local tasks_content = extract_sync_section(content, "tasks")
  if not tasks_content then
    return {}
  end

  local tasks = {}
  for line in tasks_content:gmatch("[^\n]+") do
    local task = parse_task_line(line)
    if task then
      table.insert(tasks, task)
    end
  end
  return tasks
end

local function parse_comment_block(block)
  -- Format:
  -- ---
  -- **Author Name** · 2026-01-18 10:30 <!-- comment:123 -->
  --
  -- Comment text here
  local header_pattern = "%*%*(.-)%*%*%s*·%s*([%d%-]+%s*[%d:]+)%s*<!%-%-%s*comment:(%S+)%s*%-%->"

  local lines = {}
  local header_line = nil
  local found_header = false

  for line in (block .. "\n"):gmatch("([^\n]*)\n?") do
    if not found_header then
      local author, timestamp, id = line:match(header_pattern)
      if author then
        found_header = true
        header_line = {
          author = author,
          timestamp = timestamp,
          id = (id == "new") and nil or tonumber(id),
          is_new = (id == "new"),
        }
      end
    else
      -- Collect body lines (skip empty lines at start)
      if #lines > 0 or not line:match("^%s*$") then
        table.insert(lines, line:gsub("\n$", ""))
      end
    end
  end

  if header_line then
    header_line.text = table.concat(lines, "\n")
    return header_line
  end
  return nil
end

function M.extract_comments(content)
  local comments_content = extract_sync_section(content, "comments")
  if not comments_content then
    return {}
  end

  local comments = {}
  -- Split by --- separator
  local blocks = vim.split(comments_content, "\n%-%-%-\n", { plain = false, trimempty = true })

  for _, block in ipairs(blocks) do
    local comment = parse_comment_block(block)
    if comment then
      table.insert(comments, comment)
    end
  end
  return comments
end

function M.parse(content)
  local parsed_fm = frontmatter.parse(content)
  local description = M.extract_description(content)
  local tasks = M.extract_tasks(content)
  local comments = M.extract_comments(content)

  return {
    frontmatter = parsed_fm.frontmatter,
    description = description,
    tasks = tasks,
    comments = comments,
    body = parsed_fm.body,
    raw_frontmatter = parsed_fm.raw_frontmatter,
  }
end

function M.get_shortcut_id(content)
  local parsed = frontmatter.parse(content)
  return parsed.frontmatter.shortcut_id
end

function M.get_shortcut_type(content)
  local parsed = frontmatter.parse(content)
  return parsed.frontmatter.shortcut_type or "story"
end

function M.is_longway_file(content)
  local parsed = frontmatter.parse(content)
  return parsed.frontmatter.shortcut_id ~= nil
end

return M
