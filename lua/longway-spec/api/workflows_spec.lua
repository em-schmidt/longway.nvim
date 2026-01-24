-- Tests for longway.api.workflows
local t = require("longway-spec.init")
local workflows = require("longway.api.workflows")

local function _1_()
  before_each(function() t.setup_test_config({}) end)

  describe("list", function()
    it("is a function", function()
      assert.is_function(workflows.list)
    end)
  end)

  describe("list_cached", function()
    it("is a function", function()
      assert.is_function(workflows.list_cached)
    end)
  end)

  describe("refresh_cache", function()
    it("is a function", function()
      assert.is_function(workflows.refresh_cache)
    end)
  end)

  describe("get_states", function()
    it("is a function", function()
      assert.is_function(workflows.get_states)
    end)
    it("returns states from workflow", function()
      local workflow = {
        states = {
          { id = 1, name = "To Do" },
          { id = 2, name = "In Progress" },
          { id = 3, name = "Done" }
        }
      }
      local states = workflows.get_states(workflow)
      assert.equals(3, #states)
    end)
  end)

  describe("get_all_states", function()
    it("is a function", function()
      assert.is_function(workflows.get_all_states)
    end)
  end)

  describe("find_state_by_name", function()
    it("is a function", function()
      assert.is_function(workflows.find_state_by_name)
    end)
    it("finds state by partial name match", function()
      local test_workflows = {
        {
          states = {
            { id = 1, name = "To Do", type = "unstarted" },
            { id = 2, name = "In Progress", type = "started" },
            { id = 3, name = "Done", type = "done" }
          }
        }
      }
      local result = workflows.find_state_by_name("progress", test_workflows)
      assert.equals(2, result.id)
    end)
  end)

  describe("find_state_by_id", function()
    it("is a function", function()
      assert.is_function(workflows.find_state_by_id)
    end)
    it("finds state by exact id", function()
      local test_workflows = {
        {
          states = {
            { id = 1, name = "To Do" },
            { id = 2, name = "In Progress" }
          }
        }
      }
      local result = workflows.find_state_by_id(2, test_workflows)
      assert.equals("In Progress", result.name)
    end)
  end)

  describe("get_state_type", function()
    it("is a function", function()
      assert.is_function(workflows.get_state_type)
    end)
    it("returns state type", function()
      local state = { id = 1, name = "Done", type = "done" }
      local state_type = workflows.get_state_type(state)
      assert.equals("done", state_type)
    end)
  end)

  describe("is_done_state", function()
    it("is a function", function()
      assert.is_function(workflows.is_done_state)
    end)
    it("returns true for done states", function()
      local state = { type = "done" }
      assert.is_true(workflows.is_done_state(state))
    end)
    it("returns false for other states", function()
      local state = { type = "started" }
      assert.is_false(workflows.is_done_state(state))
    end)
  end)

  describe("is_started_state", function()
    it("is a function", function()
      assert.is_function(workflows.is_started_state)
    end)
    it("returns true for started states", function()
      local state = { type = "started" }
      assert.is_true(workflows.is_started_state(state))
    end)
  end)
end

return describe("longway.api.workflows", _1_)
