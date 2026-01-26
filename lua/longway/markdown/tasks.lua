local config = require("longway.config")
local members = require("longway.api.members")
local M = {}
local function parse_task_metadata(metadata_str)
  local result = {id = nil, owner_mention = nil, complete = false, is_new = false}
  do
    local id_match = string.match(metadata_str, "task:(%S+)")
    if (id_match == "new") then
      result.is_new = true
    else
      result.id = tonumber(id_match)
    end
  end
  do
    local owner_match = string.match(metadata_str, "@(%S+)")
    if owner_match then
      result.owner_mention = owner_match
    else
    end
  end
  do
    local complete_match = string.match(metadata_str, "complete:(%S+)")
    result.complete = (complete_match == "true")
  end
  return result
end
M["parse-line"] = function(line)
  local checkbox_pattern = "^%s*%-%s*%[([x ])%]%s*(.+)$"
  local checkbox, rest = string.match(line, checkbox_pattern)
  if checkbox then
    local checkbox_complete = (checkbox == "x")
    local metadata_pattern = "(.-)%s*<!%-%-(.-)%-%->%s*$"
    local description, metadata_str = string.match(rest, metadata_pattern)
    if metadata_str then
      local meta = parse_task_metadata(metadata_str)
      return {description = string.gsub(description, "%s+$", ""), id = meta.id, complete = checkbox_complete, is_new = meta.is_new, owner_mention = meta.owner_mention, owner_ids = {}, raw_line = line}
    else
      return {description = string.gsub(rest, "%s+$", ""), id = nil, complete = checkbox_complete, is_new = true, owner_mention = nil, owner_ids = {}, raw_line = line}
    end
  else
    return nil
  end
end
M["parse-section"] = function(content)
  local tasks = {}
  local position = 0
  for line in string.gmatch(content, "[^\n]+") do
    local task = M["parse-line"](line)
    if task then
      position = (position + 1)
      task.position = position
      table.insert(tasks, task)
    else
    end
  end
  return tasks
end
M["resolve-owner-mention"] = function(mention)
  if mention then
    local member = members["find-by-name"](mention)
    if member then
      return member.id
    else
      return nil
    end
  else
    return nil
  end
end
M["resolve-owner-id"] = function(member_id)
  if member_id then
    return members["resolve-name"](member_id)
  else
    return nil
  end
end
M["resolve-task-owners"] = function(task)
  if (task.owner_mention and (not task.owner_ids or (#task.owner_ids == 0))) then
    local owner_id = M["resolve-owner-mention"](task.owner_mention)
    if owner_id then
      task.owner_ids = {owner_id}
    else
    end
  else
  end
  return task
end
M["get-current-user-id"] = function()
  local result = members["get-current"]()
  if result.ok then
    return result.data.id
  else
    return nil
  end
end
local function format_owner_mention(task)
  local cfg = config.get()
  if not cfg.tasks.show_owners then
    return ""
  else
    if task.owner_mention then
      return (" @" .. task.owner_mention)
    else
      if (task.owner_ids and (#task.owner_ids > 0)) then
        local first_owner = task.owner_ids[1]
        local member = members["find-by-id"](first_owner)
        if (member and member.profile and member.profile.mention_name) then
          return (" @" .. member.profile.mention_name)
        else
          if (member and member.profile and member.profile.name) then
            return (" @" .. string.gsub(member.profile.name, " ", "_"))
          else
            return ""
          end
        end
      else
        return ""
      end
    end
  end
end
M["render-task"] = function(task)
  local checkbox
  if task.complete then
    checkbox = "[x]"
  else
    checkbox = "[ ]"
  end
  local owner_part = format_owner_mention(task)
  local id_part
  if task.id then
    id_part = tostring(task.id)
  else
    id_part = "new"
  end
  local complete_str
  if task.complete then
    complete_str = "true"
  else
    complete_str = "false"
  end
  local metadata = string.format("<!-- task:%s%s complete:%s -->", id_part, owner_part, complete_str)
  return string.format("- %s %s %s", checkbox, task.description, metadata)
end
M["render-tasks"] = function(tasks)
  if (not tasks or (#tasks == 0)) then
    return ""
  else
    local lines = {}
    local function _20_(a, b)
      return ((a.position or 0) < (b.position or 0))
    end
    table.sort(tasks, _20_)
    for _, task in ipairs(tasks) do
      table.insert(lines, M["render-task"](task))
    end
    return table.concat(lines, "\n")
  end
end
M["render-section"] = function(tasks)
  local cfg = config.get()
  local start_marker = string.gsub(cfg.sync_start_marker, "{section}", "tasks")
  local end_marker = string.gsub(cfg.sync_end_marker, "{section}", "tasks")
  local content = M["render-tasks"](tasks)
  return (start_marker .. "\n" .. content .. "\n" .. end_marker)
end
M["task-changed?"] = function(local_task, remote_task)
  if (local_task.complete ~= remote_task.complete) then
    return true
  else
    local local_desc = string.gsub((local_task.description or ""), "^%s*(.-)%s*$", "%1")
    local remote_desc = string.gsub((remote_task.description or ""), "^%s*(.-)%s*$", "%1")
    return (local_desc ~= remote_desc)
  end
end
M["find-task-by-id"] = function(tasks, id)
  local found = nil
  for _, task in ipairs(tasks) do
    if found then break end
    if (task.id == id) then
      found = task
    else
    end
  end
  return found
end
M["tasks-equal?"] = function(a, b)
  if (#a ~= #b) then
    return false
  else
    local equal = true
    for i, task_a in ipairs(a) do
      if not equal then break end
      local task_b = b[i]
      if (not task_b or (task_a.id ~= task_b.id) or (task_a.complete ~= task_b.complete) or (task_a.description ~= task_b.description)) then
        equal = false
      else
      end
    end
    return equal
  end
end
return M
