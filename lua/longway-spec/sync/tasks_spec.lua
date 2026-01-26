local t = require("longway-spec.init")
require("longway-spec.assertions")
local tasks_sync = require("longway.sync.tasks")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      local local_tasks = {{description = "New task", is_new = true, complete = false}}
      local remote_tasks = {}
      local result = tasks_sync.diff(local_tasks, remote_tasks)
      assert.equals(1, #result.created)
      assert.equals(0, #result.updated)
      assert.equals(0, #result.deleted)
      return assert.equals(0, #result.unchanged)
    end
    it("detects new local tasks", _4_)
    local function _5_()
      local local_tasks = {{id = 1, description = "Task", complete = true, is_new = false}}
      local remote_tasks = {{id = 1, description = "Task", complete = false}}
      local result = tasks_sync.diff(local_tasks, remote_tasks)
      assert.equals(0, #result.created)
      assert.equals(1, #result.updated)
      return assert.equals(0, #result.deleted)
    end
    it("detects updated tasks", _5_)
    local function _6_()
      local local_tasks = {}
      local remote_tasks = {{id = 1, description = "Remote task", complete = false}}
      local result = tasks_sync.diff(local_tasks, remote_tasks)
      assert.equals(0, #result.created)
      assert.equals(0, #result.updated)
      assert.equals(1, #result.deleted)
      return assert.equals(1, result.deleted[1])
    end
    it("detects deleted tasks", _6_)
    local function _7_()
      local local_tasks = {{id = 1, description = "Same", complete = false, is_new = false}}
      local remote_tasks = {{id = 1, description = "Same", complete = false}}
      local result = tasks_sync.diff(local_tasks, remote_tasks)
      assert.equals(0, #result.created)
      assert.equals(0, #result.updated)
      assert.equals(0, #result.deleted)
      return assert.equals(1, #result.unchanged)
    end
    it("detects unchanged tasks", _7_)
    local function _8_()
      local local_tasks = {{id = 1, description = "Unchanged", complete = false, is_new = false}, {id = 2, description = "Updated desc", complete = false, is_new = false}, {description = "Brand new", is_new = true, complete = false}}
      local remote_tasks = {{id = 1, description = "Unchanged", complete = false}, {id = 2, description = "Original desc", complete = false}, {id = 3, description = "Will be deleted", complete = false}}
      local result = tasks_sync.diff(local_tasks, remote_tasks)
      assert.equals(1, #result.created)
      assert.equals(1, #result.updated)
      assert.equals(1, #result.deleted)
      return assert.equals(1, #result.unchanged)
    end
    return it("handles complex diff scenario", _8_)
  end
  describe("diff", _3_)
  local function _9_()
    local function _10_()
      local diff = {created = {{description = "New"}}, updated = {}, deleted = {}, unchanged = {}}
      local has_changes_3f = tasks_sync["has-changes?"]
      return assert.is_true(has_changes_3f(diff))
    end
    it("returns true when there are created tasks", _10_)
    local function _11_()
      local diff = {created = {}, updated = {{id = 1}}, deleted = {}, unchanged = {}}
      local has_changes_3f = tasks_sync["has-changes?"]
      return assert.is_true(has_changes_3f(diff))
    end
    it("returns true when there are updated tasks", _11_)
    local function _12_()
      local diff = {created = {}, updated = {}, deleted = {1}, unchanged = {}}
      local has_changes_3f = tasks_sync["has-changes?"]
      return assert.is_true(has_changes_3f(diff))
    end
    it("returns true when there are deleted tasks", _12_)
    local function _13_()
      local diff = {created = {}, updated = {}, deleted = {}, unchanged = {{id = 1}}}
      local has_changes_3f = tasks_sync["has-changes?"]
      return assert.is_false(has_changes_3f(diff))
    end
    return it("returns false when no changes", _13_)
  end
  describe("has-changes?", _9_)
  local function _14_()
    local function _15_()
      local story = {tasks = {{id = 1, description = "Task 1", complete = false}, {id = 2, description = "Task 2", complete = true}}}
      local result = tasks_sync.pull(story)
      assert.is_true(result.ok)
      return assert.equals(2, #result.tasks)
    end
    it("extracts tasks from story", _15_)
    local function _16_()
      local story = {tasks = {}}
      local result = tasks_sync.pull(story)
      assert.is_true(result.ok)
      return assert.equals(0, #result.tasks)
    end
    it("handles story with no tasks", _16_)
    local function _17_()
      local story = {}
      local result = tasks_sync.pull(story)
      assert.is_true(result.ok)
      return assert.equals(0, #result.tasks)
    end
    return it("handles story with nil tasks", _17_)
  end
  describe("pull", _14_)
  local function _18_()
    local function _19_()
      local local_tasks = {{description = "Local new", is_new = true}}
      local remote_tasks = {}
      local previous_tasks = {}
      local result = tasks_sync.merge(local_tasks, remote_tasks, previous_tasks)
      assert.equals(1, #result.tasks)
      return assert.equals("Local new", result.tasks[1].description)
    end
    it("keeps new local tasks", _19_)
    local function _20_()
      local local_tasks = {}
      local remote_tasks = {{id = 1, description = "Remote new", complete = false}}
      local previous_tasks = {}
      local result = tasks_sync.merge(local_tasks, remote_tasks, previous_tasks)
      assert.equals(1, #result.remote_added)
      return assert.equals(1, result.remote_added[1].id)
    end
    it("adds new remote tasks", _20_)
    local function _21_()
      local local_tasks = {{id = 1, description = "Local version", complete = true}}
      local remote_tasks = {{id = 1, description = "Remote version", complete = false}}
      local previous_tasks = {{id = 1, description = "Original", complete = false}}
      local result = tasks_sync.merge(local_tasks, remote_tasks, previous_tasks)
      return assert.equals(1, #result.conflicts)
    end
    return it("detects conflicts when both changed", _21_)
  end
  return describe("merge", _18_)
end
return describe("longway.sync.tasks", _1_)
