-- Entry point for longway.nvim
-- This file is automatically loaded by Neovim

-- Prevent loading twice
if vim.g.loaded_longway then
  return
end
vim.g.loaded_longway = true

-- Create user commands

-- Pull a story by ID
vim.api.nvim_create_user_command('LongwayPull', function(opts)
  local story_id = opts.args
  if story_id == '' then
    vim.notify('[longway] Usage: :LongwayPull <story_id>', vim.log.levels.ERROR)
    return
  end
  require('longway').pull(tonumber(story_id) or story_id)
end, {
  nargs = 1,
  desc = 'Pull a story from Shortcut by ID',
})

-- Push current buffer to Shortcut
vim.api.nvim_create_user_command('LongwayPush', function()
  require('longway').push()
end, {
  desc = 'Push current buffer to Shortcut',
})

-- Refresh current buffer from Shortcut
vim.api.nvim_create_user_command('LongwayRefresh', function()
  require('longway').refresh()
end, {
  desc = 'Refresh current buffer from Shortcut',
})

-- Open current story in browser
vim.api.nvim_create_user_command('LongwayOpen', function()
  require('longway').open()
end, {
  desc = 'Open current story in browser',
})

-- Show sync status of current file
vim.api.nvim_create_user_command('LongwayStatus', function()
  require('longway').status()
end, {
  desc = 'Show sync status of current file',
})

-- Show plugin info
vim.api.nvim_create_user_command('LongwayInfo', function()
  local info = require('longway').get_info()
  print('longway.nvim v' .. info.version)
  print('  Configured: ' .. tostring(info.configured))
  print('  Workspace: ' .. info.workspace_dir)
  print('  Debug: ' .. tostring(info.debug))
  local presets = info.presets or {}
  local preset_count = 0
  for _ in pairs(presets) do preset_count = preset_count + 1 end
  print('  Presets: ' .. preset_count)
end, {
  desc = 'Show longway.nvim plugin info',
})

-- Phase 2: Epic pull
vim.api.nvim_create_user_command('LongwayPullEpic', function(opts)
  local epic_id = opts.args
  if epic_id == '' then
    vim.notify('[longway] Usage: :LongwayPullEpic <epic_id>', vim.log.levels.ERROR)
    return
  end
  require('longway').pull_epic(tonumber(epic_id) or epic_id)
end, {
  nargs = 1,
  desc = 'Pull an epic from Shortcut by ID',
})

-- Phase 2: Sync command (query or preset)
vim.api.nvim_create_user_command('LongwaySync', function(opts)
  local arg = opts.args
  if arg == '' then
    require('longway').sync()
  else
    require('longway').sync(arg)
  end
end, {
  nargs = '?',
  desc = 'Sync stories by query (owner:me state:started) or preset name',
})

-- Phase 2: Sync all presets
vim.api.nvim_create_user_command('LongwaySyncAll', function()
  require('longway').sync_all()
end, {
  desc = 'Sync all configured presets',
})

-- Phase 2: Cache management
vim.api.nvim_create_user_command('LongwayCacheRefresh', function(opts)
  local cache_type = opts.args
  if cache_type == '' then
    require('longway').cache_refresh()
  else
    require('longway').cache_refresh(cache_type)
  end
end, {
  nargs = '?',
  complete = function()
    return { 'members', 'workflows', 'iterations', 'teams' }
  end,
  desc = 'Refresh cache (members, workflows, iterations, teams, or all)',
})

vim.api.nvim_create_user_command('LongwayCacheStatus', function()
  require('longway').cache_status()
end, {
  desc = 'Show status of all caches',
})

-- Phase 2: List presets
vim.api.nvim_create_user_command('LongwayPresets', function()
  require('longway').list_presets()
end, {
  desc = 'List configured presets',
})

-- Phase 5: Resolve sync conflicts
vim.api.nvim_create_user_command('LongwayResolve', function(opts)
  local strategy = opts.args
  if strategy == '' then
    vim.notify('[longway] Usage: :LongwayResolve <local|remote|manual>', vim.log.levels.ERROR)
    return
  end
  require('longway').resolve(strategy)
end, {
  nargs = 1,
  complete = function()
    return { 'local', 'remote', 'manual' }
  end,
  desc = 'Resolve sync conflict (local, remote, or manual)',
})

-- Phase 6: Picker command
vim.api.nvim_create_user_command('LongwayPicker', function(opts)
  local source = opts.args
  if source == '' then
    vim.notify('[longway] Usage: :LongwayPicker <stories|epics|presets|modified|comments>', vim.log.levels.ERROR)
    return
  end
  require('longway').picker(source)
end, {
  nargs = 1,
  complete = function()
    return { 'stories', 'epics', 'presets', 'modified', 'comments' }
  end,
  desc = 'Open Snacks picker (stories, epics, presets, modified, comments)',
})

