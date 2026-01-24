-- Tests for longway.api.teams
local t = require("longway-spec.init")
local teams = require("longway.api.teams")

local function _1_()
  before_each(function() t.setup_test_config({}) end)

  describe("list", function()
    it("is a function", function()
      assert.is_function(teams.list)
    end)
  end)

  describe("get", function()
    it("is a function", function()
      assert.is_function(teams.get)
    end)
  end)

  describe("list_cached", function()
    it("is a function", function()
      assert.is_function(teams.list_cached)
    end)
  end)

  describe("refresh_cache", function()
    it("is a function", function()
      assert.is_function(teams.refresh_cache)
    end)
  end)

  describe("find_by_name", function()
    it("is a function", function()
      assert.is_function(teams.find_by_name)
    end)
    it("finds team by partial name match", function()
      local test_teams = {
        { id = "1", name = "Engineering" },
        { id = "2", name = "Design" },
        { id = "3", name = "Product" }
      }
      local result = teams.find_by_name("eng", test_teams)
      assert.equals("1", result.id)
    end)
  end)

  describe("find_by_id", function()
    it("is a function", function()
      assert.is_function(teams.find_by_id)
    end)
    it("finds team by exact id", function()
      local test_teams = {
        { id = "1", name = "Engineering" },
        { id = "2", name = "Design" }
      }
      local result = teams.find_by_id("2", test_teams)
      assert.equals("Design", result.name)
    end)
  end)

  describe("get_members", function()
    it("is a function", function()
      assert.is_function(teams.get_members)
    end)
    it("returns member IDs from team", function()
      local team = { id = "1", name = "Engineering", member_ids = { "a", "b", "c" } }
      local member_ids = teams.get_members(team)
      assert.equals(3, #member_ids)
    end)
  end)

  describe("resolve_name", function()
    it("is a function", function()
      assert.is_function(teams.resolve_name)
    end)
  end)
end

return describe("longway.api.teams", _1_)
