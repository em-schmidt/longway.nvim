-- [nfnl] fnl/longway-spec/cache/store_spec.fnl
local t = require("longway-spec.init")
local cache = require("longway.cache.store")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(cache.get)
    end
    it("is a function", _4_)
    local function _5_()
      local result = cache.get("nonexistent")
      return assert.is_true(result.expired)
    end
    return it("returns expired for missing cache", _5_)
  end
  describe("get", _3_)
  local function _6_()
    local function _7_()
      return assert.is_function(cache.set)
    end
    return it("is a function", _7_)
  end
  describe("set", _6_)
  local function _8_()
    local function _9_()
      return assert.is_function(cache.invalidate)
    end
    it("is a function", _9_)
    local function _10_()
      local result = cache.invalidate("members")
      return assert.is_true(result.ok)
    end
    return it("returns ok for any cache type", _10_)
  end
  describe("invalidate", _8_)
  local function _11_()
    local function _12_()
      return assert.is_function(cache["invalidate-all"])
    end
    it("is a function", _12_)
    local function _13_()
      local invalidate_all = cache["invalidate-all"]
      local result = invalidate_all()
      return assert.is_true(result.ok)
    end
    return it("returns ok", _13_)
  end
  describe("invalidate-all", _11_)
  local function _14_()
    local function _15_()
      return assert.is_function(cache["get-or-fetch"])
    end
    it("is a function", _15_)
    local function _16_()
      cache.invalidate("members")
      local fetch_called = false
      local fetch_fn
      local function _17_()
        fetch_called = true
        return {ok = true, data = {test = true}}
      end
      fetch_fn = _17_
      local get_or_fetch = cache["get-or-fetch"]
      get_or_fetch("members", fetch_fn)
      return assert.is_true(fetch_called)
    end
    return it("calls fetch function when cache is empty", _16_)
  end
  describe("get-or-fetch", _14_)
  local function _18_()
    local function _19_()
      return assert.is_function(cache["get-age"])
    end
    it("is a function", _19_)
    local function _20_()
      local get_age = cache["get-age"]
      local age = get_age("nonexistent")
      return assert.is_nil(age)
    end
    return it("returns nil for missing cache", _20_)
  end
  describe("get-age", _18_)
  local function _21_()
    local function _22_()
      return assert.is_function(cache["get-status"])
    end
    it("is a function", _22_)
    local function _23_()
      local get_status = cache["get-status"]
      local status = get_status()
      return assert.is_table(status)
    end
    return it("returns a table", _23_)
  end
  describe("get-status", _21_)
  local function _24_()
    local function _25_()
      return assert.is_function(cache.refresh)
    end
    return it("is a function", _25_)
  end
  return describe("refresh", _24_)
end
return describe("longway.cache.store", _1_)
