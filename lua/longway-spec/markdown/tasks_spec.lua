-- [nfnl] fnl/longway-spec/markdown/tasks_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local tasks_md = require("longway.markdown.tasks")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      local line = "- [ ] Do something <!-- task:123 complete:false -->"
      local parse_line = tasks_md["parse-line"]
      local result = parse_line(line)
      assert.is_not_nil(result)
      assert.equals("Do something", result.description)
      assert.equals(123, result.id)
      assert.is_false(result.complete)
      return assert.is_false(result.is_new)
    end
    it("parses incomplete task with metadata", _4_)
    local function _5_()
      local line = "- [x] Done task <!-- task:456 complete:true -->"
      local parse_line = tasks_md["parse-line"]
      local result = parse_line(line)
      assert.is_not_nil(result)
      assert.is_true(result.complete)
      return assert.equals(456, result.id)
    end
    it("parses complete task with metadata", _5_)
    local function _6_()
      local line = "- [ ] Task <!-- task:789 @eric complete:false -->"
      local parse_line = tasks_md["parse-line"]
      local result = parse_line(line)
      assert.is_not_nil(result)
      return assert.equals("eric", result.owner_mention)
    end
    it("parses task with owner mention", _6_)
    local function _7_()
      local line = "- [ ] New task <!-- task:new complete:false -->"
      local parse_line = tasks_md["parse-line"]
      local result = parse_line(line)
      assert.is_not_nil(result)
      assert.is_nil(result.id)
      return assert.is_true(result.is_new)
    end
    it("parses new task marker", _7_)
    local function _8_()
      local line = "- [ ] Plain task without metadata"
      local parse_line = tasks_md["parse-line"]
      local result = parse_line(line)
      assert.is_not_nil(result)
      assert.equals("Plain task without metadata", result.description)
      assert.is_nil(result.id)
      return assert.is_true(result.is_new)
    end
    it("parses task without metadata as new", _8_)
    local function _9_()
      local parse_line = tasks_md["parse-line"]
      assert.is_nil(parse_line("Regular text"))
      assert.is_nil(parse_line("# Heading"))
      return assert.is_nil(parse_line("* Bullet point"))
    end
    it("returns nil for non-task lines", _9_)
    local function _10_()
      local line = "  - [ ] Indented task <!-- task:100 complete:false -->"
      local parse_line = tasks_md["parse-line"]
      local result = parse_line(line)
      assert.is_not_nil(result)
      assert.equals("Indented task", result.description)
      return assert.equals(100, result.id)
    end
    it("parses task with leading whitespace", _10_)
    local function _11_()
      local line = "- [ ] Task with 'quotes' & symbols! <!-- task:200 complete:false -->"
      local parse_line = tasks_md["parse-line"]
      local result = parse_line(line)
      assert.is_not_nil(result)
      assert.has_substring(result.description, "quotes")
      return assert.has_substring(result.description, "symbols")
    end
    it("parses task with special characters in description", _11_)
    local function _12_()
      local parse_line = tasks_md["parse-line"]
      return assert.is_nil(parse_line(""))
    end
    it("returns nil for empty string", _12_)
    local function _13_()
      local line = "- [ ] X <!-- task:300 complete:false -->"
      local parse_line = tasks_md["parse-line"]
      local result = parse_line(line)
      assert.is_not_nil(result)
      return assert.equals("X", result.description)
    end
    it("handles task with minimal description", _13_)
    local function _14_()
      local line = "- [ ] Task <!-- task:123 complete:false -->"
      local parse_line = tasks_md["parse-line"]
      local result = parse_line(line)
      assert.is_not_nil(result.owner_ids)
      return assert.equals(0, #result.owner_ids)
    end
    return it("initializes owner_ids as empty table", _14_)
  end
  describe("parse-line", _3_)
  local function _15_()
    local function _16_()
      local content = "- [ ] First <!-- task:1 complete:false -->\n- [x] Second <!-- task:2 complete:true -->\n- [ ] Third <!-- task:3 complete:false -->"
      local parse_section = tasks_md["parse-section"]
      local result = parse_section(content)
      assert.equals(3, #result)
      assert.equals("First", result[1].description)
      assert.equals("Second", result[2].description)
      return assert.equals("Third", result[3].description)
    end
    it("parses multiple tasks", _16_)
    local function _17_()
      local content = "- [ ] First <!-- task:1 complete:false -->\n- [ ] Second <!-- task:2 complete:false -->"
      local parse_section = tasks_md["parse-section"]
      local result = parse_section(content)
      assert.equals(1, result[1].position)
      return assert.equals(2, result[2].position)
    end
    it("assigns positions to tasks", _17_)
    local function _18_()
      local content = "Some text before\n- [ ] Only task <!-- task:1 complete:false -->\nSome text after"
      local parse_section = tasks_md["parse-section"]
      local result = parse_section(content)
      return assert.equals(1, #result)
    end
    it("ignores non-task lines", _18_)
    local function _19_()
      local parse_section = tasks_md["parse-section"]
      local result = parse_section("")
      return assert.equals(0, #result)
    end
    it("handles empty content", _19_)
    local function _20_()
      local content = "- [x] Done task <!-- task:1 complete:true -->\n- [ ] New task <!-- task:new -->\n- [ ] Another existing <!-- task:2 complete:false -->"
      local parse_section = tasks_md["parse-section"]
      local result = parse_section(content)
      assert.equals(3, #result)
      assert.equals(1, result[1].id)
      assert.is_true(result[2].is_new)
      return assert.equals(2, result[3].id)
    end
    return it("handles mixed new and existing tasks", _20_)
  end
  describe("parse-section", _15_)
  local function _21_()
    local function _22_()
      local task = {id = 123, description = "Do thing", complete = false, is_new = false}
      local render_task = tasks_md["render-task"]
      local result = render_task(task)
      assert.has_substring(result, "- [ ]")
      assert.has_substring(result, "Do thing")
      assert.has_substring(result, "task:123")
      return assert.has_substring(result, "complete:false")
    end
    it("renders incomplete task", _22_)
    local function _23_()
      local task = {id = 456, description = "Done", complete = true, is_new = false}
      local render_task = tasks_md["render-task"]
      local result = render_task(task)
      assert.has_substring(result, "- [x]")
      return assert.has_substring(result, "complete:true")
    end
    it("renders complete task", _23_)
    local function _24_()
      local task = {description = "New task", is_new = true, complete = false}
      local render_task = tasks_md["render-task"]
      local result = render_task(task)
      return assert.has_substring(result, "task:new")
    end
    it("renders new task without ID", _24_)
    local function _25_()
      local task = {id = 789, description = "Owned task", owner_mention = "eric", complete = false, is_new = false}
      local render_task = tasks_md["render-task"]
      local result = render_task(task)
      assert.has_substring(result, "@eric")
      return assert.has_substring(result, "task:789")
    end
    return it("renders task with owner mention", _25_)
  end
  describe("render-task", _21_)
  local function _26_()
    local function _27_()
      local tasks = {{id = 1, description = "First", position = 1, complete = false}, {id = 2, description = "Second", complete = true, position = 2}}
      local render_tasks = tasks_md["render-tasks"]
      local result = render_tasks(tasks)
      assert.has_substring(result, "First")
      return assert.has_substring(result, "Second")
    end
    it("renders multiple tasks", _27_)
    local function _28_()
      local render_tasks = tasks_md["render-tasks"]
      assert.equals("", render_tasks({}))
      return assert.equals("", render_tasks(nil))
    end
    it("returns empty string for no tasks", _28_)
    local function _29_()
      local tasks = {{id = 2, description = "Second", position = 2, complete = false}, {id = 1, description = "First", position = 1, complete = false}}
      local render_tasks = tasks_md["render-tasks"]
      local result = render_tasks(tasks)
      local first_pos = string.find(result, "First", 1, true)
      local second_pos = string.find(result, "Second", 1, true)
      assert.is_not_nil(first_pos)
      assert.is_not_nil(second_pos)
      return assert.is_true((first_pos < second_pos))
    end
    return it("preserves task order by position", _29_)
  end
  describe("render-tasks", _26_)
  local function _30_()
    local function _31_()
      local tasks = {{id = 1, description = "Task", position = 1, complete = false}}
      local render_section = tasks_md["render-section"]
      local result = render_section(tasks)
      assert.has_substring(result, "<!-- BEGIN SHORTCUT SYNC:tasks -->")
      assert.has_substring(result, "<!-- END SHORTCUT SYNC:tasks -->")
      return assert.has_substring(result, "Task")
    end
    it("wraps tasks in sync markers", _31_)
    local function _32_()
      local render_section = tasks_md["render-section"]
      local result = render_section({})
      assert.has_substring(result, "<!-- BEGIN SHORTCUT SYNC:tasks -->")
      return assert.has_substring(result, "<!-- END SHORTCUT SYNC:tasks -->")
    end
    return it("renders empty section with markers", _32_)
  end
  describe("render-section", _30_)
  local function _33_()
    local function _34_()
      local local_task = {id = 1, description = "Task", complete = true}
      local remote_task = {id = 1, description = "Task", complete = false}
      local task_changed_3f = tasks_md["task-changed?"]
      return assert.is_true(task_changed_3f(local_task, remote_task))
    end
    it("detects completion change", _34_)
    local function _35_()
      local local_task = {id = 1, description = "Updated task", complete = false}
      local remote_task = {id = 1, description = "Original task", complete = false}
      local task_changed_3f = tasks_md["task-changed?"]
      return assert.is_true(task_changed_3f(local_task, remote_task))
    end
    it("detects description change", _35_)
    local function _36_()
      local local_task = {id = 1, description = "Same task", complete = false}
      local remote_task = {id = 1, description = "Same task", complete = false}
      local task_changed_3f = tasks_md["task-changed?"]
      return assert.is_false(task_changed_3f(local_task, remote_task))
    end
    it("returns false for unchanged task", _36_)
    local function _37_()
      local local_task = {id = 1, description = "  Task text  ", complete = false}
      local remote_task = {id = 1, description = "Task text", complete = false}
      local task_changed_3f = tasks_md["task-changed?"]
      return assert.is_false(task_changed_3f(local_task, remote_task))
    end
    it("ignores leading and trailing whitespace in descriptions", _37_)
    local function _38_()
      local local_task = {id = 1, description = nil, complete = false}
      local remote_task = {id = 1, description = nil, complete = false}
      local task_changed_3f = tasks_md["task-changed?"]
      return assert.is_false(task_changed_3f(local_task, remote_task))
    end
    return it("handles nil descriptions", _38_)
  end
  describe("task-changed?", _33_)
  local function _39_()
    local function _40_()
      local tasks = {{id = 1, description = "First"}, {id = 2, description = "Second"}, {id = 3, description = "Third"}}
      local find_task_by_id = tasks_md["find-task-by-id"]
      local result = find_task_by_id(tasks, 2)
      assert.is_not_nil(result)
      return assert.equals("Second", result.description)
    end
    it("finds task by ID", _40_)
    local function _41_()
      local tasks = {{id = 1, description = "First"}}
      local find_task_by_id = tasks_md["find-task-by-id"]
      local result = find_task_by_id(tasks, 999)
      return assert.is_nil(result)
    end
    it("returns nil when not found", _41_)
    local function _42_()
      local tasks = {{id = 1, description = "First"}, {id = 1, description = "Duplicate"}}
      local find_task_by_id = tasks_md["find-task-by-id"]
      local result = find_task_by_id(tasks, 1)
      return assert.equals("First", result.description)
    end
    return it("returns first match when duplicate IDs exist", _42_)
  end
  describe("find-task-by-id", _39_)
  local function _43_()
    local function _44_()
      local a = {{id = 1, description = "Task", complete = false}}
      local b = {{id = 1, description = "Task", complete = false}}
      local tasks_equal_3f = tasks_md["tasks-equal?"]
      return assert.is_true(tasks_equal_3f(a, b))
    end
    it("returns true for identical task lists", _44_)
    local function _45_()
      local a = {{id = 1, description = "Task", complete = false}}
      local b = {{id = 1, description = "Task", complete = false}, {id = 2, description = "Another", complete = false}}
      local tasks_equal_3f = tasks_md["tasks-equal?"]
      return assert.is_false(tasks_equal_3f(a, b))
    end
    it("returns false for different lengths", _45_)
    local function _46_()
      local a = {{id = 1, description = "Task", complete = true}}
      local b = {{id = 1, description = "Task", complete = false}}
      local tasks_equal_3f = tasks_md["tasks-equal?"]
      return assert.is_false(tasks_equal_3f(a, b))
    end
    it("returns false for different completion states", _46_)
    local function _47_()
      local tasks_equal_3f = tasks_md["tasks-equal?"]
      return assert.is_true(tasks_equal_3f({}, {}))
    end
    return it("returns true for two empty lists", _47_)
  end
  describe("tasks-equal?", _43_)
  local function _48_()
    local function _49_()
      local parse_line = tasks_md["parse-line"]
      local render_task = tasks_md["render-task"]
      local original = "- [ ] Do something <!-- task:123 complete:false -->"
      local parsed = parse_line(original)
      local rendered = render_task(parsed)
      assert.has_substring(rendered, "task:123")
      assert.has_substring(rendered, "Do something")
      assert.has_substring(rendered, "complete:false")
      return assert.has_substring(rendered, "- [ ]")
    end
    it("parsed task can be re-rendered with same metadata", _49_)
    local function _50_()
      local parse_line = tasks_md["parse-line"]
      local render_task = tasks_md["render-task"]
      local original = "- [x] Completed <!-- task:456 complete:true -->"
      local parsed = parse_line(original)
      local rendered = render_task(parsed)
      assert.has_substring(rendered, "- [x]")
      assert.has_substring(rendered, "task:456")
      return assert.has_substring(rendered, "complete:true")
    end
    return it("completed task round-trips correctly", _50_)
  end
  return describe("round-trip parse-render", _48_)
end
return describe("longway.markdown.tasks", _1_)
