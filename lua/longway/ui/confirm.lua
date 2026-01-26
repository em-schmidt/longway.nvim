-- [nfnl] fnl/longway/ui/confirm.fnl
local M = {}
M.confirm = function(message, callback)
  local function _1_(choice)
    return callback((choice == "Yes"))
  end
  return vim.ui.select({"Yes", "No"}, {prompt = message}, _1_)
end
M["confirm-sync"] = function(message, callback)
  local result = vim.fn.confirm(message, "&Yes\n&No", 2)
  local confirmed = (result == 1)
  if callback then
    callback(confirmed)
  else
  end
  return confirmed
end
local function format_task_list(tasks)
  local lines = {}
  for i, task in ipairs(tasks) do
    if (i <= 5) then
      local desc
      if (#(task.description or "") > 40) then
        desc = (string.sub(task.description, 1, 37) .. "...")
      else
        desc = (task.description or "(no description)")
      end
      table.insert(lines, string.format("  \226\128\162 %s", desc))
    else
    end
  end
  if (#tasks > 5) then
    table.insert(lines, string.format("  ... and %d more", (#tasks - 5)))
  else
  end
  return table.concat(lines, "\n")
end
M["confirm-delete-tasks"] = function(tasks, callback)
  local count = #tasks
  local task_list = format_task_list(tasks)
  local message = string.format("Delete %d task(s)?\n\n%s\n\nThis cannot be undone.", count, task_list)
  return M.confirm(message, callback)
end
M["confirm-delete-task-ids"] = function(task_ids, remote_tasks, callback)
  local tasks_to_delete = {}
  for _, id in ipairs(task_ids) do
    local found = nil
    for _0, task in ipairs((remote_tasks or {})) do
      if found then break end
      if (task.id == id) then
        found = task
      else
      end
    end
    table.insert(tasks_to_delete, (found or {id = id, description = string.format("Task #%s", id)}))
  end
  return M["confirm-delete-tasks"](tasks_to_delete, callback)
end
M["confirm-overwrite"] = function(item_type, direction, callback)
  local message
  if (direction == "local") then
    message = string.format("Overwrite local %s with remote version?", item_type)
  else
    message = string.format("Overwrite remote %s with local version?", item_type)
  end
  return M.confirm(message, callback)
end
M["prompt-delete-or-skip"] = function(tasks, callback)
  local count = #tasks
  local task_list = format_task_list(tasks)
  local function _8_(choice)
    if (choice == "Delete from Shortcut") then
      return callback("delete")
    elseif (choice == "Keep in Shortcut (skip delete)") then
      return callback("skip")
    else
      return callback(nil)
    end
  end
  return vim.ui.select({"Delete from Shortcut", "Keep in Shortcut (skip delete)", "Cancel"}, {prompt = string.format("%d task(s) removed locally:\n\n%s\n\nWhat should happen on Shortcut?", count, task_list)}, _8_)
end
return M
