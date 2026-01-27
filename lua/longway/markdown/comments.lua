-- [nfnl] fnl/longway/markdown/comments.fnl
local config = require("longway.config")
local members = require("longway.api.members")
local M = {}
local function safe_text(val)
  if (type(val) == "string") then
    return val
  else
    return ""
  end
end
local function parse_comment_metadata(header_line)
  local pattern = "%*%*(.-)%*%*%s*\194\183%s*([%d%-]+%s*[%d:]+)%s*<!%-%-[%s]*comment:(%S+)%s*%-%->"
  local author, timestamp, id = string.match(header_line, pattern)
  if author then
    local _2_
    if (id == "new") then
      _2_ = nil
    else
      _2_ = tonumber(id)
    end
    return {author = author, timestamp = timestamp, id = _2_, is_new = (id == "new")}
  else
    return nil
  end
end
M["parse-block"] = function(block)
  local lines = {}
  local found_header = false
  local header_data = nil
  for line in string.gmatch((block .. "\n"), "([^\n]*)\n") do
    if not found_header then
      local parsed = parse_comment_metadata(line)
      if parsed then
        found_header = true
        header_data = parsed
      else
      end
    else
      if ((#lines > 0) or not string.match(line, "^%s*$")) then
        table.insert(lines, line)
      else
      end
    end
  end
  if header_data then
    header_data.text = table.concat(lines, "\n")
    return header_data
  else
    return nil
  end
end
M["parse-section"] = function(content)
  local comments = {}
  local blocks = vim.split(content, "\n%-%-%-\n", {trimempty = true, plain = false})
  for _, block in ipairs(blocks) do
    local cmt = M["parse-block"](block)
    if cmt then
      table.insert(comments, cmt)
    else
    end
  end
  return comments
end
M["resolve-author-name"] = function(author_id)
  if not author_id then
    return "Unknown"
  else
    return members["resolve-name"](author_id)
  end
end
M["resolve-author-id"] = function(name)
  if name then
    local member = members["find-by-name"](name)
    if member then
      return member.id
    else
      return nil
    end
  else
    return nil
  end
end
M["get-current-user"] = function()
  local result = members["get-current"]()
  if result.ok then
    return {id = result.data.id, name = members["get-display-name"](result.data)}
  else
    return nil
  end
end
M["format-timestamp"] = function(created_at)
  local cfg = config.get()
  if (not created_at or (type(created_at) ~= "string")) then
    return ""
  else
    local year, month, day, hour, min, sec = string.match(created_at, "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
    if not year then
      return created_at
    else
      local time = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = tonumber(hour), min = tonumber(min), sec = tonumber(sec)})
      local format_str = ((cfg.comments and cfg.comments.timestamp_format) or "%Y-%m-%d %H:%M")
      return os.date(format_str, time)
    end
  end
end
M["render-comment"] = function(cmt)
  local author_name = (cmt.author or "Unknown")
  local timestamp = (cmt.timestamp or "")
  local id_part
  if cmt.id then
    id_part = tostring(cmt.id)
  else
    id_part = "new"
  end
  local metadata = string.format("<!-- comment:%s -->", id_part)
  return table.concat({"---", string.format("**%s** \194\183 %s %s", author_name, timestamp, metadata), "", safe_text(cmt.text)}, "\n")
end
M["render-comments"] = function(comments)
  if (not comments or (#comments == 0)) then
    return ""
  else
    local rendered = {}
    for _, cmt in ipairs(comments) do
      table.insert(rendered, M["render-comment"](cmt))
    end
    return table.concat(rendered, "\n\n")
  end
end
M["render-section"] = function(comments)
  local cfg = config.get()
  local start_marker = string.gsub(cfg.sync_start_marker, "{section}", "comments")
  local end_marker = string.gsub(cfg.sync_end_marker, "{section}", "comments")
  local content = M["render-comments"](comments)
  return (start_marker .. "\n" .. content .. "\n" .. end_marker)
end
M["format-api-comments"] = function(raw_comments)
  local formatted = {}
  for _, cmt in ipairs((raw_comments or {})) do
    local author_name = M["resolve-author-name"](cmt.author_id)
    local timestamp = M["format-timestamp"](cmt.created_at)
    table.insert(formatted, {id = cmt.id, author = author_name, timestamp = timestamp, text = safe_text(cmt.text), is_new = false})
  end
  return formatted
end
M["comment-changed?"] = function(local_comment, remote_comment)
  local local_text = string.gsub((local_comment.text or ""), "^%s*(.-)%s*$", "%1")
  local remote_text = string.gsub((remote_comment.text or ""), "^%s*(.-)%s*$", "%1")
  return (local_text ~= remote_text)
end
M["find-comment-by-id"] = function(comments, id)
  local found = nil
  for _, cmt in ipairs(comments) do
    if found then break end
    if (cmt.id == id) then
      found = cmt
    else
    end
  end
  return found
end
M["comments-equal?"] = function(a, b)
  if (#a ~= #b) then
    return false
  else
    local equal = true
    for i, cmt_a in ipairs(a) do
      if not equal then break end
      local cmt_b = b[i]
      if (not cmt_b or (cmt_a.id ~= cmt_b.id) or (cmt_a.text ~= cmt_b.text)) then
        equal = false
      else
      end
    end
    return equal
  end
end
return M
