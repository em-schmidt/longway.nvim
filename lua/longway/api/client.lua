-- [nfnl] fnl/longway/api/client.fnl
local curl = require("plenary.curl")
local config = require("longway.config")
local notify = require("longway.ui.notify")
local M = {}
local BASE_URL = "https://api.app.shortcut.com/api/v3"
local function build_headers()
  local token = config["get-token"]()
  return {["Content-Type"] = "application/json", ["Shortcut-Token"] = token}
end
local function handle_response(response)
  local status = response.status
  local body = response.body
  if ((status >= 200) and (status < 300)) then
    if (body and (#body > 0)) then
      return {ok = true, data = vim.json.decode(body)}
    else
      return {ok = true, data = nil}
    end
  else
    local error_msg
    if (body and (#body > 0)) then
      local ok, err_data = pcall(vim.json.decode, body)
      if ok then
        error_msg = (err_data.message or err_data.error or body)
      else
        error_msg = body
      end
    else
      error_msg = string.format("HTTP %d", status)
    end
    return {status = status, error = error_msg, ok = false}
  end
end
M.request = function(method, endpoint, opts)
  local token = config["get-token"]()
  if not token then
    notify["no-token"]()
    return {error = "No API token configured", ok = false}
  else
    local url = (BASE_URL .. endpoint)
    local headers = build_headers()
    local request_opts = {url = url, method = method, headers = headers, timeout = 30000}
    if (opts and opts.body) then
      request_opts.body = vim.json.encode(opts.body)
    else
    end
    if (opts and opts.query) then
      request_opts.query = opts.query
    else
    end
    notify.debug(string.format("API %s %s", method, endpoint))
    local ok, response = pcall(curl.request, request_opts)
    if ok then
      return handle_response(response)
    else
      return {error = tostring(response), ok = false}
    end
  end
end
M.get = function(endpoint, opts)
  return M.request("get", endpoint, opts)
end
M.post = function(endpoint, opts)
  return M.request("post", endpoint, opts)
end
M.put = function(endpoint, opts)
  return M.request("put", endpoint, opts)
end
M.delete = function(endpoint, opts)
  return M.request("delete", endpoint, opts)
end
return M
