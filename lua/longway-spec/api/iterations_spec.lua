-- Tests for longway.api.iterations
local t = require("longway-spec.init")
local iterations = require("longway.api.iterations")

local function _1_()
  before_each(function() t.setup_test_config({}) end)

  describe("list", function()
    it("is a function", function()
      assert.is_function(iterations.list)
    end)
  end)

  describe("get", function()
    it("is a function", function()
      assert.is_function(iterations.get)
    end)
  end)

  describe("list_cached", function()
    it("is a function", function()
      assert.is_function(iterations.list_cached)
    end)
  end)

  describe("refresh_cache", function()
    it("is a function", function()
      assert.is_function(iterations.refresh_cache)
    end)
  end)

  describe("find_by_name", function()
    it("is a function", function()
      assert.is_function(iterations.find_by_name)
    end)
    it("finds iteration by partial name match", function()
      local test_iterations = {
        { id = 1, name = "Sprint 1" },
        { id = 2, name = "Sprint 2" },
        { id = 3, name = "Backlog" }
      }
      local result = iterations.find_by_name("sprint 2", test_iterations)
      assert.equals(2, result.id)
    end)
  end)

  describe("find_by_id", function()
    it("is a function", function()
      assert.is_function(iterations.find_by_id)
    end)
    it("finds iteration by exact id", function()
      local test_iterations = {
        { id = 1, name = "Sprint 1" },
        { id = 2, name = "Sprint 2" }
      }
      local result = iterations.find_by_id(2, test_iterations)
      assert.equals("Sprint 2", result.name)
    end)
  end)

  describe("get_current", function()
    it("is a function", function()
      assert.is_function(iterations.get_current)
    end)
  end)

  describe("get_upcoming", function()
    it("is a function", function()
      assert.is_function(iterations.get_upcoming)
    end)
  end)

  describe("resolve_name", function()
    it("is a function", function()
      assert.is_function(iterations.resolve_name)
    end)
  end)
end

return describe("longway.api.iterations", _1_)
