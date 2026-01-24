-- [nfnl] fnl/longway/config.fnl
local M = {}
local default_config = {token = nil, token_file = nil, workspace_dir = vim.fn.expand("~/shortcut"), stories_subdir = "stories", epics_subdir = "epics", filename_template = "{id}-{slug}", slug_max_length = 50, slug_separator = "-", sync_start_marker = "<!-- BEGIN SHORTCUT SYNC:{section} -->", sync_end_marker = "<!-- END SHORTCUT SYNC:{section} -->", sync_sections = {description = true, tasks = true, comments = true}, tasks = {show_owners = true, confirm_delete = true, auto_assign_on_complete = false}, comments = {max_pull = 50, show_timestamps = true, timestamp_format = "%Y-%m-%d %H:%M", confirm_delete = true}, auto_push_delay = 2000, conflict_strategy = "prompt", presets = {}, default_preset = nil, rate_limit = {requests_per_minute = 180, retry_delay_base = 1000, max_retries = 3}, notify = true, notify_level = vim.log.levels.INFO, progress = true, picker = {layout = "default", preview = true, icons = true}, log_file = nil, auto_push_on_save = false, confirm_push = false, debug = false, pull_on_open = false}
local config = vim.deepcopy(default_config)
local function read_token_file(path)
  local expanded = vim.fn.expand(path)
  local exists = (vim.fn.filereadable(expanded) == 1)
  if exists then
    local lines = vim.fn.readfile(expanded)
    if (#lines > 0) then
      return string.gsub(lines[1], "%s+", "")
    else
      return nil
    end
  else
    return nil
  end
end
local function resolve_token(opts)
  local or_3_ = opts.token
  if not or_3_ then
    if opts.token_file then
      or_3_ = read_token_file(opts.token_file)
    else
      or_3_ = nil
    end
  end
  return (or_3_ or os.getenv("SHORTCUT_API_TOKEN") or read_token_file("~/.config/longway/token"))
end
local function validate_config(cfg)
  local errors = {}
  if not cfg._resolved_token then
    table.insert(errors, "No API token found. Set SHORTCUT_API_TOKEN env var, token in config, or create ~/.config/longway/token")
  else
  end
  if (not cfg.workspace_dir or (cfg.workspace_dir == "")) then
    table.insert(errors, "workspace_dir must be set")
  else
  end
  if (#errors == 0) then
    return {true, nil}
  else
    return {false, errors}
  end
end
M.setup = function(opts)
  local opts0 = (opts or {})
  local merged = vim.tbl_deep_extend("force", default_config, opts0)
  local token = resolve_token(opts0)
  merged._resolved_token = token
  config = merged
  if config.debug then
    local _let_8_ = validate_config(config)
    local ok = _let_8_[1]
    local errors = _let_8_[2]
    if not ok then
      for _, err in ipairs(errors) do
        vim.notify(("[longway] Config warning: " .. err), vim.log.levels.WARN)
      end
    else
    end
  else
  end
  return config
end
M.get = function()
  return config
end
M["get-token"] = function()
  return config._resolved_token
end
M["get-workspace-dir"] = function()
  return vim.fn.expand(config.workspace_dir)
end
M["get-stories-dir"] = function()
  return (M["get-workspace-dir"]() .. "/" .. config.stories_subdir)
end
M["get-epics-dir"] = function()
  return (M["get-workspace-dir"]() .. "/" .. config.epics_subdir)
end
M.validate = function()
  return validate_config(config)
end
M["is-configured"] = function()
  return not not config._resolved_token
end
M["get-preset"] = function(name)
  if (config.presets and name) then
    return config.presets[name]
  else
    return nil
  end
end
M["get-presets"] = function()
  return (config.presets or {})
end
M["get-default-preset"] = function()
  return config.default_preset
end
M["get-cache-dir"] = function()
  return (M["get-workspace-dir"]() .. "/.longway/cache")
end
M["get-state-dir"] = function()
  return (M["get-workspace-dir"]() .. "/.longway/state")
end
return M
