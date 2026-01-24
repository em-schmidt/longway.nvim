-- [nfnl] fnl/longway-spec/mocks/curl.fnl
local M = {}
local response = nil
local calls = {}
local response_queue = {}
M.reset = function()
  response = nil
  calls = {}
  response_queue = {}
  return nil
end
M["setup-response"] = function(resp)
  response = resp
  return nil
end
M["queue-response"] = function(resp)
  return table.insert(response_queue, resp)
end
M["get-response"] = function()
  if (#response_queue > 0) then
    return table.remove(response_queue, 1)
  else
    return response
  end
end
M.request = function(opts)
  table.insert(calls, opts)
  local resp = M["get-response"]()
  return (resp or {status = 200, body = "{}"})
end
M.get = function(url, opts)
  return M.request(vim.tbl_extend("force", (opts or {}), {url = url, method = "GET"}))
end
M.post = function(url, opts)
  return M.request(vim.tbl_extend("force", (opts or {}), {url = url, method = "POST"}))
end
M.put = function(url, opts)
  return M.request(vim.tbl_extend("force", (opts or {}), {url = url, method = "PUT"}))
end
M.delete = function(url, opts)
  return M.request(vim.tbl_extend("force", (opts or {}), {url = url, method = "DELETE"}))
end
M["last-call"] = function()
  return calls[#calls]
end
M["call-count"] = function()
  return #calls
end
M["get-calls"] = function()
  return calls
end
M["has-header"] = function(call, header_name)
  if (call and call.headers) then
    for _, h in ipairs(call.headers) do
      if string.find(h, header_name, 1, true) then
        return true
      else
      end
    end
  else
  end
  return false
end
M["get-header"] = function(call, header_name)
  if (call and call.headers) then
    for _, h in ipairs(call.headers) do
      local pattern = (header_name .. ":%s*(.+)")
      local value = string.match(h, pattern)
      if value then
        return value
      else
      end
    end
  else
  end
  return nil
end
return M
