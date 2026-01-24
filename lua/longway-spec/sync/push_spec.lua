local t = require("longway-spec.init")
local push = require("longway.sync.push")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(push.push_current_buffer)
    end
    it("exports push_current_buffer function", _4_)
    local function _5_()
      return assert.is_function(push.push_story)
    end
    it("exports push_story function", _5_)
    local function _6_()
      return assert.is_function(push.push_file)
    end
    return it("exports push_file function", _6_)
  end
  describe("module structure", _3_)
  local function _7_()
    local function _8_()
      return assert.is_function(push.push_story)
    end
    return it("requires story_id and parsed arguments", _8_)
  end
  return describe("push_story", _7_)
end
return describe("longway.sync.push", _1_)
