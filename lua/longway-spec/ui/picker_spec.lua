-- [nfnl] Compiled from fnl/longway-spec/ui/picker_spec.fnl by https://github.com/Olical/nfnl, do not edit.
local t = require("longway-spec.init")
require("longway-spec.assertions")
local picker = require("longway.ui.picker")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      local check_snacks = picker["check-snacks"]
      return assert.is_function(check_snacks)
    end
    it("exports check-snacks function", _4_)
    local function _5_()
      local pick_stories = picker["pick-stories"]
      return assert.is_function(pick_stories)
    end
    it("exports pick-stories function", _5_)
    local function _6_()
      local pick_epics = picker["pick-epics"]
      return assert.is_function(pick_epics)
    end
    it("exports pick-epics function", _6_)
    local function _7_()
      local pick_presets = picker["pick-presets"]
      return assert.is_function(pick_presets)
    end
    it("exports pick-presets function", _7_)
    local function _8_()
      local pick_modified = picker["pick-modified"]
      return assert.is_function(pick_modified)
    end
    it("exports pick-modified function", _8_)
    local function _9_()
      local pick_comments = picker["pick-comments"]
      return assert.is_function(pick_comments)
    end
    return it("exports pick-comments function", _9_)
  end
  describe("module structure", _3_)
  local function _10_()
    local function _11_()
      local check_snacks = picker["check-snacks"]
      local result = check_snacks()
      return assert.is_boolean(result)
    end
    it("returns a boolean", _11_)
    local function _12_()
      return assert.is_false(picker["check-snacks"]())
    end
    return it("returns false when snacks is not installed", _12_)
  end
  describe("check-snacks", _10_)
  local function _13_()
    local function _14_()
      return assert.equals("", picker.truncate(nil, 10))
    end
    it("returns empty string for nil input", _14_)
    local function _15_()
      return assert.equals("hello", picker.truncate("hello", 10))
    end
    it("returns original string when shorter than max", _15_)
    local function _16_()
      return assert.equals("hello", picker.truncate("hello", 5))
    end
    it("returns original string when exactly max length", _16_)
    local function _17_()
      return assert.equals("hel...", picker.truncate("hello world", 6))
    end
    it("truncates and appends ... when longer than max", _17_)
    local function _18_()
      return assert.equals("", picker.truncate("", 10))
    end
    return it("handles empty string", _18_)
  end
  describe("truncate", _13_)
  local function _19_()
    local function _20_()
      return assert.equals("", picker["first-line"](nil))
    end
    it("returns empty string for nil input", _20_)
    local function _21_()
      return assert.equals("hello", picker["first-line"]("hello"))
    end
    it("returns the only line of a single-line string", _21_)
    local function _22_()
      return assert.equals("first", picker["first-line"]("first\nsecond\nthird"))
    end
    it("returns first line of multi-line string", _22_)
    local function _23_()
      return assert.equals("hello", picker["first-line"]("  hello  "))
    end
    it("trims surrounding whitespace", _23_)
    local function _24_()
      return assert.equals("", picker["first-line"](""))
    end
    return it("handles empty string", _24_)
  end
  describe("first-line", _19_)
  local function _25_()
    local function _26_()
      local find_local_file = picker["find-local-file"]
      local result = find_local_file(99999, "story")
      return assert.is_nil(result)
    end
    it("returns nil when no matching file exists", _26_)
    local function _27_()
      local stories_dir = "/tmp/longway-test/stories"
      vim.fn.mkdir(stories_dir, "p")
      local filepath = (stories_dir .. "/12345-test-story.md")
      local f = io.open(filepath, "w")
      f:write("test")
      f:close()
      do
        local result = picker["find-local-file"](12345, "story")
        assert.equals(filepath, result)
      end
      return os.remove(filepath)
    end
    it("finds a story file by shortcut_id", _27_)
    local function _28_()
      local epics_dir = "/tmp/longway-test/epics"
      vim.fn.mkdir(epics_dir, "p")
      local filepath = (epics_dir .. "/99999-test-epic.md")
      local f = io.open(filepath, "w")
      f:write("test")
      f:close()
      do
        local result = picker["find-local-file"](99999, "epic")
        assert.equals(filepath, result)
      end
      return os.remove(filepath)
    end
    return it("finds an epic file by shortcut_id", _28_)
  end
  describe("find-local-file", _25_)
  local function _29_()
    local function _30_()
      t["setup-test-config"]({})
      local layout = picker["build-picker-layout"]()
      assert.is_table(layout)
      assert.equals("default", layout.preset)
      return assert.is_true(layout.preview)
    end
    it("returns default layout when no picker config", _30_)
    local function _31_()
      t["setup-test-config"]({picker = {layout = "ivy", preview = true}})
      local layout = picker["build-picker-layout"]()
      return assert.equals("ivy", layout.preset)
    end
    it("respects custom layout setting", _31_)
    local function _32_()
      t["setup-test-config"]({picker = {layout = "default", preview = false}})
      local layout = picker["build-picker-layout"]()
      return assert.is_false(layout.preview)
    end
    return it("respects preview=false setting", _32_)
  end
  return describe("build-picker-layout", _29_)
end
return describe("longway.ui.picker", _1_)