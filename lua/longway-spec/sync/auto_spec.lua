-- [nfnl] fnl/longway-spec/sync/auto_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local auto = require("longway.sync.auto")
local function _1_()
  local function _2_()
    t["setup-test-config"]({})
    return auto.teardown()
  end
  before_each(_2_)
  local function _3_()
    return auto.teardown()
  end
  after_each(_3_)
  local function _4_()
    local function _5_()
      local is_active = auto["is-active"]
      return assert.is_false(is_active())
    end
    it("returns false when not set up", _5_)
    local function _6_()
      local is_active = auto["is-active"]
      auto.setup()
      return assert.is_true(is_active())
    end
    it("returns true after setup", _6_)
    local function _7_()
      local is_active = auto["is-active"]
      auto.setup()
      auto.teardown()
      return assert.is_false(is_active())
    end
    return it("returns false after teardown", _7_)
  end
  describe("is-active", _4_)
  local function _8_()
    local function _9_()
      auto.setup()
      local autocmds = vim.api.nvim_get_autocmds({group = "longway_auto_push"})
      return assert.is_true((#autocmds >= 1))
    end
    it("creates augroup", _9_)
    local function _10_()
      auto.setup()
      local autocmds = vim.api.nvim_get_autocmds({group = "longway_auto_push", event = "BufWritePost"})
      assert.equals(1, #autocmds)
      return assert.equals("*.md", autocmds[1].pattern)
    end
    it("registers BufWritePost autocmd for markdown files", _10_)
    local function _11_()
      auto.setup()
      auto.setup()
      local autocmds = vim.api.nvim_get_autocmds({group = "longway_auto_push"})
      return assert.equals(1, #autocmds)
    end
    return it("clears previous setup on re-setup", _11_)
  end
  describe("setup", _8_)
  local function _12_()
    local function _13_()
      auto.setup()
      auto.teardown()
      local ok, _ = pcall(vim.api.nvim_get_autocmds, {group = "longway_auto_push"})
      return assert.is_false(ok)
    end
    it("removes augroup", _13_)
    local function _14_()
      auto.teardown()
      return assert.is_true(true)
    end
    return it("is safe to call when not set up", _14_)
  end
  return describe("teardown", _12_)
end
return describe("longway.sync.auto", _1_)
