-- [nfnl] fnl/longway-spec/util/slug_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local slug = require("longway.util.slug")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.equals("hello-world", slug.sanitize("Hello World"))
    end
    it("converts text to lowercase", _4_)
    local function _5_()
      return assert.equals("hello-world", slug.sanitize("hello world"))
    end
    it("replaces spaces with hyphens", _5_)
    local function _6_()
      return assert.equals("hello-world", slug.sanitize("hello_world"))
    end
    it("replaces underscores with hyphens", _6_)
    local function _7_()
      return assert.equals("fix-bug-123", slug.sanitize("Fix Bug #123!@$%"))
    end
    it("removes special characters", _7_)
    local function _8_()
      return assert.equals("hello-world", slug.sanitize("hello---world"))
    end
    it("collapses multiple hyphens", _8_)
    local function _9_()
      return assert.equals("hello", slug.sanitize("---hello"))
    end
    it("removes leading hyphens", _9_)
    local function _10_()
      return assert.equals("hello", slug.sanitize("hello---"))
    end
    it("removes trailing hyphens", _10_)
    local function _11_()
      return assert.equals("", slug.sanitize(""))
    end
    it("handles empty string", _11_)
    local function _12_()
      return assert.equals("", slug.sanitize("!@#$%^&*()"))
    end
    it("handles string with only special characters", _12_)
    local function _13_()
      return assert.equals("issue-42-fix", slug.sanitize("Issue 42 Fix"))
    end
    return it("preserves numbers", _13_)
  end
  describe("sanitize", _3_)
  local function _14_()
    local function _15_()
      return assert.equals("hello", slug.truncate("hello", 50))
    end
    it("returns short text unchanged", _15_)
    local function _16_()
      local result = slug.truncate("hello-world-this-is-long", 15)
      return assert.is_true((#result <= 15))
    end
    it("truncates text at max length", _16_)
    local function _17_()
      return assert.equals("hello", slug.truncate("hello-world", 10))
    end
    it("breaks at hyphen boundaries when possible", _17_)
    local function _18_()
      return assert.equals("hello", slug.truncate("helloworld", 5))
    end
    return it("returns exact truncation when no hyphen found", _18_)
  end
  describe("truncate", _14_)
  local function _19_()
    local function _20_()
      local result = slug.generate("My Story Title")
      assert.is_valid_slug(result)
      return assert.equals("my-story-title", result)
    end
    it("generates valid slug from title", _20_)
    local function _21_()
      t["setup-test-config"]({slug_max_length = 10})
      local result = slug.generate("This Is A Very Long Story Title")
      return assert.is_true((#result <= 10))
    end
    it("respects max length from config", _21_)
    local function _22_()
      local result = slug.generate("H\195\169llo W\195\182rld")
      return assert.is_valid_slug(result)
    end
    return it("handles unicode by removing non-ascii", _22_)
  end
  describe("generate", _19_)
  local function _23_()
    local function _24_()
      local result = slug["make-filename"](12345, "My Story")
      return assert.equals("12345-my-story.md", result)
    end
    it("generates filename with id and slug", _24_)
    local function _25_()
      t["setup-test-config"]({filename_template = "{slug}-{id}"})
      local result = slug["make-filename"](42, "Test Story")
      return assert.equals("test-story-42.md", result)
    end
    it("uses custom template from config", _25_)
    local function _26_()
      t["setup-test-config"]({filename_template = "{type}/{id}-{slug}"})
      local result = slug["make-filename"](123, "Epic Name", "epic")
      return assert.equals("epic/123-epic-name.md", result)
    end
    it("handles type placeholder", _26_)
    local function _27_()
      t["setup-test-config"]({filename_template = "{type}-{id}"})
      local result = slug["make-filename"](123, "Test")
      return assert.equals("story-123.md", result)
    end
    return it("defaults type to story", _27_)
  end
  return describe("make-filename", _23_)
end
return describe("longway.util.slug", _1_)
