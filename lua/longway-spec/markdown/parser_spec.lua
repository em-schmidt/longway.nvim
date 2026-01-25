-- [nfnl] fnl/longway-spec/markdown/parser_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local parser = require("longway.markdown.parser")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      local content = "# Title\n\n<!-- BEGIN SHORTCUT SYNC:description -->\nThis is the description content.\n<!-- END SHORTCUT SYNC:description -->"
      local extract_description = parser["extract-description"]
      local result = extract_description(content)
      return assert.equals("This is the description content.", result)
    end
    it("extracts content from description sync section", _4_)
    local function _5_()
      local content = "# Title\n\nJust regular content."
      local extract_description = parser["extract-description"]
      local result = extract_description(content)
      return assert.is_nil(result)
    end
    it("returns nil when no description section", _5_)
    local function _6_()
      local content = "<!-- BEGIN SHORTCUT SYNC:description -->\nLine 1\nLine 2\nLine 3\n<!-- END SHORTCUT SYNC:description -->"
      local extract_description = parser["extract-description"]
      local result = extract_description(content)
      assert.has_substring(result, "Line 1")
      assert.has_substring(result, "Line 2")
      return assert.has_substring(result, "Line 3")
    end
    return it("handles multiline description", _6_)
  end
  describe("extract-description", _3_)
  local function _7_()
    local function _8_()
      local content = "<!-- BEGIN SHORTCUT SYNC:tasks -->\n- [ ] Task one <!-- task:1 complete:false -->\n<!-- END SHORTCUT SYNC:tasks -->"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      assert.equals(1, #result)
      assert.equals("Task one", result[1].description)
      return assert.is_false(result[1].complete)
    end
    it("extracts incomplete tasks", _8_)
    local function _9_()
      local content = "<!-- BEGIN SHORTCUT SYNC:tasks -->\n- [x] Done task <!-- task:2 complete:true -->\n<!-- END SHORTCUT SYNC:tasks -->"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      assert.equals(1, #result)
      return assert.is_true(result[1].complete)
    end
    it("extracts complete tasks", _9_)
    local function _10_()
      local content = "<!-- BEGIN SHORTCUT SYNC:tasks -->\n- [ ] Task <!-- task:12345 complete:false -->\n<!-- END SHORTCUT SYNC:tasks -->"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      return assert.equals(12345, result[1].id)
    end
    it("extracts task IDs", _10_)
    local function _11_()
      local content = "<!-- BEGIN SHORTCUT SYNC:tasks -->\n- [ ] New task <!-- task:new complete:false -->\n<!-- END SHORTCUT SYNC:tasks -->"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      assert.is_nil(result[1].id)
      return assert.is_true(result[1].is_new)
    end
    it("handles new tasks without ID", _11_)
    local function _12_()
      local content = "# No tasks here"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      return assert.same({}, result)
    end
    it("returns empty array when no tasks section", _12_)
    local function _13_()
      local content = "<!-- BEGIN SHORTCUT SYNC:tasks -->\n- [ ] First <!-- task:1 complete:false -->\n- [x] Second <!-- task:2 complete:true -->\n- [ ] Third <!-- task:3 complete:false -->\n<!-- END SHORTCUT SYNC:tasks -->"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      return assert.equals(3, #result)
    end
    return it("extracts multiple tasks", _13_)
  end
  describe("extract-tasks", _7_)
  local function _14_()
    local function _15_()
      local content = "<!-- BEGIN SHORTCUT SYNC:comments -->\n---\n**John Doe** \194\183 2026-01-10 10:30 <!-- comment:123 -->\n\nThis is my comment.\n<!-- END SHORTCUT SYNC:comments -->"
      local extract_comments = parser["extract-comments"]
      local result = extract_comments(content)
      assert.equals(1, #result)
      assert.equals("John Doe", result[1].author)
      return assert.has_substring(result[1].text, "This is my comment")
    end
    it("extracts comment author and text", _15_)
    local function _16_()
      local content = "<!-- BEGIN SHORTCUT SYNC:comments -->\n---\n**Author** \194\183 2026-01-10 10:30 <!-- comment:456 -->\n\nComment text\n<!-- END SHORTCUT SYNC:comments -->"
      local extract_comments = parser["extract-comments"]
      local result = extract_comments(content)
      return assert.equals(456, result[1].id)
    end
    it("extracts comment IDs", _16_)
    local function _17_()
      local content = "# No comments"
      local extract_comments = parser["extract-comments"]
      local result = extract_comments(content)
      return assert.same({}, result)
    end
    return it("returns empty array when no comments section", _17_)
  end
  describe("extract-comments", _14_)
  local function _18_()
    local function _19_()
      local content = t["sample-markdown"]()
      local result = parser.parse(content)
      assert.is_not_nil(result.frontmatter)
      assert.is_not_nil(result.description)
      assert.is_table(result.tasks)
      return assert.is_table(result.comments)
    end
    it("parses complete markdown file", _19_)
    local function _20_()
      local content = t["sample-markdown"]()
      local result = parser.parse(content)
      assert.equals(12345, result.frontmatter.shortcut_id)
      return assert.equals("story", result.frontmatter.shortcut_type)
    end
    return it("extracts frontmatter fields", _20_)
  end
  describe("parse", _18_)
  local function _21_()
    local function _22_()
      local content = t["sample-markdown"]()
      local get_shortcut_id = parser["get-shortcut-id"]
      local result = get_shortcut_id(content)
      return assert.equals(12345, result)
    end
    it("extracts ID from frontmatter", _22_)
    local function _23_()
      local content = "# No frontmatter"
      local get_shortcut_id = parser["get-shortcut-id"]
      local result = get_shortcut_id(content)
      return assert.is_nil(result)
    end
    return it("returns nil when no ID", _23_)
  end
  describe("get-shortcut-id", _21_)
  local function _24_()
    local function _25_()
      local content = t["sample-markdown"]()
      local is_longway_file = parser["is-longway-file"]
      return assert.is_true(is_longway_file(content))
    end
    it("returns true for longway files", _25_)
    local function _26_()
      local content = "# Regular File\n\nJust content."
      local is_longway_file = parser["is-longway-file"]
      return assert.is_false(is_longway_file(content))
    end
    return it("returns false for regular markdown", _26_)
  end
  return describe("is-longway-file", _24_)
end
return describe("longway.markdown.parser", _1_)
