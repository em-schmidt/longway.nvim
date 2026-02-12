-- [nfnl] fnl/longway-spec/api/epics_spec.fnl
local t = require("longway-spec.init")
local epics = require("longway.api.epics")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(epics.get)
    end
    return it("is a function", _4_)
  end
  describe("get", _3_)
  local function _5_()
    local function _6_()
      return assert.is_function(epics.list)
    end
    return it("is a function", _6_)
  end
  describe("list", _5_)
  local function _7_()
    local function _8_()
      return assert.is_function(epics.update)
    end
    return it("is a function", _8_)
  end
  describe("update", _7_)
  local function _9_()
    local function _10_()
      return assert.is_function(epics.create)
    end
    return it("is a function", _10_)
  end
  describe("create", _9_)
  local function _11_()
    local function _12_()
      return assert.is_function(epics.delete)
    end
    return it("is a function", _12_)
  end
  describe("delete", _11_)
  local function _13_()
    local function _14_()
      return assert.is_function(epics["list-stories"])
    end
    return it("is a function", _14_)
  end
  describe("list-stories", _13_)
  local function _15_()
    local function _16_()
      return assert.is_function(epics["get-with-stories"])
    end
    return it("is a function", _16_)
  end
  describe("get-with-stories", _15_)
  local function _17_()
    local function _18_()
      return assert.is_function(epics["get-stats"])
    end
    it("is a function", _18_)
    local function _19_()
      local epic = {stats = {num_stories_total = 10, num_stories_started = 3, num_stories_done = 5, num_stories_unstarted = 2, num_points = 20, num_points_done = 10}}
      local get_stats = epics["get-stats"]
      local stats = get_stats(epic)
      assert.equals(10, stats.total)
      assert.equals(5, stats.done)
      assert.equals(3, stats.started)
      return assert.equals(2, stats.unstarted)
    end
    return it("calculates stats from epic data", _19_)
  end
  describe("get-stats", _17_)
  local function _20_()
    local function _21_()
      return assert.is_function(epics["get-progress"])
    end
    it("is a function", _21_)
    local function _22_()
      local epic = {stats = {num_stories_total = 10, num_stories_done = 5}}
      local get_progress = epics["get-progress"]
      local progress = get_progress(epic)
      return assert.equals(50, progress)
    end
    it("calculates percentage progress", _22_)
    local function _23_()
      local epic = {stats = {num_stories_total = 0, num_stories_done = 0}}
      local get_progress = epics["get-progress"]
      local progress = get_progress(epic)
      return assert.equals(0, progress)
    end
    return it("returns 0 for empty epic", _23_)
  end
  return describe("get-progress", _20_)
end
return describe("longway.api.epics", _1_)
