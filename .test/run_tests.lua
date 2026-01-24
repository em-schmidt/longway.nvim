-- Test runner script for CI
-- Runs all tests and exits Neovim with appropriate exit code

-- When run with nvim -l, we need to set up the environment
vim.opt.runtimepath:prepend(".")
vim.opt.runtimepath:prepend(".test/nvim/pack/test/start/plenary.nvim")
vim.opt.runtimepath:prepend(".test/nvim/pack/test/start/nfnl")

vim.opt.swapfile = false
vim.g.longway_test_mode = true

-- Load plenary
local ok, _ = pcall(require, "plenary")
if not ok then
  print("ERROR: Could not load plenary.nvim")
  print("Run ./scripts/setup-test-deps first")
  os.exit(1)
end

print("Running tests from lua/longway-spec...")
print("")

-- Use vim.wait to run the event loop while tests execute
local harness = require("plenary.test_harness")

-- Track completion
local completed = false
local exit_code = 0

-- Override the test complete function to capture results
local original_test_directory = harness.test_directory
harness.test_directory = function(path, opts)
  opts = opts or {}
  local original_on_complete = opts.on_complete
  opts.on_complete = function(results)
    if original_on_complete then
      original_on_complete(results)
    end
    completed = true
    -- Check for failures
    if results and results.fail and results.fail > 0 then
      exit_code = 1
    end
  end
  return original_test_directory(path, opts)
end

-- Start the tests
harness.test_directory("lua/longway-spec", {
  minimal_init = vim.fn.getcwd() .. "/.test/init.lua",
  sequential = true,
})

-- Wait for tests to complete (max 5 minutes)
local timeout_ms = 300000
local waited = vim.wait(timeout_ms, function()
  return completed
end, 100)

if not waited then
  print("")
  print("ERROR: Test timeout exceeded (" .. (timeout_ms / 1000) .. " seconds)")
  os.exit(1)
end

print("")
if exit_code == 0 then
  print("All tests passed!")
else
  print("Some tests failed!")
end

os.exit(exit_code)
