-- [nfnl] fnl/longway-spec/mocks/notify.fnl
local M = {}
local notifications = {}
M.reset = function()
  notifications = {}
  return nil
end
M.notify = function(message, level)
  return table.insert(notifications, {message = message, level = level})
end
M["last-notification"] = function()
  return notifications[#notifications]
end
M["notification-count"] = function()
  return #notifications
end
M["get-notifications"] = function()
  return notifications
end
M["has-notification-with"] = function(substring)
  for _, n in ipairs(notifications) do
    if string.find(n.message, substring, 1, true) then
      return true
    else
    end
  end
  return false
end
M["get-notifications-by-level"] = function(level)
  local results = {}
  for _, n in ipairs(notifications) do
    if (n.level == level) then
      table.insert(results, n)
    else
    end
  end
  return results
end
return M
