local t = require("longway-spec.init")
require("longway-spec.assertions")
local tasks = require("longway.api.tasks")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(tasks.create)
    end
    it("exports create function", _4_)
    local function _5_()
      return assert.is_function(tasks.update)
    end
    it("exports update function", _5_)
    local function _6_()
      return assert.is_function(tasks.delete)
    end
    it("exports delete function", _6_)
    local function _7_()
      return assert.is_function(tasks.get)
    end
    it("exports get function", _7_)
    local function _8_()
      return assert.is_function(tasks["batch-create"])
    end
    it("exports batch-create function", _8_)
    local function _9_()
      return assert.is_function(tasks["batch-update"])
    end
    it("exports batch-update function", _9_)
    local function _10_()
      return assert.is_function(tasks["batch-delete"])
    end
    return it("exports batch-delete function", _10_)
  end
  return describe("module structure", _3_)
end
return describe("longway.api.tasks", _1_)
