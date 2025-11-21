-- Entry point for longway.nvim
-- This file is automatically loaded by Neovim

-- Create a user command for quick testing
vim.api.nvim_create_user_command('LongwayHello', function()
  require('longway').hello()
end, { desc = 'Test longway.nvim plugin' })

vim.api.nvim_create_user_command('LongwayInfo', function()
  local info = require('longway').get_info()
  print(vim.inspect(info))
end, { desc = 'Show longway.nvim info' })
