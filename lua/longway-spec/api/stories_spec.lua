-- [nfnl] fnl/longway-spec/api/stories_spec.fnl
local t = require("longway-spec.init")
local stories = require("longway.api.stories")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(stories.get)
    end
    it("is a function", _4_)
    local function _5_()
      return assert.is_function(stories.get)
    end
    return it("accepts story ID as argument", _5_)
  end
  describe("get", _3_)
  local function _6_()
    local function _7_()
      return assert.is_function(stories.update)
    end
    it("is a function", _7_)
    local function _8_()
      return assert.is_function(stories.update)
    end
    return it("accepts story ID and data", _8_)
  end
  describe("update", _6_)
  local function _9_()
    local function _10_()
      return assert.is_function(stories.search)
    end
    return it("is a function", _10_)
  end
  describe("search", _9_)
  local function _11_()
    local function _12_()
      return assert.is_function(stories["list-for-epic"])
    end
    return it("is a function", _12_)
  end
  describe("list-for-epic", _11_)
  local function _13_()
    local function _14_()
      return assert.is_function(stories["list-comments"])
    end
    return it("is a function", _14_)
  end
  describe("list-comments", _13_)
  local function _15_()
    local function _16_()
      return assert.is_function(stories["create-comment"])
    end
    return it("is a function", _16_)
  end
  describe("create-comment", _15_)
  local function _17_()
    local function _18_()
      return assert.is_function(stories["delete-comment"])
    end
    return it("is a function", _18_)
  end
  return describe("delete-comment", _17_)
end
return describe("longway.api.stories", _1_)
