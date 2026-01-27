-- [nfnl] fnl/longway-spec/sync/resolve_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local resolve = require("longway.sync.resolve")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      local resolve_manual = resolve["resolve-manual"]
      return assert.is_function(resolve_manual)
    end
    it("inserts conflict markers into description section", _4_)
    local function _5_()
      return assert.is_function(resolve.resolve)
    end
    it("exports resolve function", _5_)
    local function _6_()
      local resolve_local = resolve["resolve-local"]
      return assert.is_function(resolve_local)
    end
    it("exports resolve-local function", _6_)
    local function _7_()
      local resolve_remote = resolve["resolve-remote"]
      return assert.is_function(resolve_remote)
    end
    return it("exports resolve-remote function", _7_)
  end
  return describe("resolve-manual", _3_)
end
return describe("longway.sync.resolve", _1_)
