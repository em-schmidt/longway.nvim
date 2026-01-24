-- Tests for longway.api.members
local t = require("longway-spec.init")
local members = require("longway.api.members")

local function _1_()
  before_each(function() t.setup_test_config({}) end)

  describe("list", function()
    it("is a function", function()
      assert.is_function(members.list)
    end)
  end)

  describe("get_current", function()
    it("is a function", function()
      assert.is_function(members.get_current)
    end)
  end)

  describe("get", function()
    it("is a function", function()
      assert.is_function(members.get)
    end)
  end)

  describe("list_cached", function()
    it("is a function", function()
      assert.is_function(members.list_cached)
    end)
  end)

  describe("refresh_cache", function()
    it("is a function", function()
      assert.is_function(members.refresh_cache)
    end)
  end)

  describe("find_by_name", function()
    it("is a function", function()
      assert.is_function(members.find_by_name)
    end)
    it("finds member by partial name match", function()
      local test_members = {
        { id = "1", profile = { name = "John Doe" } },
        { id = "2", profile = { name = "Jane Smith" } }
      }
      local result = members.find_by_name("john", test_members)
      assert.equals("1", result.id)
    end)
  end)

  describe("find_by_id", function()
    it("is a function", function()
      assert.is_function(members.find_by_id)
    end)
    it("finds member by exact id", function()
      local test_members = {
        { id = "1", profile = { name = "John Doe" } },
        { id = "2", profile = { name = "Jane Smith" } }
      }
      local result = members.find_by_id("2", test_members)
      assert.equals("Jane Smith", result.profile.name)
    end)
  end)

  describe("get_display_name", function()
    it("is a function", function()
      assert.is_function(members.get_display_name)
    end)
    it("returns profile name", function()
      local member = { id = "1", profile = { name = "John Doe" } }
      local name = members.get_display_name(member)
      assert.equals("John Doe", name)
    end)
    it("falls back to mention name", function()
      local member = { id = "1", profile = { mention_name = "johnd" } }
      local name = members.get_display_name(member)
      assert.equals("johnd", name)
    end)
  end)

  describe("resolve_name", function()
    it("is a function", function()
      assert.is_function(members.resolve_name)
    end)
  end)
end

return describe("longway.api.members", _1_)
