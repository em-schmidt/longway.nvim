-- [nfnl] fnl/longway-spec/ui/confirm_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local confirm = require("longway.ui.confirm")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(confirm.confirm)
    end
    it("exports confirm function", _4_)
    local function _5_()
      return assert.is_function(confirm["confirm-sync"])
    end
    it("exports confirm-sync function", _5_)
    local function _6_()
      return assert.is_function(confirm["confirm-delete-tasks"])
    end
    it("exports confirm-delete-tasks function", _6_)
    local function _7_()
      return assert.is_function(confirm["confirm-delete-task-ids"])
    end
    it("exports confirm-delete-task-ids function", _7_)
    local function _8_()
      return assert.is_function(confirm["confirm-overwrite"])
    end
    it("exports confirm-overwrite function", _8_)
    local function _9_()
      return assert.is_function(confirm["prompt-delete-or-skip"])
    end
    return it("exports prompt-delete-or-skip function", _9_)
  end
  return describe("module structure", _3_)
end
return describe("longway.ui.confirm", _1_)
