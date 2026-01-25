-- [nfnl] fnl/longway-spec/api/workflows_spec.fnl
local t = require("longway-spec.init")
local workflows = require("longway.api.workflows")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(workflows.list)
    end
    return it("is a function", _4_)
  end
  describe("list", _3_)
  local function _5_()
    local function _6_()
      return assert.is_function(workflows["list-cached"])
    end
    return it("is a function", _6_)
  end
  describe("list-cached", _5_)
  local function _7_()
    local function _8_()
      return assert.is_function(workflows["refresh-cache"])
    end
    return it("is a function", _8_)
  end
  describe("refresh-cache", _7_)
  local function _9_()
    local function _10_()
      return assert.is_function(workflows["get-states"])
    end
    it("is a function", _10_)
    local function _11_()
      local workflow = {states = {{id = 1, name = "To Do"}, {id = 2, name = "In Progress"}, {id = 3, name = "Done"}}}
      local get_states = workflows["get-states"]
      local states = get_states(workflow)
      return assert.equals(3, #states)
    end
    return it("returns states from workflow", _11_)
  end
  describe("get-states", _9_)
  local function _12_()
    local function _13_()
      return assert.is_function(workflows["get-all-states"])
    end
    return it("is a function", _13_)
  end
  describe("get-all-states", _12_)
  local function _14_()
    local function _15_()
      return assert.is_function(workflows["find-state-by-name"])
    end
    it("is a function", _15_)
    local function _16_()
      local test_workflows = {{states = {{id = 1, name = "To Do", type = "unstarted"}, {id = 2, name = "In Progress", type = "started"}, {id = 3, name = "Done", type = "done"}}}}
      local find_state_by_name = workflows["find-state-by-name"]
      local result = find_state_by_name("progress", test_workflows)
      return assert.equals(2, result.id)
    end
    return it("finds state by partial name match", _16_)
  end
  describe("find-state-by-name", _14_)
  local function _17_()
    local function _18_()
      return assert.is_function(workflows["find-state-by-id"])
    end
    it("is a function", _18_)
    local function _19_()
      local test_workflows = {{states = {{id = 1, name = "To Do"}, {id = 2, name = "In Progress"}}}}
      local find_state_by_id = workflows["find-state-by-id"]
      local result = find_state_by_id(2, test_workflows)
      return assert.equals("In Progress", result.name)
    end
    return it("finds state by exact id", _19_)
  end
  describe("find-state-by-id", _17_)
  local function _20_()
    local function _21_()
      return assert.is_function(workflows["get-state-type"])
    end
    it("is a function", _21_)
    local function _22_()
      local state = {id = 1, name = "Done", type = "done"}
      local get_state_type = workflows["get-state-type"]
      local type = get_state_type(state)
      return assert.equals("done", type)
    end
    return it("returns state type", _22_)
  end
  describe("get-state-type", _20_)
  local function _23_()
    local function _24_()
      return assert.is_function(workflows["is-done-state"])
    end
    it("is a function", _24_)
    local function _25_()
      local state = {type = "done"}
      local is_done_state = workflows["is-done-state"]
      return assert.is_true(is_done_state(state))
    end
    it("returns true for done states", _25_)
    local function _26_()
      local state = {type = "started"}
      local is_done_state = workflows["is-done-state"]
      return assert.is_false(is_done_state(state))
    end
    return it("returns false for other states", _26_)
  end
  describe("is-done-state", _23_)
  local function _27_()
    local function _28_()
      return assert.is_function(workflows["is-started-state"])
    end
    it("is a function", _28_)
    local function _29_()
      local state = {type = "started"}
      local is_started_state = workflows["is-started-state"]
      return assert.is_true(is_started_state(state))
    end
    return it("returns true for started states", _29_)
  end
  return describe("is-started-state", _27_)
end
return describe("longway.api.workflows", _1_)
