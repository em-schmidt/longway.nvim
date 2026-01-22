-- Core functionality for longway.nvim
-- Compiled from fnl/longway/core.fnl

local config = require("longway.config")
local pull = require("longway.sync.pull")
local push = require("longway.sync.push")
local notify = require("longway.ui.notify")

local M = {}

function M.hello()
  print("Hello from longway.nvim!")
end

function M.get_info()
  local cfg = config.get()
  return {
    name = "longway.nvim",
    version = "0.1.0",
    author = "Eric Schmidt",
    configured = config.is_configured(),
    workspace_dir = config.get_workspace_dir(),
    debug = cfg.debug,
  }
end

function M.pull(story_id)
  if not config.is_configured() then
    notify.no_token()
    return
  end
  return pull.pull_story_to_buffer(story_id)
end

function M.push()
  if not config.is_configured() then
    notify.no_token()
    return
  end
  return push.push_current_buffer()
end

function M.refresh()
  if not config.is_configured() then
    notify.no_token()
    return
  end
  return pull.refresh_current_buffer()
end

function M.open_in_browser()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local parser = require("longway.markdown.parser")
  local parsed = parser.parse(content)
  local url = parsed.frontmatter.shortcut_url

  if url then
    vim.fn.system({ vim.g.longway_browser or "xdg-open", url })
    notify.info(string.format("Opening %s", url))
  else
    notify.error("No shortcut_url found in frontmatter")
  end
end

function M.status()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  if filepath == "" then
    notify.error("No file in current buffer")
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local parser = require("longway.markdown.parser")
  local parsed = parser.parse(content)
  local fm = parsed.frontmatter

  if not fm.shortcut_id then
    notify.info("Not a longway-managed file")
    return
  end

  print(string.format("Shortcut ID: %s", tostring(fm.shortcut_id)))
  print(string.format("Type: %s", fm.shortcut_type or "story"))
  print(string.format("State: %s", fm.state or "unknown"))
  if fm.shortcut_url then
    print(string.format("URL: %s", fm.shortcut_url))
  end
  if fm.updated_at then
    print(string.format("Last updated: %s", fm.updated_at))
  end
  if fm.local_updated_at then
    print(string.format("Local updated: %s", fm.local_updated_at))
  end
end

return M
