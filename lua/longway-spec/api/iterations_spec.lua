-- [nfnl] fnl/longway-spec/api/iterations_spec.fnl
local t = require("longway-spec.init")
local iterations = require("longway.api.iterations")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(iterations.list)
    end
    return it("is a function", _4_)
  end
  describe("list", _3_)
  local function _5_()
    local function _6_()
      return assert.is_function(iterations.get)
    end
    return it("is a function", _6_)
  end
  describe("get", _5_)
  local function _7_()
    local function _8_()
      return assert.is_function(iterations["list-cached"])
    end
    return it("is a function", _8_)
  end
  describe("list-cached", _7_)
  local function _9_()
    local function _10_()
      return assert.is_function(iterations["refresh-cache"])
    end
    return it("is a function", _10_)
  end
  describe("refresh-cache", _9_)
  local function _11_()
    local function _12_()
      return assert.is_function(iterations["find-by-name"])
    end
    it("is a function", _12_)
    local function _13_()
      local test_iterations = {{id = 1, name = "Sprint 1"}, {id = 2, name = "Sprint 2"}, {id = 3, name = "Backlog"}}
      local find_by_name = iterations["find-by-name"]
      local result = find_by_name("sprint 2", test_iterations)
      return assert.equals(2, result.id)
    end
    return it("finds iteration by partial name match", _13_)
  end
  describe("find-by-name", _11_)
  local function _14_()
    local function _15_()
      return assert.is_function(iterations["find-by-id"])
    end
    it("is a function", _15_)
    local function _16_()
      local test_iterations = {{id = 1, name = "Sprint 1"}, {id = 2, name = "Sprint 2"}}
      local find_by_id = iterations["find-by-id"]
      local result = find_by_id(2, test_iterations)
      return assert.equals("Sprint 2", result.name)
    end
    return it("finds iteration by exact id", _16_)
  end
  describe("find-by-id", _14_)
  local function _17_()
    local function _18_()
      return assert.is_function(iterations["get-current"])
    end
    return it("is a function", _18_)
  end
  describe("get-current", _17_)
  local function _19_()
    local function _20_()
      return assert.is_function(iterations["get-upcoming"])
    end
    return it("is a function", _20_)
  end
  describe("get-upcoming", _19_)
  local function _21_()
    local function _22_()
      return assert.is_function(iterations["resolve-name"])
    end
    return it("is a function", _22_)
  end
  return describe("resolve-name", _21_)
end
return describe("longway.api.iterations", _1_)
