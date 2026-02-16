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
      local content = "# Title\n\n## Description\n\nThis is the description content.\n\n## Tasks\n\nsome tasks"
      local extract_description = parser["extract-description"]
      local result = extract_description(content)
      return assert.equals("This is the description content.", result)
    end
    it("extracts content from description section", _4_)
    local function _5_()
      local content = "# Title\n\nJust regular content."
      local extract_description = parser["extract-description"]
      local result = extract_description(content)
      return assert.is_nil(result)
    end
    it("returns nil when no description section", _5_)
    local function _6_()
      local content = "# Title\n\n## Description\n\nLine 1\nLine 2\nLine 3\n\n## Tasks\n"
      local extract_description = parser["extract-description"]
      local result = extract_description(content)
      assert.has_substring(result, "Line 1")
      assert.has_substring(result, "Line 2")
      return assert.has_substring(result, "Line 3")
    end
    it("handles multiline description", _6_)
    local function _7_()
      local content = "# Title\n\n## Description\n\nDescription to the end."
      local extract_description = parser["extract-description"]
      local result = extract_description(content)
      return assert.equals("Description to the end.", result)
    end
    it("extracts description that goes to EOF", _7_)
    local function _8_()
      local content = "# Title\n\n## Description\n\n## Tasks\n"
      local extract_description = parser["extract-description"]
      local result = extract_description(content)
      return assert.equals("", result)
    end
    it("handles empty description section", _8_)
    local function _9_()
      local content = "# Title\n\n## Description\n\nSome text\n\n### Details\n\nMore details\n\n## Tasks\n"
      local extract_description = parser["extract-description"]
      local result = extract_description(content)
      assert.has_substring(result, "### Details")
      return assert.has_substring(result, "More details")
    end
    return it("allows ### subheadings inside description", _9_)
  end
  describe("extract-description", _3_)
  local function _10_()
    local function _11_()
      local content = "## Description\n\nDesc\n\n## Tasks\n\n- [ ] Task one <!-- task:1 complete:false -->\n\n## Comments\n"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      assert.equals(1, #result)
      assert.equals("Task one", result[1].description)
      return assert.is_false(result[1].complete)
    end
    it("extracts incomplete tasks", _11_)
    local function _12_()
      local content = "## Tasks\n\n- [x] Done task <!-- task:2 complete:true -->\n\n## Comments\n"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      assert.equals(1, #result)
      return assert.is_true(result[1].complete)
    end
    it("extracts complete tasks", _12_)
    local function _13_()
      local content = "## Tasks\n\n- [ ] Task <!-- task:12345 complete:false -->\n\n## Comments\n"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      return assert.equals(12345, result[1].id)
    end
    it("extracts task IDs", _13_)
    local function _14_()
      local content = "## Tasks\n\n- [ ] New task <!-- task:new complete:false -->\n\n## Comments\n"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      assert.is_nil(result[1].id)
      return assert.is_true(result[1].is_new)
    end
    it("handles new tasks without ID", _14_)
    local function _15_()
      local content = "# No tasks here"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      return assert.same({}, result)
    end
    it("returns empty array when no tasks section", _15_)
    local function _16_()
      local content = "## Tasks\n\n- [ ] First <!-- task:1 complete:false -->\n- [x] Second <!-- task:2 complete:true -->\n- [ ] Third <!-- task:3 complete:false -->\n\n## Comments\n"
      local extract_tasks = parser["extract-tasks"]
      local result = extract_tasks(content)
      return assert.equals(3, #result)
    end
    return it("extracts multiple tasks", _16_)
  end
  describe("extract-tasks", _10_)
  local function _17_()
    local function _18_()
      local content = "## Comments\n\n---\n**John Doe** \194\183 2026-01-10 10:30 <!-- comment:123 -->\n\nThis is my comment.\n\n## Local Notes\n"
      local extract_comments = parser["extract-comments"]
      local result = extract_comments(content)
      assert.equals(1, #result)
      assert.equals("John Doe", result[1].author)
      return assert.has_substring(result[1].text, "This is my comment")
    end
    it("extracts comment author and text", _18_)
    local function _19_()
      local content = "## Comments\n\n---\n**Author** \194\183 2026-01-10 10:30 <!-- comment:456 -->\n\nComment text\n\n## Local Notes\n"
      local extract_comments = parser["extract-comments"]
      local result = extract_comments(content)
      return assert.equals(456, result[1].id)
    end
    it("extracts comment IDs", _19_)
    local function _20_()
      local content = "# No comments"
      local extract_comments = parser["extract-comments"]
      local result = extract_comments(content)
      return assert.same({}, result)
    end
    return it("returns empty array when no comments section", _20_)
  end
  describe("extract-comments", _17_)
  local function _21_()
    local function _22_()
      local content = "# Title\n\n## Description\n\nSome desc\n\n## Local Notes\n\n<!-- This section is NOT synced to Shortcut -->\n\nMy custom notes here\n"
      local extract_local_notes = parser["extract-local-notes"]
      local result = extract_local_notes(content)
      assert.is_not_nil(result)
      assert.has_substring(result, "## Local Notes")
      return assert.has_substring(result, "My custom notes here")
    end
    it("extracts local notes section with user content", _22_)
    local function _23_()
      local content = "# Title\n\n## Description\n\nSome content\n"
      local extract_local_notes = parser["extract-local-notes"]
      local result = extract_local_notes(content)
      return assert.is_nil(result)
    end
    it("returns nil when no local notes section exists", _23_)
    local function _24_()
      local content = "# Title\n\n## Local Notes\n\n<!-- This section is NOT synced to Shortcut -->\n\n### My Heading\n\n- Item 1\n- Item 2\n\nSome paragraph.\n"
      local extract_local_notes = parser["extract-local-notes"]
      local result = extract_local_notes(content)
      assert.has_substring(result, "### My Heading")
      assert.has_substring(result, "- Item 1")
      return assert.has_substring(result, "Some paragraph.")
    end
    it("preserves multi-line local notes content", _24_)
    local function _25_()
      local content = "# Title\n\n## Local Notes\n\n<!-- This section is NOT synced to Shortcut -->\n"
      local extract_local_notes = parser["extract-local-notes"]
      local result = extract_local_notes(content)
      assert.is_not_nil(result)
      return assert.has_substring(result, "## Local Notes")
    end
    return it("extracts blank local notes template", _25_)
  end
  describe("extract-local-notes", _21_)
  local function _26_()
    local function _27_()
      local content = t["sample-markdown"]()
      local result = parser.parse(content)
      assert.is_not_nil(result.frontmatter)
      assert.is_not_nil(result.description)
      assert.is_table(result.tasks)
      return assert.is_table(result.comments)
    end
    it("parses complete markdown file", _27_)
    local function _28_()
      local content = t["sample-markdown"]()
      local result = parser.parse(content)
      assert.equals(12345, result.frontmatter.shortcut_id)
      return assert.equals("story", result.frontmatter.shortcut_type)
    end
    it("extracts frontmatter fields", _28_)
    local function _29_()
      local content = t["sample-markdown"]()
      local result = parser.parse(content)
      assert.is_not_nil(result.local_notes)
      return assert.has_substring(result.local_notes, "## Local Notes")
    end
    return it("includes local_notes in parsed result", _29_)
  end
  describe("parse", _26_)
  local function _30_()
    local function _31_()
      local notify = require("longway.ui.notify")
      local original_warn = notify.warn
      local function _32_()
      end
      notify.warn = _32_
      local content = "# Title\n\n<!-- BEGIN SHORTCUT SYNC:description -->\nLegacy description.\n<!-- END SHORTCUT SYNC:description -->"
      local extract_description = parser["extract-description"]
      local result = extract_description(content)
      assert.equals("Legacy description.", result)
      notify.warn = original_warn
      return nil
    end
    return it("falls back to legacy sync markers when headers not found", _31_)
  end
  describe("legacy sync marker fallback", _30_)
  local function _33_()
    local function _34_()
      local content = t["sample-markdown"]()
      local get_shortcut_id = parser["get-shortcut-id"]
      local result = get_shortcut_id(content)
      return assert.equals(12345, result)
    end
    it("extracts ID from frontmatter", _34_)
    local function _35_()
      local content = "# No frontmatter"
      local get_shortcut_id = parser["get-shortcut-id"]
      local result = get_shortcut_id(content)
      return assert.is_nil(result)
    end
    return it("returns nil when no ID", _35_)
  end
  describe("get-shortcut-id", _33_)
  local function _36_()
    local function _37_()
      local content = t["sample-markdown"]()
      local is_longway_file = parser["is-longway-file"]
      return assert.is_true(is_longway_file(content))
    end
    it("returns true for longway files", _37_)
    local function _38_()
      local content = "# Regular File\n\nJust content."
      local is_longway_file = parser["is-longway-file"]
      return assert.is_false(is_longway_file(content))
    end
    return it("returns false for regular markdown", _38_)
  end
  return describe("is-longway-file", _36_)
end
return describe("longway.markdown.parser", _1_)
