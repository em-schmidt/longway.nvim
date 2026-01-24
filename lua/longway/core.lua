-- Core functionality for longway.nvim
-- Compiled from fnl/longway/core.fnl

local config = require("longway.config")
local pull = require("longway.sync.pull")
local push = require("longway.sync.push")
local notify = require("longway.ui.notify")
local cache = require("longway.cache.store")

local M = {}

function M.hello()
  print("Hello from longway.nvim!")
end

function M.get_info()
  local cfg = config.get()
  return {
    name = "longway.nvim",
    version = "0.2.0",
    author = "Eric Schmidt",
    configured = config.is_configured(),
    workspace_dir = config.get_workspace_dir(),
    presets = config.get_presets(),
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
    vim.ui.open(url)
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

-- Phase 2: Sync and filtering functions

function M.pull_epic(epic_id)
  if not config.is_configured() then
    notify.no_token()
    return
  end
  return pull.pull_epic_to_buffer(epic_id)
end

function M.sync(query_or_preset)
  if not config.is_configured() then
    notify.no_token()
    return
  end
  if not query_or_preset then
    local default_preset = config.get_default_preset()
    if default_preset then
      return pull.sync_preset(default_preset)
    else
      notify.error("No query or preset specified")
      return { ok = false, error = "No query or preset specified" }
    end
  end
  -- Check if it's a query (contains :) or preset name
  if string.find(query_or_preset, ":") then
    return pull.sync_stories(query_or_preset)
  else
    local preset = config.get_preset(query_or_preset)
    if preset then
      return pull.sync_preset(query_or_preset)
    else
      return pull.sync_stories(query_or_preset)
    end
  end
end

function M.sync_all()
  if not config.is_configured() then
    notify.no_token()
    return
  end
  return pull.sync_all_presets()
end

function M.cache_refresh(cache_type)
  if not config.is_configured() then
    notify.no_token()
    return
  end
  if cache_type then
    local api_module = nil
    if cache_type == "members" then
      api_module = require("longway.api.members")
    elseif cache_type == "workflows" then
      api_module = require("longway.api.workflows")
    elseif cache_type == "iterations" then
      api_module = require("longway.api.iterations")
    elseif cache_type == "teams" then
      api_module = require("longway.api.teams")
    end
    if api_module then
      notify.info(string.format("Refreshing %s cache...", cache_type))
      local result = api_module.refresh_cache()
      if result.ok then
        notify.info(string.format("%s cache refreshed", cache_type))
      else
        notify.error(string.format("Failed to refresh %s cache: %s", cache_type, result.error or "unknown"))
      end
    else
      notify.error(string.format("Unknown cache type: %s", cache_type))
    end
  else
    -- Refresh all caches
    notify.info("Refreshing all caches...")
    local members = require("longway.api.members")
    local workflows = require("longway.api.workflows")
    local iterations = require("longway.api.iterations")
    local teams = require("longway.api.teams")
    members.refresh_cache()
    workflows.refresh_cache()
    iterations.refresh_cache()
    teams.refresh_cache()
    notify.info("All caches refreshed")
  end
end

function M.cache_status()
  local status = cache.get_status()
  print("Cache Status:")
  print("-------------")
  for cache_type, info in pairs(status) do
    local state
    if not info.exists then
      state = "not cached"
    elseif info.expired then
      state = "expired"
    else
      state = "valid"
    end
    local age_str
    if info.age then
      age_str = string.format("%d seconds ago", info.age)
    else
      age_str = "never"
    end
    print(string.format("  %s: %s (%s)", cache_type, state, age_str))
  end
end

function M.list_presets()
  local presets = config.get_presets()
  local default = config.get_default_preset()
  local has_presets = false
  for _ in pairs(presets) do
    has_presets = true
    break
  end
  if not has_presets then
    notify.info("No presets configured")
    return
  end
  print("Configured Presets:")
  print("-------------------")
  for name, preset in pairs(presets) do
    local is_default = name == default
    local marker = is_default and " (default)" or ""
    print(string.format("  %s%s", name, marker))
    if preset.query then
      print(string.format("    query: %s", preset.query))
    end
    if preset.description then
      print(string.format("    desc: %s", preset.description))
    end
  end
end

return M
