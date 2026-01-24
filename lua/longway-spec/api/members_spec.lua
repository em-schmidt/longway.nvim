-- [nfnl] fnl/longway-spec/api/members_spec.fnl
local t = require("longway-spec.init")
local members = require("longway.api.members")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(members.list)
    end
    return it("is a function", _4_)
  end
  describe("list", _3_)
  local function _5_()
    local function _6_()
      return assert.is_function(members["get-current"])
    end
    return it("is a function", _6_)
  end
  describe("get-current", _5_)
  local function _7_()
    local function _8_()
      return assert.is_function(members.get)
    end
    return it("is a function", _8_)
  end
  describe("get", _7_)
  local function _9_()
    local function _10_()
      return assert.is_function(members["list-cached"])
    end
    return it("is a function", _10_)
  end
  describe("list-cached", _9_)
  local function _11_()
    local function _12_()
      return assert.is_function(members["refresh-cache"])
    end
    return it("is a function", _12_)
  end
  describe("refresh-cache", _11_)
  local function _13_()
    local function _14_()
      return assert.is_function(members["find-by-name"])
    end
    it("is a function", _14_)
    local function _15_()
      local test_members = {{id = "1", profile = {name = "John Doe"}}, {id = "2", profile = {name = "Jane Smith"}}}
      local find_by_name = members["find-by-name"]
      local result = find_by_name("john", test_members)
      return assert.equals("1", result.id)
    end
    return it("finds member by partial name match", _15_)
  end
  describe("find-by-name", _13_)
  local function _16_()
    local function _17_()
      return assert.is_function(members["find-by-id"])
    end
    it("is a function", _17_)
    local function _18_()
      local test_members = {{id = "1", profile = {name = "John Doe"}}, {id = "2", profile = {name = "Jane Smith"}}}
      local find_by_id = members["find-by-id"]
      local result = find_by_id("2", test_members)
      return assert.equals("Jane Smith", result.profile.name)
    end
    return it("finds member by exact id", _18_)
  end
  describe("find-by-id", _16_)
  local function _19_()
    local function _20_()
      return assert.is_function(members["get-display-name"])
    end
    it("is a function", _20_)
    local function _21_()
      local member = {id = "1", profile = {name = "John Doe"}}
      local get_display_name = members["get-display-name"]
      local name = get_display_name(member)
      return assert.equals("John Doe", name)
    end
    it("returns profile name", _21_)
    local function _22_()
      local member = {id = "1", profile = {mention_name = "johnd"}}
      local get_display_name = members["get-display-name"]
      local name = get_display_name(member)
      return assert.equals("johnd", name)
    end
    return it("falls back to mention name", _22_)
  end
  describe("get-display-name", _19_)
  local function _23_()
    local function _24_()
      return assert.is_function(members["resolve-name"])
    end
    return it("is a function", _24_)
  end
  return describe("resolve-name", _23_)
end
return describe("longway.api.members", _1_)
