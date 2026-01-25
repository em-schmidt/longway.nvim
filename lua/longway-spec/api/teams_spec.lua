-- [nfnl] fnl/longway-spec/api/teams_spec.fnl
local t = require("longway-spec.init")
local teams = require("longway.api.teams")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(teams.list)
    end
    return it("is a function", _4_)
  end
  describe("list", _3_)
  local function _5_()
    local function _6_()
      return assert.is_function(teams.get)
    end
    return it("is a function", _6_)
  end
  describe("get", _5_)
  local function _7_()
    local function _8_()
      return assert.is_function(teams["list-cached"])
    end
    return it("is a function", _8_)
  end
  describe("list-cached", _7_)
  local function _9_()
    local function _10_()
      return assert.is_function(teams["refresh-cache"])
    end
    return it("is a function", _10_)
  end
  describe("refresh-cache", _9_)
  local function _11_()
    local function _12_()
      return assert.is_function(teams["find-by-name"])
    end
    it("is a function", _12_)
    local function _13_()
      local test_teams = {{id = "1", name = "Engineering"}, {id = "2", name = "Design"}, {id = "3", name = "Product"}}
      local find_by_name = teams["find-by-name"]
      local result = find_by_name("eng", test_teams)
      return assert.equals("1", result.id)
    end
    return it("finds team by partial name match", _13_)
  end
  describe("find-by-name", _11_)
  local function _14_()
    local function _15_()
      return assert.is_function(teams["find-by-id"])
    end
    it("is a function", _15_)
    local function _16_()
      local test_teams = {{id = "1", name = "Engineering"}, {id = "2", name = "Design"}}
      local find_by_id = teams["find-by-id"]
      local result = find_by_id("2", test_teams)
      return assert.equals("Design", result.name)
    end
    return it("finds team by exact id", _16_)
  end
  describe("find-by-id", _14_)
  local function _17_()
    local function _18_()
      return assert.is_function(teams["get-members"])
    end
    it("is a function", _18_)
    local function _19_()
      local team = {id = "1", name = "Engineering", member_ids = {"a", "b", "c"}}
      local get_members = teams["get-members"]
      local member_ids = get_members(team)
      return assert.equals(3, #member_ids)
    end
    return it("returns member IDs from team", _19_)
  end
  describe("get-members", _17_)
  local function _20_()
    local function _21_()
      return assert.is_function(teams["resolve-name"])
    end
    return it("is a function", _21_)
  end
  return describe("resolve-name", _20_)
end
return describe("longway.api.teams", _1_)
