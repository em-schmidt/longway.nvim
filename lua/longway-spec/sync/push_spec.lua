-- [nfnl] fnl/longway-spec/sync/push_spec.fnl
local t = require("longway-spec.init")
local push = require("longway.sync.push")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(push["push-current-buffer"])
    end
    it("exports push-current-buffer function", _4_)
    local function _5_()
      return assert.is_function(push["push-story"])
    end
    it("exports push-story function", _5_)
    local function _6_()
      return assert.is_function(push["push-file"])
    end
    return it("exports push-file function", _6_)
  end
  describe("module structure", _3_)
  local function _7_()
    local function _8_()
      return assert.is_function(push["push-story"])
    end
    return it("requires story-id and parsed arguments", _8_)
  end
  return describe("push-story", _7_)
end
return describe("longway.sync.push", _1_)
