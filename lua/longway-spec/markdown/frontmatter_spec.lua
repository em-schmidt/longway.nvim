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
    return it("returns raw frontmatter string", _8_)
  end
  describe("parse", _2_)
  local function _9_()
    local function _10_()
      local data = {shortcut_id = 12345, story_type = "feature"}
      local result = frontmatter.generate(data)
      assert.has_frontmatter(result)
      return assert.has_substring(result, "shortcut_id: 12345")
    end
    it("generates valid YAML frontmatter", _10_)
    local function _11_()
      local data = {name = "Test Story"}
      local result = frontmatter.generate(data)
      return assert.has_substring(result, "name: Test Story")
    end
    it("handles string values", _11_)
    local function _12_()
      local data = {enabled = true, disabled = false}
      local result = frontmatter.generate(data)
      assert.has_substring(result, "enabled: true")
      return assert.has_substring(result, "disabled: false")
    end
    it("handles boolean values", _12_)
    local function _13_()
      local data = {count = 42, estimate = 3.5}
      local result = frontmatter.generate(data)
      return assert.has_substring(result, "count: 42")
    end
    it("handles numeric values", _13_)
    local function _14_()
      local data = {name = "Test", _internal = "secret"}
      local result = frontmatter.generate(data)
      assert.has_substring(result, "name: Test")
      return assert.is_nil(string.find(result, "_internal"))
    end
    it("skips internal fields starting with underscore", _14_)
    local function _15_()
      local data = {labels = {"bug", "urgent"}}
      local result = frontmatter.generate(data)
      assert.has_substring(result, "labels:")
      assert.has_substring(result, "- bug")
      return assert.has_substring(result, "- urgent")
    end
    return it("handles array values", _15_)
  end
  return describe("generate", _9_)
end
return describe("longway.markdown.frontmatter", _1_)
