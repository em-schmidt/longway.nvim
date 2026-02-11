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
      local block = "This is a bare comment without header."
      local result = comments_md["parse-block"](block)
      assert.is_not_nil(result)
      assert.is_nil(result.id)
      assert.is_nil(result.author)
      assert.is_nil(result.timestamp)
      assert.equals("This is a bare comment without header.", result.text)
      return assert.is_true(result.is_new)
    end
    it("parses a bare comment block as new", _6_)
    local function _7_()
      local block = "\n  \nActual comment text here."
      local result = comments_md["parse-block"](block)
      assert.is_not_nil(result)
      assert.equals("Actual comment text here.", result.text)
      return assert.is_true(result.is_new)
    end
    it("parses bare block with leading whitespace", _7_)
    local function _8_()
      local block = "   \n  \n  "
      local result = comments_md["parse-block"](block)
      return assert.is_nil(result)
    end
    it("returns nil for empty bare block", _8_)
    local function _9_()
      local block = "**Author** \194\183 2026-01-10 10:30 <!-- comment:222 -->\n\nLine one\nLine two\nLine three"
      local result = comments_md["parse-block"](block)
      assert.is_not_nil(result)
      assert.has_substring(result.text, "Line one")
      assert.has_substring(result.text, "Line two")
      return assert.has_substring(result.text, "Line three")
    end
    it("handles multi-line comment text", _9_)
    local function _10_()
      local block = "**Author** \194\183 2026-01-10 10:30 <!-- comment:333 -->"
      local result = comments_md["parse-block"](block)
      assert.is_not_nil(result)
      return assert.equals("", result.text)
    end
    it("handles empty comment text", _10_)
    local function _11_()
      local block = "---\n**Author** \194\183 2026-01-10 10:30 <!-- comment:456 -->\n\nClean text here."
      local result = comments_md["parse-block"](block)
      assert.is_not_nil(result)
      assert.equals("Author", result.author)
      assert.equals(456, result.id)
      return assert.equals("Clean text here.", result.text)
    end
    it("skips leading --- separator and produces clean text", _11_)
    local function _12_()
      local cmt = {id = 789, author = "Alice", timestamp = "2026-01-10 10:30", text = "Roundtrip test.", is_new = false}
      local rendered = comments_md["render-comment"](cmt)
      local reparsed = comments_md["parse-block"](rendered)
      assert.is_not_nil(reparsed)
      assert.equals("Alice", reparsed.author)
      assert.equals(789, reparsed.id)
      return assert.equals("Roundtrip test.", reparsed.text)
    end
    return it("render then parse roundtrip produces stable text", _12_)
  end
  describe("parse-block", _3_)
  local function _13_()
    local function _14_()
      local content = "---\n**Author A** \194\183 2026-01-10 10:00 <!-- comment:111 -->\n\nFirst comment.\n\n---\n**Author B** \194\183 2026-01-10 11:00 <!-- comment:222 -->\n\nSecond comment."
      local result = comments_md["parse-section"](content)
      assert.equals(2, #result)
      assert.equals("Author A", result[1].author)
      assert.equals("First comment.", result[1].text)
      assert.equals("Author B", result[2].author)
      return assert.equals("Second comment.", result[2].text)
    end
    it("parses multiple comments", _14_)
    local function _15_()
      local result = comments_md["parse-section"]("")
      return assert.equals(0, #result)
    end
    it("handles empty content", _15_)
    local function _16_()
      local result = comments_md["parse-section"]("---\n---\n---")
      return assert.equals(0, #result)
    end
    return it("handles content with only separators", _16_)
  end
  describe("parse-section", _13_)
  local function _17_()
    local function _18_()
      local cmt = {id = 123, author = "John", timestamp = "2026-01-10 10:30", text = "Hello world", is_new = false}
      local result = comments_md["render-comment"](cmt)
      assert.has_substring(result, "---")
      assert.has_substring(result, "**John**")
      assert.has_substring(result, "2026-01-10 10:30")
      assert.has_substring(result, "comment:123")
      return assert.has_substring(result, "Hello world")
    end
    it("renders a comment with all fields", _18_)
    local function _19_()
      local cmt = {author = "Jane", timestamp = "2026-01-20 15:00", text = "New!", is_new = true}
      local result = comments_md["render-comment"](cmt)
      assert.has_substring(result, "comment:new")
      assert.has_substring(result, "**Jane**")
      return assert.has_substring(result, "New!")
    end
    return it("renders a new comment", _19_)
  end
  describe("render-comment", _17_)
  local function _20_()
    local function _21_()
      local cmts = {{id = 1, author = "A", timestamp = "2026-01-01 10:00", text = "First", is_new = false}, {id = 2, author = "B", timestamp = "2026-01-02 10:00", text = "Second", is_new = false}}
      local result = comments_md["render-comments"](cmts)
      assert.has_substring(result, "First")
      return assert.has_substring(result, "Second")
    end
    it("renders multiple comments", _21_)
    local function _22_()
      assert.equals("", comments_md["render-comments"]({}))
      return assert.equals("", comments_md["render-comments"](nil))
    end
    it("returns empty string for no comments", _22_)
    local function _23_()
      local cmts = {{id = 3, author = "C", timestamp = "2026-01-03 10:00", text = "Newest", is_new = false}, {id = 1, author = "A", timestamp = "2026-01-01 10:00", text = "Oldest", is_new = false}, {id = 2, author = "B", timestamp = "2026-01-02 10:00", text = "Middle", is_new = false}}
      local result = comments_md["render-comments"](cmts)
      local oldest_pos = string.find(result, "Oldest")
      local middle_pos = string.find(result, "Middle")
      local newest_pos = string.find(result, "Newest")
      assert.is_true((oldest_pos < middle_pos))
      return assert.is_true((middle_pos < newest_pos))
    end
    it("sorts comments chronologically (oldest first)", _23_)
    local function _24_()
      local cmts = {{id = nil, author = nil, timestamp = nil, text = "New comment", is_new = true}, {id = 1, author = "A", timestamp = "2026-01-01 10:00", text = "Existing", is_new = false}}
      local result = comments_md["render-comments"](cmts)
      local existing_pos = string.find(result, "Existing")
      local new_pos = string.find(result, "New comment")
      return assert.is_true((existing_pos < new_pos))
    end
    return it("places new comments (nil timestamp) at the end", _24_)
  end
  describe("render-comments", _20_)
  local function _25_()
    local function _26_()
      local cmts = {{id = 1, author = "A", timestamp = "2026-01-01 10:00", text = "Comment", is_new = false}}
      local result = comments_md["render-section"](cmts)
      assert.has_substring(result, "<!-- BEGIN SHORTCUT SYNC:comments -->")
      assert.has_substring(result, "<!-- END SHORTCUT SYNC:comments -->")
      return assert.has_substring(result, "Comment")
    end
    return it("wraps comments in sync markers", _26_)
  end
  describe("render-section", _25_)
  local function _27_()
    local function _28_()
      local local_cmt = {id = 1, text = "Updated text"}
      local remote_cmt = {id = 1, text = "Original text"}
      local comment_changed_3f = comments_md["comment-changed?"]
      return assert.is_true(comment_changed_3f(local_cmt, remote_cmt))
    end
    it("detects text change", _28_)
    local function _29_()
      local local_cmt = {id = 1, text = "Same text"}
      local remote_cmt = {id = 1, text = "Same text"}
      local comment_changed_3f = comments_md["comment-changed?"]
      return assert.is_false(comment_changed_3f(local_cmt, remote_cmt))
    end
    it("returns false for same text", _29_)
    local function _30_()
      local local_cmt = {id = 1, text = "  Text  "}
      local remote_cmt = {id = 1, text = "Text"}
      local comment_changed_3f = comments_md["comment-changed?"]
      return assert.is_false(comment_changed_3f(local_cmt, remote_cmt))
    end
    it("ignores leading/trailing whitespace", _30_)
    local function _31_()
      local local_cmt = {id = 1, text = nil}
      local remote_cmt = {id = 1, text = nil}
      local comment_changed_3f = comments_md["comment-changed?"]
      return assert.is_false(comment_changed_3f(local_cmt, remote_cmt))
    end
    return it("handles nil text", _31_)
  end
  describe("comment-changed?", _27_)
  local function _32_()
    local function _33_()
      local cmts = {{id = 1, text = "First"}, {id = 2, text = "Second"}, {id = 3, text = "Third"}}
      local find_comment_by_id = comments_md["find-comment-by-id"]
      local result = find_comment_by_id(cmts, 2)
      assert.is_not_nil(result)
      return assert.equals("Second", result.text)
    end
    it("finds comment by ID", _33_)
    local function _34_()
      local cmts = {{id = 1, text = "First"}}
      local find_comment_by_id = comments_md["find-comment-by-id"]
      local result = find_comment_by_id(cmts, 999)
      return assert.is_nil(result)
    end
    return it("returns nil when not found", _34_)
  end
  describe("find-comment-by-id", _32_)
  local function _35_()
    local function _36_()
      local a = {{id = 1, text = "Hello"}}
      local b = {{id = 1, text = "Hello"}}
      local comments_equal_3f = comments_md["comments-equal?"]
      return assert.is_true(comments_equal_3f(a, b))
    end
    it("returns true for identical lists", _36_)
    local function _37_()
      local a = {{id = 1, text = "Hello"}}
      local b = {{id = 1, text = "Hello"}, {id = 2, text = "World"}}
      local comments_equal_3f = comments_md["comments-equal?"]
      return assert.is_false(comments_equal_3f(a, b))
    end
    it("returns false for different lengths", _37_)
    local function _38_()
      local a = {{id = 1, text = "Hello"}}
      local b = {{id = 1, text = "Goodbye"}}
      local comments_equal_3f = comments_md["comments-equal?"]
      return assert.is_false(comments_equal_3f(a, b))
    end
    it("returns false for different text", _38_)
    local function _39_()
      local comments_equal_3f = comments_md["comments-equal?"]
      return assert.is_true(comments_equal_3f({}, {}))
    end
    return it("returns true for two empty lists", _39_)
  end
  describe("comments-equal?", _35_)
  local function _40_()
    local function _41_()
      local format_timestamp = comments_md["format-timestamp"]
      local result = format_timestamp("2026-01-10T10:30:00Z")
      return assert.equals("2026-01-10 10:30", result)
    end
    it("formats ISO 8601 timestamp with default format", _41_)
    local function _42_()
      t["setup-test-config"]({comments = {timestamp_format = "%d/%m/%Y %H:%M", max_pull = 50, show_timestamps = true, confirm_delete = true}})
      local format_timestamp = comments_md["format-timestamp"]
      local result = format_timestamp("2026-01-10T10:30:00Z")
      return assert.equals("10/01/2026 10:30", result)
    end
    it("formats ISO 8601 timestamp with custom format", _42_)
    local function _43_()
      t["setup-test-config"]({comments = {timestamp_format = "%Y-%m-%d", max_pull = 50, show_timestamps = true, confirm_delete = true}})
      local format_timestamp = comments_md["format-timestamp"]
      local result = format_timestamp("2026-01-10T10:30:00Z")
      return assert.equals("2026-01-10", result)
    end
    it("formats ISO 8601 timestamp with date-only format", _43_)
    local function _44_()
      local format_timestamp = comments_md["format-timestamp"]
      local result = format_timestamp(nil)
      return assert.equals("", result)
    end
    it("returns empty string for nil input", _44_)
    local function _45_()
      local format_timestamp = comments_md["format-timestamp"]
      local result = format_timestamp("not a timestamp")
      return assert.equals("not a timestamp", result)
    end
    return it("returns raw string for non-ISO input", _45_)
  end
  describe("format-timestamp", _40_)
  local function _46_()
    local function _47_()
      local members = require("longway.api.members")
      local original_resolve = members["resolve-name"]
      local function _48_(id)
        return id
      end
      members["resolve-name"] = _48_
      local format_api_comments = comments_md["format-api-comments"]
      local raw = {{id = 101, text = "Hello world", author_id = "author-uuid-1", created_at = "2026-01-10T10:30:00Z"}}
      local result = format_api_comments(raw)
      assert.equals(1, #result)
      assert.equals(101, result[1].id)
      assert.equals("Hello world", result[1].text)
      assert.equals("2026-01-10 10:30", result[1].timestamp)
      assert.is_false(result[1].is_new)
      members["resolve-name"] = original_resolve
      return nil
    end
    it("converts raw API comments to rendering format", _47_)
    local function _49_()
      local format_api_comments = comments_md["format-api-comments"]
      local result = format_api_comments({})
      return assert.equals(0, #result)
    end
    it("handles empty input", _49_)
    local function _50_()
      local format_api_comments = comments_md["format-api-comments"]
      local result = format_api_comments(nil)
      return assert.equals(0, #result)
    end
    it("handles nil input", _50_)
    local function _51_()
      local members = require("longway.api.members")
      local original_resolve = members["resolve-name"]
      local function _52_(id)
        if (id == "uuid-alice") then
          return "Alice"
        else
          return id
        end
      end
      members["resolve-name"] = _52_
      local format_api_comments = comments_md["format-api-comments"]
      local raw = {{id = 1, text = "Test", author_id = "uuid-alice", created_at = "2026-01-10T10:30:00Z"}}
      local result = format_api_comments(raw)
      assert.equals("Alice", result[1].author)
      members["resolve-name"] = original_resolve
      return nil
    end
    it("resolves author_id to display name via members cache", _51_)
    local function _54_()
      local members = require("longway.api.members")
      local original_resolve = members["resolve-name"]
      local function _55_(id)
        return id
      end
      members["resolve-name"] = _55_
      local format_api_comments = comments_md["format-api-comments"]
      local raw = {{id = 1, text = "Test", author_id = "unknown-uuid", created_at = "2026-01-10T10:30:00Z"}}
      local result = format_api_comments(raw)
      assert.equals("unknown-uuid", result[1].author)
      members["resolve-name"] = original_resolve
      return nil
    end
    it("falls back to raw ID when member not found", _54_)
    local function _56_()
      local members = require("longway.api.members")
      local original_resolve = members["resolve-name"]
      local function _57_(id)
        return id
      end
      members["resolve-name"] = _57_
      local format_api_comments = comments_md["format-api-comments"]
      local raw = {{id = 3, text = "Newest", author_id = "a", created_at = "2026-01-12T10:00:00Z"}, {id = 1, text = "Oldest", author_id = "a", created_at = "2026-01-10T10:00:00Z"}, {id = 2, text = "Middle", author_id = "a", created_at = "2026-01-11T10:00:00Z"}}
      local result = format_api_comments(raw)
      assert.equals(1, result[1].id)
      assert.equals("Oldest", result[1].text)
      assert.equals(2, result[2].id)
      assert.equals("Middle", result[2].text)
      assert.equals(3, result[3].id)
      assert.equals("Newest", result[3].text)
      members["resolve-name"] = original_resolve
      return nil
    end
    it("sorts comments chronologically (oldest first)", _56_)
    local function _58_()
      local members = require("longway.api.members")
      local original_resolve = members["resolve-name"]
      local function _59_(id)
        return id
      end
      members["resolve-name"] = _59_
      local format_api_comments = comments_md["format-api-comments"]
      local raw = {{id = 1, text = "Active", author_id = "a", created_at = "2026-01-10T10:00:00Z", deleted = false}, {id = 2, text = "", author_id = "a", created_at = "2026-01-11T10:00:00Z", deleted = true}, {id = 3, text = "Also active", author_id = "a", created_at = "2026-01-12T10:00:00Z"}}
      local result = format_api_comments(raw)
      assert.equals(2, #result)
      assert.equals(1, result[1].id)
      assert.equals(3, result[2].id)
      members["resolve-name"] = original_resolve
      return nil
    end
    return it("filters out deleted comments (soft delete)", _58_)
  end
  describe("format-api-comments", _46_)
  local function _60_()
    local function _61_()
      local resolve_author_name = comments_md["resolve-author-name"]
      local result = resolve_author_name(nil)
      return assert.equals("Unknown", result)
    end
    it("returns Unknown for nil input", _61_)
    local function _62_()
      local members = require("longway.api.members")
      local original_resolve = members["resolve-name"]
      local function _63_(id)
        return "Resolved Name"
      end
      members["resolve-name"] = _63_
      local resolve_author_name = comments_md["resolve-author-name"]
      local result = resolve_author_name("some-uuid")
      assert.equals("Resolved Name", result)
      members["resolve-name"] = original_resolve
      return nil
    end
    return it("delegates to members.resolve-name for valid ID", _62_)
  end
  describe("resolve-author-name", _60_)
  local function _64_()
    local function _65_()
      local original_block = "**Author** \194\183 2026-01-10 10:30 <!-- comment:456 -->\n\nSome text here"
      local parsed = comments_md["parse-block"](original_block)
      local rendered = comments_md["render-comment"](parsed)
      assert.has_substring(rendered, "comment:456")
      assert.has_substring(rendered, "**Author**")
      return assert.has_substring(rendered, "Some text here")
    end
    it("parsed comment can be re-rendered with same metadata", _65_)
    local function _66_()
      local cmts = {{id = 1, text = "Comment A"}, {id = 2, text = "Comment B"}}
      local hash1 = hash["comments-hash"](cmts)
      local hash2 = hash["comments-hash"](cmts)
      assert.equals(hash1, hash2)
      local modified = {{id = 1, text = "Changed"}, {id = 2, text = "Comment B"}}
      local hash3 = hash["comments-hash"](modified)
      return assert.is_not.equals(hash1, hash3)
    end
    return it("comments hash is stable across render-parse cycles", _66_)
  end
  return describe("round-trip parse-render", _64_)
end
return describe("longway.markdown.comments", _1_)
