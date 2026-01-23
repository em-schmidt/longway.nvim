-- Configuration module for longway.nvim
-- Compiled from fnl/longway/config.fnl

local M = {}

-- Default configuration
local default_config = {
  -- Authentication
  token = nil,
  token_file = nil,

  -- Workspace
  workspace_dir = vim.fn.expand("~/shortcut"),
  stories_subdir = "stories",
  epics_subdir = "epics",

  -- File format
  filename_template = "{id}-{slug}",
  slug_max_length = 50,
  slug_separator = "-",

  -- Sync markers
  sync_start_marker = "<!-- BEGIN SHORTCUT SYNC:{section} -->",
  sync_end_marker = "<!-- END SHORTCUT SYNC:{section} -->",

  -- Section sync toggles
  sync_sections = {
    description = true,
    tasks = true,
    comments = true,
  },

  -- Task sync options
  tasks = {
    show_owners = true,
    confirm_delete = true,
    auto_assign_on_complete = false,
  },

  -- Comment sync options
  comments = {
    max_pull = 50,
    show_timestamps = true,
    timestamp_format = "%Y-%m-%d %H:%M",
    confirm_delete = true,
  },

  -- Sync behavior
  auto_push_on_save = false,
  auto_push_delay = 2000,
  confirm_push = false,
  pull_on_open = false,

  -- Conflict handling
  conflict_strategy = "prompt",

  -- Filter presets
  presets = {},
  default_preset = nil,

  -- Rate limiting
  rate_limit = {
    requests_per_minute = 180,
    retry_delay_base = 1000,
    max_retries = 3,
  },

  -- UI
  notify = true,
  notify_level = vim.log.levels.INFO,
  progress = true,

  -- Snacks picker
  picker = {
    layout = "default",
    preview = true,
    icons = true,
  },

  -- Debug
  debug = false,
  log_file = nil,
}

-- Current configuration state (initialized with defaults so plugin works without setup())
local config = vim.deepcopy(default_config)

local function read_token_file(path)
  local expanded = vim.fn.expand(path)
  local exists = vim.fn.filereadable(expanded) == 1
  if exists then
    local lines = vim.fn.readfile(expanded)
    if #lines > 0 then
      return (lines[1]:gsub("%s+", ""))
    end
  end
  return nil
end

local function resolve_token(opts)
  return opts.token
    or (opts.token_file and read_token_file(opts.token_file))
    or os.getenv("SHORTCUT_API_TOKEN")
    or read_token_file("~/.config/longway/token")
end

local function validate_config(cfg)
  local errors = {}

  if not cfg._resolved_token then
    table.insert(errors, "No API token found. Set SHORTCUT_API_TOKEN env var, token in config, or create ~/.config/longway/token")
  end

  if not cfg.workspace_dir or cfg.workspace_dir == "" then
    table.insert(errors, "workspace_dir must be set")
  end

  if #errors == 0 then
    return true, nil
  else
    return false, errors
  end
end

function M.setup(opts)
  opts = opts or {}
  local merged = vim.tbl_deep_extend("force", default_config, opts)
  local token = resolve_token(opts)

  merged._resolved_token = token
  config = merged

  if config.debug then
    local ok, errors = validate_config(config)
    if not ok then
      for _, err in ipairs(errors) do
        vim.notify("[longway] Config warning: " .. err, vim.log.levels.WARN)
      end
    end
  end

  return config
end

function M.get()
  return config
end

function M.get_token()
  return config._resolved_token
end

function M.get_workspace_dir()
  return vim.fn.expand(config.workspace_dir)
end

function M.get_stories_dir()
  return M.get_workspace_dir() .. "/" .. config.stories_subdir
end

function M.get_epics_dir()
  return M.get_workspace_dir() .. "/" .. config.epics_subdir
end

function M.validate()
  return validate_config(config)
end

function M.is_configured()
  return config._resolved_token ~= nil
end

return M
