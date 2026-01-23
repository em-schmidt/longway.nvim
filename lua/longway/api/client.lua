-- HTTP client wrapper for Shortcut API
-- Compiled from fnl/longway/api/client.fnl

local curl = require("plenary.curl")
local config = require("longway.config")
local notify = require("longway.ui.notify")

local M = {}

-- Base URL for Shortcut API
local BASE_URL = "https://api.app.shortcut.com/api/v3"

local function build_headers()
  local token = config.get_token()
  return {
    ["Content-Type"] = "application/json",
    ["Shortcut-Token"] = token,
  }
end

local function handle_response(response)
  local status = response.status
  local body = response.body

  if status >= 200 and status < 300 then
    -- Success
    if body and #body > 0 then
      return { ok = true, data = vim.json.decode(body) }
    else
      return { ok = true, data = nil }
    end
  else
    -- Error
    local error_msg
    if body and #body > 0 then
      local ok, err_data = pcall(vim.json.decode, body)
      if ok then
        error_msg = err_data.message or err_data.error or body
      else
        error_msg = body
      end
    else
      error_msg = string.format("HTTP %d", status)
    end
    return { ok = false, status = status, error = error_msg }
  end
end

function M.request(method, endpoint, opts)
  local token = config.get_token()
  if not token then
    notify.no_token()
    return { ok = false, error = "No API token configured" }
  end

  local url = BASE_URL .. endpoint
  local headers = build_headers()
  local request_opts = {
    url = url,
    method = method,
    headers = headers,
    timeout = 30000,
  }

  -- Add body for POST/PUT requests
  if opts and opts.body then
    request_opts.body = vim.json.encode(opts.body)
  end

  -- Add query params for GET requests
  if opts and opts.query then
    request_opts.query = opts.query
  end

  notify.debug(string.format("API %s %s", method, endpoint))

  local ok, response = pcall(curl.request, request_opts)
  if ok then
    return handle_response(response)
  else
    return { ok = false, error = tostring(response) }
  end
end

function M.get(endpoint, opts)
  return M.request("get", endpoint, opts)
end

function M.post(endpoint, opts)
  return M.request("post", endpoint, opts)
end

function M.put(endpoint, opts)
  return M.request("put", endpoint, opts)
end

function M.delete(endpoint, opts)
  return M.request("delete", endpoint, opts)
end

return M
