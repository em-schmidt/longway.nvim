-- Minimal init for testing
-- This file sets up the Neovim environment for running tests

-- Add pack directory to packpath so plugins load automatically
vim.opt.packpath:prepend(".test/nvim")

-- Add plugin paths to runtimepath
vim.opt.runtimepath:prepend(".")
vim.opt.runtimepath:prepend(".test/nvim/pack/test/start/plenary.nvim")
vim.opt.runtimepath:prepend(".test/nvim/pack/test/start/nfnl")

-- Disable swap files for testing
vim.opt.swapfile = false

-- Set up a mock config for testing (no real API token needed)
vim.g.longway_test_mode = true

-- Load plenary
local ok, _ = pcall(require, "plenary")
if not ok then
    print("ERROR: Could not load plenary.nvim")
    print("Run ./scripts/setup-test-deps first")
    vim.cmd("cq 1")
end

-- Ensure nfnl plugin files are sourced (registers commands)
vim.cmd("runtime! plugin/**/*.lua")
