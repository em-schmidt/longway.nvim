local t = require("longway-spec.init")
local pull = require("longway.sync.pull")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(pull.pull_story)
    end
    it("exports pull_story function", _4_)
    local function _5_()
      return assert.is_function(pull.pull_story_to_buffer)
    end
    it("exports pull_story_to_buffer function", _5_)
    local function _6_()
      return assert.is_function(pull.refresh_current_buffer)
    end
    return it("exports refresh_current_buffer function", _6_)
  end
  describe("module structure", _3_)
  local function _7_()
    local function _8_()
      return assert.is_function(pull.pull_story)
    end
    return it("requires a story ID argument", _8_)
  end
  return describe("pull_story", _7_)
end
return describe("longway.sync.pull", _1_)
