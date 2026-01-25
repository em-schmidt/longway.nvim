-- [nfnl] fnl/longway-spec/api/search_spec.fnl
local t = require("longway-spec.init")
local search = require("longway.api.search")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      return assert.is_function(search["search-stories"])
    end
    return it("is a function", _4_)
  end
  describe("search-stories", _3_)
  local function _5_()
    local function _6_()
      return assert.is_function(search["search-stories-all"])
    end
    return it("is a function", _6_)
  end
  describe("search-stories-all", _5_)
  local function _7_()
    local function _8_()
      return assert.is_function(search["search-epics"])
    end
    return it("is a function", _8_)
  end
  describe("search-epics", _7_)
  local function _9_()
    local function _10_()
      return assert.is_function(search["build-query"])
    end
    it("is a function", _10_)
    local function _11_()
      local build_query = search["build-query"]
      local query = build_query({owner = "me", type = "feature"})
      assert.is_string(query)
      assert.truthy(string.find(query, "owner:me"))
      return assert.truthy(string.find(query, "type:feature"))
    end
    it("builds query from simple filters", _11_)
    local function _12_()
      local build_query = search["build-query"]
      local query = build_query({state = "In Progress"})
      return assert.truthy(string.find(query, "\"In Progress\""))
    end
    return it("quotes values with spaces", _12_)
  end
  describe("build-query", _9_)
  local function _13_()
    local function _14_()
      return assert.is_function(search["parse-query"])
    end
    it("is a function", _14_)
    local function _15_()
      local parse_query = search["parse-query"]
      local result = parse_query("owner:me state:started")
      assert.is_table(result)
      return assert.is_table(result.params)
    end
    return it("parses key:value pairs", _15_)
  end
  return describe("parse-query", _13_)
end
return describe("longway.api.search", _1_)
