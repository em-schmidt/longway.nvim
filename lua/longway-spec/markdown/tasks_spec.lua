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
    return it("returns nil for non-task lines", _9_)
  end
  describe("parse-line", _3_)
  local function _10_()
    local function _11_()
      local content = "- [ ] First <!-- task:1 complete:false -->\n- [x] Second <!-- task:2 complete:true -->\n- [ ] Third <!-- task:3 complete:false -->"
      local parse_section = tasks_md["parse-section"]
      local result = parse_section(content)
      assert.equals(3, #result)
      assert.equals("First", result[1].description)
      assert.equals("Second", result[2].description)
      return assert.equals("Third", result[3].description)
    end
    it("parses multiple tasks", _11_)
    local function _12_()
      local content = "- [ ] First <!-- task:1 complete:false -->\n- [ ] Second <!-- task:2 complete:false -->"
      local parse_section = tasks_md["parse-section"]
      local result = parse_section(content)
      assert.equals(1, result[1].position)
      return assert.equals(2, result[2].position)
    end
    it("assigns positions to tasks", _12_)
    local function _13_()
      local content = "Some text before\n- [ ] Only task <!-- task:1 complete:false -->\nSome text after"
      local parse_section = tasks_md["parse-section"]
      local result = parse_section(content)
      return assert.equals(1, #result)
    end
    return it("ignores non-task lines", _13_)
  end
  describe("parse-section", _10_)
  local function _14_()
    local function _15_()
      local task = {id = 123, description = "Do thing", complete = false, is_new = false}
      local render_task = tasks_md["render-task"]
      local result = render_task(task)
      assert.has_substring(result, "- [ ]")
      assert.has_substring(result, "Do thing")
      assert.has_substring(result, "task:123")
      return assert.has_substring(result, "complete:false")
    end
    it("renders incomplete task", _15_)
    local function _16_()
      local task = {id = 456, description = "Done", complete = true, is_new = false}
      local render_task = tasks_md["render-task"]
      local result = render_task(task)
      assert.has_substring(result, "- [x]")
      return assert.has_substring(result, "complete:true")
    end
    it("renders complete task", _16_)
    local function _17_()
      local task = {description = "New task", is_new = true, complete = false}
      local render_task = tasks_md["render-task"]
      local result = render_task(task)
      return assert.has_substring(result, "task:new")
    end
    return it("renders new task without ID", _17_)
  end
  describe("render-task", _14_)
  local function _18_()
    local function _19_()
      local tasks = {{id = 1, description = "First", position = 1, complete = false}, {id = 2, description = "Second", complete = true, position = 2}}
      local render_tasks = tasks_md["render-tasks"]
      local result = render_tasks(tasks)
      assert.has_substring(result, "First")
      return assert.has_substring(result, "Second")
    end
    it("renders multiple tasks", _19_)
    local function _20_()
      local render_tasks = tasks_md["render-tasks"]
      assert.equals("", render_tasks({}))
      return assert.equals("", render_tasks(nil))
    end
    return it("returns empty string for no tasks", _20_)
  end
  describe("render-tasks", _18_)
  local function _21_()
    local function _22_()
      local local_task = {id = 1, description = "Task", complete = true}
      local remote_task = {id = 1, description = "Task", complete = false}
      local task_changed_3f = tasks_md["task-changed?"]
      return assert.is_true(task_changed_3f(local_task, remote_task))
    end
    it("detects completion change", _22_)
    local function _23_()
      local local_task = {id = 1, description = "Updated task", complete = false}
      local remote_task = {id = 1, description = "Original task", complete = false}
      local task_changed_3f = tasks_md["task-changed?"]
      return assert.is_true(task_changed_3f(local_task, remote_task))
    end
    it("detects description change", _23_)
    local function _24_()
      local local_task = {id = 1, description = "Same task", complete = false}
      local remote_task = {id = 1, description = "Same task", complete = false}
      local task_changed_3f = tasks_md["task-changed?"]
      return assert.is_false(task_changed_3f(local_task, remote_task))
    end
    return it("returns false for unchanged task", _24_)
  end
  describe("task-changed?", _21_)
  local function _25_()
    local function _26_()
      local tasks = {{id = 1, description = "First"}, {id = 2, description = "Second"}, {id = 3, description = "Third"}}
      local find_task_by_id = tasks_md["find-task-by-id"]
      local result = find_task_by_id(tasks, 2)
      assert.is_not_nil(result)
      return assert.equals("Second", result.description)
    end
    it("finds task by ID", _26_)
    local function _27_()
      local tasks = {{id = 1, description = "First"}}
      local find_task_by_id = tasks_md["find-task-by-id"]
      local result = find_task_by_id(tasks, 999)
      return assert.is_nil(result)
    end
    return it("returns nil when not found", _27_)
  end
  return describe("find-task-by-id", _25_)
end
return describe("longway.markdown.tasks", _1_)
