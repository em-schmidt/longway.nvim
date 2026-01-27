-- [nfnl] fnl/longway-spec/ui/picker_spec.fnl
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
    return it("returns a boolean", _11_)
  end
  return describe("check-snacks", _10_)
end
return describe("longway.ui.picker", _1_)
