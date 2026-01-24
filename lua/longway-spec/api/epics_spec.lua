-- Tests for longway.api.epics
local t = require("longway-spec.init")
local epics = require("longway.api.epics")

local function _1_()
  before_each(function() t.setup_test_config({}) end)

  describe("get", function()
    it("is a function", function()
      assert.is_function(epics.get)
    end)
  end)

  describe("list", function()
    it("is a function", function()
      assert.is_function(epics.list)
    end)
  end)

  describe("update", function()
    it("is a function", function()
      assert.is_function(epics.update)
    end)
  end)

  describe("create", function()
    it("is a function", function()
      assert.is_function(epics.create)
    end)
  end)

  describe("delete", function()
    it("is a function", function()
      assert.is_function(epics.delete)
    end)
  end)

  describe("list_stories", function()
    it("is a function", function()
      assert.is_function(epics.list_stories)
    end)
  end)

  describe("get_with_stories", function()
    it("is a function", function()
      assert.is_function(epics.get_with_stories)
    end)
  end)

  describe("get_stats", function()
    it("is a function", function()
      assert.is_function(epics.get_stats)
    end)
    it("calculates stats from epic data", function()
      local epic = {
        stats = {
          num_stories = 10,
          num_stories_started = 3,
          num_stories_done = 5,
          num_stories_unstarted = 2,
          num_points = 20,
          num_points_done = 10
        }
      }
      local stats = epics.get_stats(epic)
      assert.equals(10, stats.total)
      assert.equals(5, stats.done)
      assert.equals(3, stats.started)
      assert.equals(2, stats.unstarted)
    end)
  end)

  describe("get_progress", function()
    it("is a function", function()
      assert.is_function(epics.get_progress)
    end)
    it("calculates percentage progress", function()
      local epic = { stats = { num_stories = 10, num_stories_done = 5 } }
      local progress = epics.get_progress(epic)
      assert.equals(50, progress)
    end)
    it("returns 0 for empty epic", function()
      local epic = { stats = { num_stories = 0, num_stories_done = 0 } }
      local progress = epics.get_progress(epic)
      assert.equals(0, progress)
    end)
  end)
end

return describe("longway.api.epics", _1_)
