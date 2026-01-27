-- [nfnl] fnl/longway-spec/ui/statusline_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local statusline = require("longway.ui.statusline")
local function _1_()
  local function _2_()
    t["setup-test-config"]({})
    return statusline.teardown()
  end
  before_each(_2_)
  local function _3_()
    return statusline.teardown()
  end
  after_each(_3_)
  local function _4_()
    local function _5_()
      local is_longway_buffer = statusline["is-longway-buffer"]
      return assert.is_function(is_longway_buffer)
    end
    it("exports is-longway-buffer function", _5_)
    local function _6_()
      local get_status = statusline["get-status"]
      return assert.is_function(get_status)
    end
    it("exports get-status function", _6_)
    local function _7_()
      local get_status_data = statusline["get-status-data"]
      return assert.is_function(get_status_data)
    end
    it("exports get-status-data function", _7_)
    local function _8_()
      local lualine_component = statusline["lualine-component"]
      return assert.is_function(lualine_component)
    end
    it("exports lualine-component function", _8_)
    local function _9_()
      return assert.is_function(statusline.setup)
    end
    it("exports setup function", _9_)
    local function _10_()
      return assert.is_function(statusline.teardown)
    end
    return it("exports teardown function", _10_)
  end
  describe("module structure", _4_)
  local function _11_()
    local function _12_()
      local is_longway_buffer = statusline["is-longway-buffer"]
      return assert.is_false(is_longway_buffer())
    end
    return it("returns false for a non-longway buffer", _12_)
  end
  describe("is-longway-buffer", _11_)
  local function _13_()
    local function _14_()
      local get_status = statusline["get-status"]
      return assert.is_nil(get_status())
    end
    return it("returns nil for non-longway buffer", _14_)
  end
  describe("get-status", _13_)
  local function _15_()
    local function _16_()
      local get_status_data = statusline["get-status-data"]
      return assert.is_nil(get_status_data())
    end
    return it("returns nil for non-longway buffer", _16_)
  end
  describe("get-status-data", _15_)
  local function _17_()
    local function _18_()
      local lualine_component = statusline["lualine-component"]
      local component = lualine_component()
      assert.is_table(component)
      assert.is_function(component[1])
      assert.is_function(component.cond)
      return assert.is_function(component.color)
    end
    return it("returns a table with expected fields", _18_)
  end
  describe("lualine-component", _17_)
  local function _19_()
    local function _20_()
      statusline.setup()
      local autocmds = vim.api.nvim_get_autocmds({group = "longway_statusline"})
      return assert.is_true((#autocmds >= 1))
    end
    it("creates augroup", _20_)
    local function _21_()
      statusline.setup()
      local enter_cmds = vim.api.nvim_get_autocmds({group = "longway_statusline", event = "BufEnter"})
      local write_cmds = vim.api.nvim_get_autocmds({group = "longway_statusline", event = "BufWritePost"})
      assert.equals(1, #enter_cmds)
      return assert.equals(1, #write_cmds)
    end
    it("registers BufEnter and BufWritePost autocmds", _21_)
    local function _22_()
      statusline.setup()
      statusline.setup()
      local autocmds = vim.api.nvim_get_autocmds({group = "longway_statusline"})
      return assert.equals(2, #autocmds)
    end
    return it("is idempotent", _22_)
  end
  describe("setup", _19_)
  local function _23_()
    local function _24_()
      statusline.setup()
      statusline.teardown()
      local ok, _ = pcall(vim.api.nvim_get_autocmds, {group = "longway_statusline"})
      return assert.is_false(ok)
    end
    it("removes augroup", _24_)
    local function _25_()
      statusline.teardown()
      return assert.is_true(true)
    end
    return it("is safe to call when not set up", _25_)
  end
  return describe("teardown", _23_)
end
return describe("longway.ui.statusline", _1_)
