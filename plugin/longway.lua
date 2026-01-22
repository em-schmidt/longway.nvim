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
end, {
  desc = 'Show longway.nvim plugin info',
})

-- Legacy hello command for testing
vim.api.nvim_create_user_command('LongwayHello', function()
  require('longway').hello()
end, {
  desc = 'Test longway.nvim plugin',
})
