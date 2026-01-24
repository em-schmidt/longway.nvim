-- [nfnl] fnl/longway-spec/api/client_spec.fnl
local t = require("longway-spec.init")
local client = require("longway.api.client")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(client.request)
    end
    it("exports request function", _4_)
    local function _5_()
      return assert.is_function(client.get)
    end
    it("exports get function", _5_)
    local function _6_()
      return assert.is_function(client.post)
    end
    it("exports post function", _6_)
    local function _7_()
      return assert.is_function(client.put)
    end
    it("exports put function", _7_)
    local function _8_()
      return assert.is_function(client.delete)
    end
    return it("exports delete function", _8_)
  end
  describe("module structure", _3_)
  local function _9_()
    local function _10_()
      t["setup-test-config"]({_resolved_token = nil})
      local config = require("longway.config")
      config.setup({_resolved_token = nil})
      return assert.is_function(client.get)
    end
    return it("returns error when no token configured", _10_)
  end
  return describe("request handling", _9_)
end
return describe("longway.api.client", _1_)
