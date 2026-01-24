-- [nfnl] fnl/longway-spec/util/hash_spec.fnl
require("longway-spec.assertions")
local hash = require("longway.util.hash")
local function _1_()
  local function _2_()
    local function _3_()
      local result = hash.djb2("hello")
      return assert.is_valid_hash(result)
    end
    it("returns 8-character hex string", _3_)
    local function _4_()
      local hash1 = hash.djb2("test string")
      local hash2 = hash.djb2("test string")
      return assert.equals(hash1, hash2)
    end
    it("returns consistent hash for same input", _4_)
    local function _5_()
      local hash1 = hash.djb2("hello")
      local hash2 = hash.djb2("world")
      return assert.not_equals(hash1, hash2)
    end
    it("returns different hash for different input", _5_)
    local function _6_()
      local result = hash.djb2("")
      return assert.is_valid_hash(result)
    end
    it("handles empty string", _6_)
    local function _7_()
      local long_string = string.rep("a", 10000)
      local result = hash.djb2(long_string)
      return assert.is_valid_hash(result)
    end
    return it("handles long strings", _7_)
  end
  describe("djb2", _2_)
  local function _8_()
    local function _9_()
      local content_hash = hash["content-hash"]
      local hash1 = content_hash("line1\nline2")
      local hash2 = content_hash("line1\r\nline2")
      return assert.equals(hash1, hash2)
    end
    it("normalizes line endings", _9_)
    local function _10_()
      local content_hash = hash["content-hash"]
      local hash1 = content_hash("line1\nline2")
      local hash2 = content_hash("line1  \nline2  ")
      return assert.equals(hash1, hash2)
    end
    it("normalizes trailing whitespace", _10_)
    local function _11_()
      local content_hash = hash["content-hash"]
      local hash1 = content_hash("content")
      local hash2 = content_hash("  \n  content  \n  ")
      return assert.equals(hash1, hash2)
    end
    it("trims leading and trailing whitespace", _11_)
    local function _12_()
      local content_hash = hash["content-hash"]
      local result = content_hash("Test content")
      return assert.is_valid_hash(result)
    end
    return it("returns valid hash", _12_)
  end
  describe("content-hash", _8_)
  local function _13_()
    local function _14_()
      local content_hash = hash["content-hash"]
      local has_changed = hash["has-changed"]
      local content = "Test content"
      local stored_hash = content_hash(content)
      return assert.is_false(has_changed(stored_hash, content))
    end
    it("returns false when content matches hash", _14_)
    local function _15_()
      local content_hash = hash["content-hash"]
      local has_changed = hash["has-changed"]
      local old_content = "Original content"
      local new_content = "Modified content"
      local stored_hash = content_hash(old_content)
      return assert.is_true(has_changed(stored_hash, new_content))
    end
    it("returns true when content differs from hash", _15_)
    local function _16_()
      local content_hash = hash["content-hash"]
      local has_changed = hash["has-changed"]
      local content = "Test content"
      local stored_hash = content_hash(content)
      local content_with_whitespace = "  Test content  \n"
      return assert.is_false(has_changed(stored_hash, content_with_whitespace))
    end
    return it("handles whitespace normalization in comparison", _16_)
  end
  return describe("has-changed", _13_)
end
return describe("longway.util.hash", _1_)
