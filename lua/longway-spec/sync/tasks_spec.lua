-- [nfnl] fnl/longway-spec/sync/tasks_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local tasks_sync = require("longway.sync.tasks")
local tasks_md = require("longway.markdown.tasks")
local hash = require("longway.util.hash")
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
    it("handles complex diff scenario", _8_)
    local function _9_()
      local remote_tasks = {{id = 1, description = "Task", complete = false}}
      local result = tasks_sync.diff(nil, remote_tasks)
      assert.equals(0, #result.created)
      return assert.equals(1, #result.deleted)
    end
    it("handles nil local tasks", _9_)
    local function _10_()
      local local_tasks = {{description = "New", is_new = true, complete = false}}
      local result = tasks_sync.diff(local_tasks, nil)
      assert.equals(1, #result.created)
      return assert.equals(0, #result.deleted)
    end
    it("handles nil remote tasks", _10_)
    local function _11_()
      local result = tasks_sync.diff(nil, nil)
      assert.equals(0, #result.created)
      assert.equals(0, #result.updated)
      assert.equals(0, #result.deleted)
      return assert.equals(0, #result.unchanged)
    end
    it("handles both nil", _11_)
    local function _12_()
      local local_tasks = {{id = 99, description = "Locally retained", complete = false, is_new = false}}
      local remote_tasks = {}
      local result = tasks_sync.diff(local_tasks, remote_tasks)
      assert.equals(1, #result.created)
      return assert.equals(0, #result.updated)
    end
    it("treats locally present task missing from remote as new", _12_)
    local function _13_()
      local local_tasks = {{id = 1, description = "Changed description", complete = false, is_new = false}}
      local remote_tasks = {{id = 1, description = "Original description", complete = false}}
      local result = tasks_sync.diff(local_tasks, remote_tasks)
      assert.equals(1, #result.updated)
      return assert.equals("Changed description", result.updated[1].description)
    end
    return it("detects description change only", _13_)
  end
  describe("diff", _3_)
  local function _14_()
    local function _15_()
      local diff = {created = {{description = "New"}}, updated = {}, deleted = {}, unchanged = {}}
      local has_changes_3f = tasks_sync["has-changes?"]
      return assert.is_true(has_changes_3f(diff))
    end
    it("returns true when there are created tasks", _15_)
    local function _16_()
      local diff = {created = {}, updated = {{id = 1}}, deleted = {}, unchanged = {}}
      local has_changes_3f = tasks_sync["has-changes?"]
      return assert.is_true(has_changes_3f(diff))
    end
    it("returns true when there are updated tasks", _16_)
    local function _17_()
      local diff = {created = {}, updated = {}, deleted = {1}, unchanged = {}}
      local has_changes_3f = tasks_sync["has-changes?"]
      return assert.is_true(has_changes_3f(diff))
    end
    it("returns true when there are deleted tasks", _17_)
    local function _18_()
      local diff = {created = {}, updated = {}, deleted = {}, unchanged = {{id = 1}}}
      local has_changes_3f = tasks_sync["has-changes?"]
      return assert.is_false(has_changes_3f(diff))
    end
    return it("returns false when no changes", _18_)
  end
  describe("has-changes?", _14_)
  local function _19_()
    local function _20_()
      local story = {tasks = {{id = 1, description = "Task 1", complete = false}, {id = 2, description = "Task 2", complete = true}}}
      local result = tasks_sync.pull(story)
      assert.is_true(result.ok)
      return assert.equals(2, #result.tasks)
    end
    it("extracts tasks from story", _20_)
    local function _21_()
      local story = {tasks = {}}
      local result = tasks_sync.pull(story)
      assert.is_true(result.ok)
      return assert.equals(0, #result.tasks)
    end
    it("handles story with no tasks", _21_)
    local function _22_()
      local story = {}
      local result = tasks_sync.pull(story)
      assert.is_true(result.ok)
      return assert.equals(0, #result.tasks)
    end
    it("handles story with nil tasks", _22_)
    local function _23_()
      local story = {tasks = {{id = 42, description = "My task", complete = true}}}
      local result = tasks_sync.pull(story)
      assert.equals(42, result.tasks[1].id)
      assert.equals("My task", result.tasks[1].description)
      return assert.is_true(result.tasks[1].complete)
    end
    it("preserves task IDs and descriptions", _23_)
    local function _24_()
      local story = {tasks = {{id = 1, description = "Task", complete = false}}}
      local result = tasks_sync.pull(story)
      return assert.is_false(result.tasks[1].is_new)
    end
    it("sets is_new to false for all pulled tasks", _24_)
    local function _25_()
      local story = {tasks = {{id = 1, description = "First", complete = false}, {id = 2, description = "Second", complete = false}}}
      local result = tasks_sync.pull(story)
      assert.equals(1, result.tasks[1].position)
      return assert.equals(2, result.tasks[2].position)
    end
    return it("assigns positions", _25_)
  end
  describe("pull", _19_)
  local function _26_()
    local function _27_()
      local local_tasks = {{description = "Local new", is_new = true}}
      local remote_tasks = {}
      local previous_tasks = {}
      local result = tasks_sync.merge(local_tasks, remote_tasks, previous_tasks)
      assert.equals(1, #result.tasks)
      return assert.equals("Local new", result.tasks[1].description)
    end
    it("keeps new local tasks", _27_)
    local function _28_()
      local local_tasks = {}
      local remote_tasks = {{id = 1, description = "Remote new", complete = false}}
      local previous_tasks = {}
      local result = tasks_sync.merge(local_tasks, remote_tasks, previous_tasks)
      assert.equals(1, #result.remote_added)
      return assert.equals(1, result.remote_added[1].id)
    end
    it("adds new remote tasks", _28_)
    local function _29_()
      local local_tasks = {{id = 1, description = "Local version", complete = true}}
      local remote_tasks = {{id = 1, description = "Remote version", complete = false}}
      local previous_tasks = {{id = 1, description = "Original", complete = false}}
      local result = tasks_sync.merge(local_tasks, remote_tasks, previous_tasks)
      return assert.equals(1, #result.conflicts)
    end
    it("detects conflicts when both changed", _29_)
    local function _30_()
      local local_tasks = {{id = 1, description = "Task", complete = false}}
      local remote_tasks = {}
      local previous_tasks = {{id = 1, description = "Task", complete = false}}
      local result = tasks_sync.merge(local_tasks, remote_tasks, previous_tasks)
      return assert.equals(1, #result.remote_deleted)
    end
    it("detects remote deletions", _30_)
    local function _31_()
      local local_tasks = {{id = 1, description = "Updated locally", complete = true}}
      local remote_tasks = {{id = 1, description = "Original", complete = false}}
      local previous_tasks = {{id = 1, description = "Original", complete = false}}
      local result = tasks_sync.merge(local_tasks, remote_tasks, previous_tasks)
      assert.equals(0, #result.conflicts)
      assert.equals(1, #result.tasks)
      return assert.equals("Updated locally", result.tasks[1].description)
    end
    it("keeps locally changed task when remote unchanged", _31_)
    local function _32_()
      local result = tasks_sync.merge({}, {}, {})
      assert.equals(0, #result.tasks)
      return assert.equals(0, #result.conflicts)
    end
    return it("handles empty merge", _32_)
  end
  describe("merge", _26_)
  local function _33_()
    local function _34_()
      local parse_section = tasks_md["parse-section"]
      local local_content = "- [x] Design auth flow <!-- task:101 complete:true -->\n- [ ] New task from user <!-- task:new -->"
      local local_tasks = parse_section(local_content)
      local remote_tasks = {{id = 101, description = "Design auth flow", complete = false}, {id = 102, description = "Set up schema", complete = false}}
      local diff = tasks_sync.diff(local_tasks, remote_tasks)
      assert.equals(1, #diff.updated)
      assert.equals(1, #diff.created)
      assert.equals(1, #diff.deleted)
      return assert.equals(102, diff.deleted[1])
    end
    it("parses markdown, diffs with remote, detects changes", _34_)
    local function _35_()
      local tasks = {{id = 1, description = "Task A", complete = false}, {id = 2, description = "Task B", complete = true}}
      local hash1 = hash["tasks-hash"](tasks)
      local hash2 = hash["tasks-hash"](tasks)
      assert.equals(hash1, hash2)
      local modified = {{id = 1, description = "Task A", complete = true}, {id = 2, description = "Task B", complete = true}}
      local hash3 = hash["tasks-hash"](modified)
      return assert.is_not.equals(hash1, hash3)
    end
    return it("computes stable hash for tasks before and after round-trip", _35_)
  end
  return describe("integration: parse-diff round-trip", _33_)
end
return describe("longway.sync.tasks", _1_)
