-- [nfnl] fnl/longway-spec/markdown/frontmatter_spec.fnl
require("longway-spec.assertions")
local frontmatter = require("longway.markdown.frontmatter")
local function _1_()
  local function _2_()
    local function _3_()
      local content = "---\nshortcut_id: 12345\nstory_type: feature\n---\n\n# Content"
      local result = frontmatter.parse(content)
      assert.equals(12345, result.frontmatter.shortcut_id)
      return assert.equals("feature", result.frontmatter.story_type)
    end
    it("parses simple key-value pairs", _3_)
    local function _4_()
      local content = "---\nenabled: true\ndisabled: false\n---\nbody"
      local result = frontmatter.parse(content)
      assert.is_true(result.frontmatter.enabled)
      return assert.is_false(result.frontmatter.disabled)
    end
    it("parses boolean values", _4_)
    local function _5_()
      local content = "---\ntitle: \"Hello: World\"\n---\nbody"
      local result = frontmatter.parse(content)
      return assert.equals("Hello: World", result.frontmatter.title)
    end
    it("parses quoted strings", _5_)
    local function _6_()
      local content = "---\nid: 123\n---\n\n# Title\n\nBody content here."
      local result = frontmatter.parse(content)
      assert.has_substring(result.body, "# Title")
      return assert.has_substring(result.body, "Body content here.")
    end
    it("extracts body after frontmatter", _6_)
    local function _7_()
      local content = "# No Frontmatter\n\nJust content."
      local result = frontmatter.parse(content)
      assert.same({}, result.frontmatter)
      return assert.equals(content, result.body)
    end
    it("returns empty frontmatter when not present", _7_)
    local function _8_()
      local content = "---\nid: 123\nname: test\n---\nbody"
      local result = frontmatter.parse(content)
      assert.is_not_nil(result.raw_frontmatter)
      return assert.has_substring(result.raw_frontmatter, "id: 123")
    end
    it("returns raw frontmatter string", _8_)
    local function _9_()
      local content = "---\nid: 123\n---\n\n# Title"
      local result = frontmatter.parse(content)
      return assert.equals("# Title", result.body)
    end
    it("strips leading and trailing whitespace from body", _9_)
    local function _10_()
      local initial_fm = {shortcut_id = 12345, story_type = "feature"}
      local generated = frontmatter.generate(initial_fm)
      local initial_content = (generated .. "\n\n" .. "# Test Story")
      local parsed1 = frontmatter.parse(initial_content)
      local regenerated = frontmatter.generate(parsed1.frontmatter)
      local updated_content = (regenerated .. "\n\n" .. parsed1.body)
      local parsed2 = frontmatter.parse(updated_content)
      assert.equals(parsed1.body, parsed2.body)
      local pattern = "%-%-%-\n\n# Test Story"
      return assert.is_not_nil(string.find(updated_content, pattern, 1, true))
    end
    return it("prevents blank line accumulation on parse-render cycles", _10_)
  end
  describe("parse", _2_)
  local function _11_()
    local function _12_()
      local data = {shortcut_id = 12345, story_type = "feature"}
      local result = frontmatter.generate(data)
      assert.has_frontmatter(result)
      return assert.has_substring(result, "shortcut_id: 12345")
    end
    it("generates valid YAML frontmatter", _12_)
    local function _13_()
      local data = {name = "Test Story"}
      local result = frontmatter.generate(data)
      return assert.has_substring(result, "name: Test Story")
    end
    it("handles string values", _13_)
    local function _14_()
      local data = {enabled = true, disabled = false}
      local result = frontmatter.generate(data)
      assert.has_substring(result, "enabled: true")
      return assert.has_substring(result, "disabled: false")
    end
    it("handles boolean values", _14_)
    local function _15_()
      local data = {count = 42, estimate = 3.5}
      local result = frontmatter.generate(data)
      return assert.has_substring(result, "count: 42")
    end
    it("handles numeric values", _15_)
    local function _16_()
      local data = {name = "Test", _internal = "secret"}
      local result = frontmatter.generate(data)
      assert.has_substring(result, "name: Test")
      return assert.is_nil(string.find(result, "_internal"))
    end
    it("skips internal fields starting with underscore", _16_)
    local function _17_()
      local data = {labels = {"bug", "urgent"}}
      local result = frontmatter.generate(data)
      assert.has_substring(result, "labels:")
      assert.has_substring(result, "- bug")
      return assert.has_substring(result, "- urgent")
    end
    it("handles array values", _17_)
    local function _18_()
      local data = {shortcut_id = 12345, estimate = vim.NIL, state = "active"}
      local result = frontmatter.generate(data)
      assert.has_substring(result, "shortcut_id: 12345")
      assert.has_substring(result, "state: active")
      return assert.is_nil(string.find(result, "estimate"))
    end
    it("omits vim.NIL values from output", _18_)
    local function _19_()
      local data = {stats = {num_stories = 10, num_points = vim.NIL}}
      local result = frontmatter.generate(data)
      assert.has_substring(result, "num_stories: 10")
      return assert.is_nil(string.find(result, "num_points"))
    end
    it("omits vim.NIL values in nested object fields", _19_)
    local function _20_()
      local data = {items = {"keep", vim.NIL, "also_keep"}}
      local result = frontmatter.generate(data)
      assert.has_substring(result, "- keep")
      return assert.has_substring(result, "- also_keep")
    end
    it("omits vim.NIL items in arrays", _20_)
    local function _21_()
      local data = {owners = {{name = "Alice", id = "uuid-1"}, {name = vim.NIL, id = "uuid-2"}}}
      local result = frontmatter.generate(data)
      assert.has_substring(result, "name: Alice")
      assert.has_substring(result, "id: uuid-1")
      return assert.has_substring(result, "id: uuid-2")
    end
    return it("omits vim.NIL values in array-of-objects", _21_)
  end
  return describe("generate", _11_)
end
return describe("longway.markdown.frontmatter", _1_)
