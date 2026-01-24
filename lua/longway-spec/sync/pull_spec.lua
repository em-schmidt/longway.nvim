-- [nfnl] fnl/longway-spec/sync/pull_spec.fnl
local t = require("longway-spec.init")
local pull = require("longway.sync.pull")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(pull["pull-story"])
    end
    it("exports pull-story function", _4_)
    local function _5_()
      return assert.is_function(pull["pull-story-to-buffer"])
    end
    it("exports pull-story-to-buffer function", _5_)
    local function _6_()
      return assert.is_function(pull["refresh-current-buffer"])
    end
    return it("exports refresh-current-buffer function", _6_)
  end
  describe("module structure", _3_)
  local function _7_()
    local function _8_()
      return assert.is_function(pull["pull-story"])
    end
    return it("requires a story ID argument", _8_)
  end
  return describe("pull-story", _7_)
end
return describe("longway.sync.pull", _1_)
