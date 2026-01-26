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
    it("returns ok true with empty comments list", _11_)
    local function _12_()
      local original_create = comments.create
      local counter = {n = 0}
      local function _13_(story_id, data)
        counter.n = (1 + counter.n)
        return {ok = true, data = {id = counter.n, text = data.text}}
      end
      comments.create = _13_
      do
        local batch_create = comments["batch-create"]
        local result = batch_create(12345, {{text = "First"}, {text = "Second"}})
        assert.is_true(result.ok)
        assert.equals(2, #result.created)
        assert.equals(0, #result.errors)
        assert.equals("First", result.created[1].text)
        assert.equals("Second", result.created[2].text)
      end
      comments.create = original_create
      return nil
    end
    it("creates comments sequentially and collects results", _12_)
    local function _14_()
      local original_create = comments.create
      local counter = {n = 0}
      local function _15_(story_id, data)
        counter.n = (1 + counter.n)
        if (counter.n == 2) then
          return {error = "Server error", ok = false}
        else
          return {ok = true, data = {id = counter.n, text = data.text}}
        end
      end
      comments.create = _15_
      do
        local batch_create = comments["batch-create"]
        local result = batch_create(12345, {{text = "OK"}, {text = "Fail"}, {text = "Also OK"}})
        assert.is_false(result.ok)
        assert.equals(2, #result.created)
        assert.equals(1, #result.errors)
        assert.has_substring(result.errors[1], "Comment 2")
      end
      comments.create = original_create
      return nil
    end
    return it("aggregates errors from failed creates", _14_)
  end
  describe("batch-create", _10_)
  local function _17_()
    local function _18_()
      local batch_delete = comments["batch-delete"]
      local result = batch_delete(12345, {})
      assert.is_true(result.ok)
      assert.equals(0, #result.deleted)
      return assert.equals(0, #result.errors)
    end
    it("returns ok true with empty comment-ids list", _18_)
    local function _19_()
      local original_delete = comments.delete
      local function _20_(story_id, comment_id)
        return {ok = true}
      end
      comments.delete = _20_
      do
        local batch_delete = comments["batch-delete"]
        local result = batch_delete(12345, {101, 102, 103})
        assert.is_true(result.ok)
        assert.equals(3, #result.deleted)
        assert.equals(0, #result.errors)
      end
      comments.delete = original_delete
      return nil
    end
    it("deletes comments sequentially and collects results", _19_)
    local function _21_()
      local original_delete = comments.delete
      local function _22_(story_id, comment_id)
        if (comment_id == 102) then
          return {error = "Not found", ok = false}
        else
          return {ok = true}
        end
      end
      comments.delete = _22_
      do
        local batch_delete = comments["batch-delete"]
        local result = batch_delete(12345, {101, 102, 103})
        assert.is_false(result.ok)
        assert.equals(2, #result.deleted)
        assert.equals(1, #result.errors)
        assert.has_substring(result.errors[1], "102")
      end
      comments.delete = original_delete
      return nil
    end
    return it("aggregates errors from failed deletes", _21_)
  end
  return describe("batch-delete", _17_)
end
return describe("longway.api.comments", _1_)
