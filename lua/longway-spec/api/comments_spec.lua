-- [nfnl] fnl/longway-spec/api/comments_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local comments = require("longway.api.comments")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(comments.list)
    end
    it("exports list function", _4_)
    local function _5_()
      return assert.is_function(comments.get)
    end
    it("exports get function", _5_)
    local function _6_()
      return assert.is_function(comments.create)
    end
    it("exports create function", _6_)
    local function _7_()
      return assert.is_function(comments.delete)
    end
    it("exports delete function", _7_)
    local function _8_()
      return assert.is_function(comments["batch-create"])
    end
    it("exports batch-create function", _8_)
    local function _9_()
      return assert.is_function(comments["batch-delete"])
    end
    return it("exports batch-delete function", _9_)
  end
  describe("module structure", _3_)
  local function _10_()
    local function _11_()
      local batch_create = comments["batch-create"]
      local result = batch_create(12345, {})
      assert.is_true(result.ok)
      assert.equals(0, #result.created)
      return assert.equals(0, #result.errors)
    end
    return it("returns ok true with empty comments list", _11_)
  end
  describe("batch-create", _10_)
  local function _12_()
    local function _13_()
      local batch_delete = comments["batch-delete"]
      local result = batch_delete(12345, {})
      assert.is_true(result.ok)
      assert.equals(0, #result.deleted)
      return assert.equals(0, #result.errors)
    end
    return it("returns ok true with empty comment-ids list", _13_)
  end
  return describe("batch-delete", _12_)
end
return describe("longway.api.comments", _1_)
