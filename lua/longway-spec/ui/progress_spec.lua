-- [nfnl] fnl/longway-spec/ui/progress_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local progress = require("longway.ui.progress")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(progress.start)
    end
    it("exports start function", _4_)
    local function _5_()
      return assert.is_function(progress.update)
    end
    it("exports update function", _5_)
    local function _6_()
      return assert.is_function(progress.finish)
    end
    it("exports finish function", _6_)
    local function _7_()
      local is_available = progress["is-available"]
      return assert.is_function(is_available)
    end
    return it("exports is-available function", _7_)
  end
  describe("module structure", _3_)
  local function _8_()
    local function _9_()
      local id = progress.start("Syncing", 10)
      assert.is_string(id)
      return assert.has_substring(id, "longway_progress_")
    end
    it("returns a progress ID string", _9_)
    local function _10_()
      local id = progress.start("Pushing", 5)
      return assert.has_substring(id, "Pushing")
    end
    return it("includes operation name in progress ID", _10_)
  end
  describe("start", _8_)
  local function _11_()
    local function _12_()
      local id = progress.start("Syncing", 10)
      progress.update(id, 1, 10, "Test item")
      return assert.is_true(true)
    end
    it("does not error with valid arguments", _12_)
    local function _13_()
      local id = progress.start("Syncing", 10)
      progress.update(id, 1, 10, nil)
      return assert.is_true(true)
    end
    it("does not error without item name", _13_)
    local function _14_()
      progress.update("unknown_id", 1, 10, "Test")
      return assert.is_true(true)
    end
    return it("does not error with unknown progress ID", _14_)
  end
  describe("update", _11_)
  local function _15_()
    local function _16_()
      local id = progress.start("Syncing", 10)
      progress.finish(id, 8, 2)
      return assert.is_true(true)
    end
    it("does not error with valid arguments", _16_)
    local function _17_()
      local id = progress.start("Syncing", 5)
      progress.finish(id, 5, 0)
      return assert.is_true(true)
    end
    it("does not error with zero failed", _17_)
    local function _18_()
      local id = progress.start("Syncing", 5)
      progress.finish(id, 5, nil)
      return assert.is_true(true)
    end
    return it("does not error with nil failed", _18_)
  end
  describe("finish", _15_)
  local function _19_()
    local function _20_()
      local is_available = progress["is-available"]
      local result = is_available()
      return assert.is_boolean(result)
    end
    return it("returns a boolean", _20_)
  end
  describe("is-available", _19_)
  local function _21_()
    local function _22_()
      t["setup-test-config"]({progress = false})
      local id = progress.start("Syncing", 10)
      progress.update(id, 1, 10, "Test")
      return assert.is_true(true)
    end
    return it("update respects config.progress = false", _22_)
  end
  return describe("progress suppression", _21_)
end
return describe("longway.ui.progress", _1_)
