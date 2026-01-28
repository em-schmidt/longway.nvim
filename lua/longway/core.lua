-- [nfnl] fnl/longway/core.fnl
local config = require("longway.config")
local pull = require("longway.sync.pull")
local push = require("longway.sync.push")
local notify = require("longway.ui.notify")
local cache = require("longway.cache.store")
local M = {}
M["get-info"] = function()
  local cfg = config.get()
  return {name = "longway.nvim", version = "0.6.0", author = "Eric Schmidt", configured = config["is-configured"](), workspace_dir = config["get-workspace-dir"](), presets = config["get-presets"](), debug = cfg.debug}
end
M.pull = function(story_id)
  if not config["is-configured"]() then
    return notify["no-token"]()
  else
    return pull["pull-story-to-buffer"](story_id)
  end
end
M.push = function()
  if not config["is-configured"]() then
    return notify["no-token"]()
  else
    return push["push-current-buffer"]()
  end
end
M.refresh = function()
  if not config["is-configured"]() then
    return notify["no-token"]()
  else
    return pull["refresh-current-buffer"]()
  end
end
M["open-in-browser"] = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local parser = require("longway.markdown.parser")
  local parsed = parser.parse(content)
  local url = parsed.frontmatter.shortcut_url
  if url then
    vim.ui.open(url)
    return notify.info(string.format("Opening %s", url))
  else
    return notify.error("No shortcut_url found in frontmatter")
  end
end
local function print_task_status(parsed, fm)
  local local_tasks = (parsed.tasks or {})
  local local_count = #local_tasks
  local complete_count
  do
    local n = 0
    for _, task in ipairs(local_tasks) do
      if task.complete then
        n = (n + 1)
      else
        n = n
      end
    end
    complete_count = n
  end
  local new_count
  do
    local n = 0
    for _, task in ipairs(local_tasks) do
      if task.is_new then
        n = (n + 1)
      else
        n = n
      end
    end
    new_count = n
  end
  local tasks_hash_stored = (fm.tasks_hash or "")
  print(string.format("Tasks: %d local (%d complete, %d new)", local_count, complete_count, new_count))
  if (#tasks_hash_stored > 0) then
    local hash_mod = require("longway.util.hash")
    local current_hash = hash_mod["tasks-hash"](local_tasks)
    local changed = (tasks_hash_stored ~= current_hash)
    local function _7_()
      if changed then
        return " (changed)"
      else
        return " (synced)"
      end
    end
    return print(string.format("Tasks hash: %s%s", tasks_hash_stored, _7_()))
  else
    return nil
  end
end
local function print_comment_status(parsed, fm)
  local local_comments = (parsed.comments or {})
  local local_count = #local_comments
  local new_count
  do
    local n = 0
    for _, cmt in ipairs(local_comments) do
      if cmt.is_new then
        n = (n + 1)
      else
        n = n
      end
    end
    new_count = n
  end
  local comments_hash_stored = (fm.comments_hash or "")
  print(string.format("Comments: %d local (%d new)", local_count, new_count))
  if (#comments_hash_stored > 0) then
    local hash_mod = require("longway.util.hash")
    local current_hash = hash_mod["comments-hash"](local_comments)
    local changed = (comments_hash_stored ~= current_hash)
    local function _10_()
      if changed then
        return " (changed)"
      else
        return " (synced)"
      end
    end
    return print(string.format("Comments hash: %s%s", comments_hash_stored, _10_()))
  else
    return nil
  end
end
local function print_description_status(parsed, fm)
  local sync_hash_stored = (fm.sync_hash or "")
  if (#sync_hash_stored > 0) then
    local hash_mod = require("longway.util.hash")
    local content_hash = hash_mod["content-hash"]
    local current_hash = content_hash((parsed.description or ""))
    local changed = (sync_hash_stored ~= current_hash)
    local function _12_()
      if changed then
        return "changed"
      else
        return "synced"
      end
    end
    return print(string.format("Description: %s", _12_()))
  else
    return nil
  end
end
local function print_conflict_status(fm)
  if fm.conflict_sections then
    local sections
    if (type(fm.conflict_sections) == "table") then
      sections = table.concat(fm.conflict_sections, ", ")
    else
      sections = tostring(fm.conflict_sections)
    end
    print(string.format("CONFLICT in: %s", sections))
    return print("  Resolve with: :LongwayResolve <local|remote|manual>")
  else
    return nil
  end
end
M.status = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if (filepath == "") then
    return notify.error("No file in current buffer")
  else
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local content = table.concat(lines, "\n")
    local parser = require("longway.markdown.parser")
    local parsed = parser.parse(content)
    local fm = parsed.frontmatter
    if not fm.shortcut_id then
      return notify.info("Not a longway-managed file")
    else
      print(string.format("Shortcut ID: %s", tostring(fm.shortcut_id)))
      print(string.format("Type: %s", (fm.shortcut_type or "story")))
      print(string.format("State: %s", (fm.state or "unknown")))
      if fm.shortcut_url then
        print(string.format("URL: %s", fm.shortcut_url))
      else
      end
      if fm.updated_at then
        print(string.format("Last updated: %s", fm.updated_at))
      else
      end
      if fm.local_updated_at then
        print(string.format("Local updated: %s", fm.local_updated_at))
      else
      end
      print_description_status(parsed, fm)
      print_task_status(parsed, fm)
      print_comment_status(parsed, fm)
      return print_conflict_status(fm)
    end
  end
end
M["pull-epic"] = function(epic_id)
  if not config["is-configured"]() then
    return notify["no-token"]()
  else
    return pull["pull-epic-to-buffer"](epic_id)
  end
end
M.sync = function(query_or_preset)
  if not config["is-configured"]() then
    return notify["no-token"]()
  else
    if not query_or_preset then
      local default_preset = config["get-default-preset"]()
      if default_preset then
        return pull["sync-preset"](default_preset)
      else
        notify.error("No query or preset specified")
        return {error = "No query or preset specified", ok = false}
      end
    else
      if string.find(query_or_preset, ":") then
        return pull["sync-stories"](query_or_preset)
      else
        local preset = config["get-preset"](query_or_preset)
        if preset then
          return pull["sync-preset"](query_or_preset)
        else
          return pull["sync-stories"](query_or_preset)
        end
      end
    end
  end
end
M["sync-all"] = function()
  if not config["is-configured"]() then
    return notify["no-token"]()
  else
    return pull["sync-all-presets"]()
  end
end
M["cache-refresh"] = function(cache_type)
  if not config["is-configured"]() then
    return notify["no-token"]()
  else
    if cache_type then
      local api_module
      if (cache_type == "members") then
        api_module = require("longway.api.members")
      elseif (cache_type == "workflows") then
        api_module = require("longway.api.workflows")
      elseif (cache_type == "iterations") then
        api_module = require("longway.api.iterations")
      elseif (cache_type == "teams") then
        api_module = require("longway.api.teams")
      else
        local _ = cache_type
        api_module = nil
      end
      if api_module then
        notify.info(string.format("Refreshing %s cache...", cache_type))
        local result = api_module["refresh-cache"]()
        if result.ok then
          return notify.info(string.format("%s cache refreshed", cache_type))
        else
          return notify.error(string.format("Failed to refresh %s cache: %s", cache_type, (result.error or "unknown")))
        end
      else
        return notify.error(string.format("Unknown cache type: %s", cache_type))
      end
    else
      notify.info("Refreshing all caches...")
      local members = require("longway.api.members")
      local workflows = require("longway.api.workflows")
      local iterations = require("longway.api.iterations")
      local teams = require("longway.api.teams")
      members["refresh-cache"]()
      workflows["refresh-cache"]()
      iterations["refresh-cache"]()
      teams["refresh-cache"]()
      return notify.info("All caches refreshed")
    end
  end
end
M["cache-status"] = function()
  local status = cache["get-status"]()
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
  return nil
end
M["list-presets"] = function()
  local presets = config["get-presets"]()
  local default = config["get-default-preset"]()
  if (next(presets) == nil) then
    return notify.info("No presets configured")
  else
    print("Configured Presets:")
    print("-------------------")
    for name, preset in pairs(presets) do
      local is_default = (name == default)
      local marker
      if is_default then
        marker = " (default)"
      else
        marker = ""
      end
      print(string.format("  %s%s", name, marker))
      if preset.query then
        print(string.format("    query: %s", preset.query))
      else
      end
      if preset.description then
        print(string.format("    desc: %s", preset.description))
      else
      end
    end
    return nil
  end
end
M.resolve = function(strategy)
  if not config["is-configured"]() then
    return notify["no-token"]()
  else
    local resolve_mod = require("longway.sync.resolve")
    return resolve_mod.resolve(strategy, {})
  end
end
M.picker = function(source, opts)
  if not config["is-configured"]() then
    return notify["no-token"]()
  else
    local picker = require("longway.ui.picker")
    if not picker["check-snacks"]() then
      return nil
    else
      if (source == "stories") then
        return picker["pick-stories"]((opts or {}))
      elseif (source == "epics") then
        return picker["pick-epics"]((opts or {}))
      elseif (source == "presets") then
        return picker["pick-presets"]()
      elseif (source == "modified") then
        return picker["pick-modified"]((opts or {}))
      elseif (source == "comments") then
        return picker["pick-comments"]((opts or {}))
      else
        local _ = source
        return notify.error(string.format("Unknown picker source: %s", tostring(source)))
      end
    end
  end
end
return M
