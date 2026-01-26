-- [nfnl] fnl/longway-spec/markdown/comments_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local comments_md = require("longway.markdown.comments")
local hash = require("longway.util.hash")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      local block = "**Test Author** \194\183 2026-01-10 10:30 <!-- comment:11111 -->\n\nThis is a comment."
      local result = comments_md["parse-block"](block)
      assert.is_not_nil(result)
      assert.equals("Test Author", result.author)
      assert.equals("2026-01-10 10:30", result.timestamp)
      assert.equals(11111, result.id)
      assert.is_false(result.is_new)
      return assert.equals("This is a comment.", result.text)
    end
    it("parses a valid comment block", _4_)
    local function _5_()
      local block = "**My Name** \194\183 2026-01-20 15:00 <!-- comment:new -->\n\nBrand new comment."
      local result = comments_md["parse-block"](block)
      assert.is_not_nil(result)
      assert.equals("My Name", result.author)
      assert.is_nil(result.id)
      assert.is_true(result.is_new)
      return assert.equals("Brand new comment.", result.text)
    end
    it("parses a new comment block", _5_)
    local function _6_()
      local block = "Just plain text without metadata"
      local result = comments_md["parse-block"](block)
      return assert.is_nil(result)
    end
    it("returns nil for invalid block", _6_)
    local function _7_()
      local block = "**Author** \194\183 2026-01-10 10:30 <!-- comment:222 -->\n\nLine one\nLine two\nLine three"
      local result = comments_md["parse-block"](block)
      assert.is_not_nil(result)
      assert.has_substring(result.text, "Line one")
      assert.has_substring(result.text, "Line two")
      return assert.has_substring(result.text, "Line three")
    end
    it("handles multi-line comment text", _7_)
    local function _8_()
      local block = "**Author** \194\183 2026-01-10 10:30 <!-- comment:333 -->"
      local result = comments_md["parse-block"](block)
      assert.is_not_nil(result)
      return assert.equals("", result.text)
    end
    return it("handles empty comment text", _8_)
  end
  describe("parse-block", _3_)
  local function _9_()
    local function _10_()
      local content = "---\n**Author A** \194\183 2026-01-10 10:00 <!-- comment:111 -->\n\nFirst comment.\n\n---\n**Author B** \194\183 2026-01-10 11:00 <!-- comment:222 -->\n\nSecond comment."
      local result = comments_md["parse-section"](content)
      assert.equals(2, #result)
      assert.equals("Author A", result[1].author)
      return assert.equals("Author B", result[2].author)
    end
    it("parses multiple comments", _10_)
    local function _11_()
      local result = comments_md["parse-section"]("")
      return assert.equals(0, #result)
    end
    it("handles empty content", _11_)
    local function _12_()
      local result = comments_md["parse-section"]("---\n---\n---")
      return assert.equals(0, #result)
    end
    return it("handles content with only separators", _12_)
  end
  describe("parse-section", _9_)
  local function _13_()
    local function _14_()
      local cmt = {id = 123, author = "John", timestamp = "2026-01-10 10:30", text = "Hello world", is_new = false}
      local result = comments_md["render-comment"](cmt)
      assert.has_substring(result, "---")
      assert.has_substring(result, "**John**")
      assert.has_substring(result, "2026-01-10 10:30")
      assert.has_substring(result, "comment:123")
      return assert.has_substring(result, "Hello world")
    end
    it("renders a comment with all fields", _14_)
    local function _15_()
      local cmt = {author = "Jane", timestamp = "2026-01-20 15:00", text = "New!", is_new = true}
      local result = comments_md["render-comment"](cmt)
      assert.has_substring(result, "comment:new")
      assert.has_substring(result, "**Jane**")
      return assert.has_substring(result, "New!")
    end
    return it("renders a new comment", _15_)
  end
  describe("render-comment", _13_)
  local function _16_()
    local function _17_()
      local cmts = {{id = 1, author = "A", timestamp = "2026-01-01 10:00", text = "First", is_new = false}, {id = 2, author = "B", timestamp = "2026-01-02 10:00", text = "Second", is_new = false}}
      local result = comments_md["render-comments"](cmts)
      assert.has_substring(result, "First")
      return assert.has_substring(result, "Second")
    end
    it("renders multiple comments", _17_)
    local function _18_()
      assert.equals("", comments_md["render-comments"]({}))
      return assert.equals("", comments_md["render-comments"](nil))
    end
    return it("returns empty string for no comments", _18_)
  end
  describe("render-comments", _16_)
  local function _19_()
    local function _20_()
      local cmts = {{id = 1, author = "A", timestamp = "2026-01-01 10:00", text = "Comment", is_new = false}}
      local result = comments_md["render-section"](cmts)
      assert.has_substring(result, "<!-- BEGIN SHORTCUT SYNC:comments -->")
      assert.has_substring(result, "<!-- END SHORTCUT SYNC:comments -->")
      return assert.has_substring(result, "Comment")
    end
    return it("wraps comments in sync markers", _20_)
  end
  describe("render-section", _19_)
  local function _21_()
    local function _22_()
      local local_cmt = {id = 1, text = "Updated text"}
      local remote_cmt = {id = 1, text = "Original text"}
      local comment_changed_3f = comments_md["comment-changed?"]
      return assert.is_true(comment_changed_3f(local_cmt, remote_cmt))
    end
    it("detects text change", _22_)
    local function _23_()
      local local_cmt = {id = 1, text = "Same text"}
      local remote_cmt = {id = 1, text = "Same text"}
      local comment_changed_3f = comments_md["comment-changed?"]
      return assert.is_false(comment_changed_3f(local_cmt, remote_cmt))
    end
    it("returns false for same text", _23_)
    local function _24_()
      local local_cmt = {id = 1, text = "  Text  "}
      local remote_cmt = {id = 1, text = "Text"}
      local comment_changed_3f = comments_md["comment-changed?"]
      return assert.is_false(comment_changed_3f(local_cmt, remote_cmt))
    end
    it("ignores leading/trailing whitespace", _24_)
    local function _25_()
      local local_cmt = {id = 1, text = nil}
      local remote_cmt = {id = 1, text = nil}
      local comment_changed_3f = comments_md["comment-changed?"]
      return assert.is_false(comment_changed_3f(local_cmt, remote_cmt))
    end
    return it("handles nil text", _25_)
  end
  describe("comment-changed?", _21_)
  local function _26_()
    local function _27_()
      local cmts = {{id = 1, text = "First"}, {id = 2, text = "Second"}, {id = 3, text = "Third"}}
      local find_comment_by_id = comments_md["find-comment-by-id"]
      local result = find_comment_by_id(cmts, 2)
      assert.is_not_nil(result)
      return assert.equals("Second", result.text)
    end
    it("finds comment by ID", _27_)
    local function _28_()
      local cmts = {{id = 1, text = "First"}}
      local find_comment_by_id = comments_md["find-comment-by-id"]
      local result = find_comment_by_id(cmts, 999)
      return assert.is_nil(result)
    end
    return it("returns nil when not found", _28_)
  end
  describe("find-comment-by-id", _26_)
  local function _29_()
    local function _30_()
      local a = {{id = 1, text = "Hello"}}
      local b = {{id = 1, text = "Hello"}}
      local comments_equal_3f = comments_md["comments-equal?"]
      return assert.is_true(comments_equal_3f(a, b))
    end
    it("returns true for identical lists", _30_)
    local function _31_()
      local a = {{id = 1, text = "Hello"}}
      local b = {{id = 1, text = "Hello"}, {id = 2, text = "World"}}
      local comments_equal_3f = comments_md["comments-equal?"]
      return assert.is_false(comments_equal_3f(a, b))
    end
    it("returns false for different lengths", _31_)
    local function _32_()
      local a = {{id = 1, text = "Hello"}}
      local b = {{id = 1, text = "Goodbye"}}
      local comments_equal_3f = comments_md["comments-equal?"]
      return assert.is_false(comments_equal_3f(a, b))
    end
    it("returns false for different text", _32_)
    local function _33_()
      local comments_equal_3f = comments_md["comments-equal?"]
      return assert.is_true(comments_equal_3f({}, {}))
    end
    return it("returns true for two empty lists", _33_)
  end
  describe("comments-equal?", _29_)
  local function _34_()
    local function _35_()
      local original_block = "**Author** \194\183 2026-01-10 10:30 <!-- comment:456 -->\n\nSome text here"
      local parsed = comments_md["parse-block"](original_block)
      local rendered = comments_md["render-comment"](parsed)
      assert.has_substring(rendered, "comment:456")
      assert.has_substring(rendered, "**Author**")
      return assert.has_substring(rendered, "Some text here")
    end
    it("parsed comment can be re-rendered with same metadata", _35_)
    local function _36_()
      local cmts = {{id = 1, text = "Comment A"}, {id = 2, text = "Comment B"}}
      local hash1 = hash["comments-hash"](cmts)
      local hash2 = hash["comments-hash"](cmts)
      assert.equals(hash1, hash2)
      local modified = {{id = 1, text = "Changed"}, {id = 2, text = "Comment B"}}
      local hash3 = hash["comments-hash"](modified)
      return assert.is_not.equals(hash1, hash3)
    end
    return it("comments hash is stable across render-parse cycles", _36_)
  end
  return describe("round-trip parse-render", _34_)
end
return describe("longway.markdown.comments", _1_)
