-- [nfnl] fnl/longway-spec/sync/comments_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local comments_sync = require("longway.sync.comments")
local comments_md = require("longway.markdown.comments")
local hash = require("longway.util.hash")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      local local_comments = {{text = "New comment", is_new = true}}
      local remote_comments = {}
      local result = comments_sync.diff(local_comments, remote_comments)
      assert.equals(1, #result.created)
      assert.equals(0, #result.deleted)
      assert.equals(0, #result.edited)
      return assert.equals(0, #result.unchanged)
    end
    it("detects new local comments", _4_)
    local function _5_()
      local local_comments = {}
      local remote_comments = {{id = 1, text = "Remote comment", is_new = false}}
      local result = comments_sync.diff(local_comments, remote_comments)
      assert.equals(0, #result.created)
      assert.equals(1, #result.deleted)
      return assert.equals(1, result.deleted[1])
    end
    it("detects deleted comments", _5_)
    local function _6_()
      local local_comments = {{id = 1, text = "Edited text", is_new = false}}
      local remote_comments = {{id = 1, text = "Original text", is_new = false}}
      local result = comments_sync.diff(local_comments, remote_comments)
      assert.equals(0, #result.created)
      assert.equals(0, #result.deleted)
      return assert.equals(1, #result.edited)
    end
    it("detects edited comments", _6_)
    local function _7_()
      local local_comments = {{id = 1, text = "Same text", is_new = false}}
      local remote_comments = {{id = 1, text = "Same text", is_new = false}}
      local result = comments_sync.diff(local_comments, remote_comments)
      assert.equals(0, #result.created)
      assert.equals(0, #result.deleted)
      assert.equals(0, #result.edited)
      return assert.equals(1, #result.unchanged)
    end
    it("detects unchanged comments", _7_)
    local function _8_()
      local local_comments = {{id = 1, text = "Unchanged", is_new = false}, {id = 2, text = "Edited text", is_new = false}, {text = "Brand new", is_new = true}}
      local remote_comments = {{id = 1, text = "Unchanged", is_new = false}, {id = 2, text = "Original text", is_new = false}, {id = 3, text = "Will be deleted", is_new = false}}
      local result = comments_sync.diff(local_comments, remote_comments)
      assert.equals(1, #result.created)
      assert.equals(1, #result.deleted)
      assert.equals(1, #result.edited)
      return assert.equals(1, #result.unchanged)
    end
    it("handles complex diff scenario", _8_)
    local function _9_()
      local remote_comments = {{id = 1, text = "Comment", is_new = false}}
      local result = comments_sync.diff(nil, remote_comments)
      assert.equals(0, #result.created)
      return assert.equals(1, #result.deleted)
    end
    it("handles nil local comments", _9_)
    local function _10_()
      local local_comments = {{text = "New", is_new = true}}
      local result = comments_sync.diff(local_comments, nil)
      assert.equals(1, #result.created)
      return assert.equals(0, #result.deleted)
    end
    it("handles nil remote comments", _10_)
    local function _11_()
      local result = comments_sync.diff(nil, nil)
      assert.equals(0, #result.created)
      assert.equals(0, #result.deleted)
      assert.equals(0, #result.edited)
      return assert.equals(0, #result.unchanged)
    end
    it("handles both nil", _11_)
    local function _12_()
      local local_comments = {{id = 99, text = "Retained", is_new = false}}
      local remote_comments = {}
      local result = comments_sync.diff(local_comments, remote_comments)
      assert.equals(1, #result.created)
      return assert.equals(0, #result.edited)
    end
    return it("treats locally present comment missing from remote as new", _12_)
  end
  describe("diff", _3_)
  local function _13_()
    local function _14_()
      local diff = {created = {{text = "New"}}, deleted = {}, edited = {}, unchanged = {}}
      local has_changes_3f = comments_sync["has-changes?"]
      return assert.is_true(has_changes_3f(diff))
    end
    it("returns true when there are created comments", _14_)
    local function _15_()
      local diff = {created = {}, deleted = {1}, edited = {}, unchanged = {}}
      local has_changes_3f = comments_sync["has-changes?"]
      return assert.is_true(has_changes_3f(diff))
    end
    it("returns true when there are deleted comments", _15_)
    local function _16_()
      local diff = {created = {}, deleted = {}, edited = {{id = 1}}, unchanged = {}}
      local has_changes_3f = comments_sync["has-changes?"]
      return assert.is_false(has_changes_3f(diff))
    end
    it("returns false when only edits (no creates or deletes)", _16_)
    local function _17_()
      local diff = {created = {}, deleted = {}, edited = {}, unchanged = {{id = 1}}}
      local has_changes_3f = comments_sync["has-changes?"]
      return assert.is_false(has_changes_3f(diff))
    end
    return it("returns false when no changes", _17_)
  end
  describe("has-changes?", _13_)
  local function _18_()
    local function _19_()
      local local_comments = {{text = "Local new", is_new = true}}
      local remote_comments = {}
      local previous_comments = {}
      local result = comments_sync.merge(local_comments, remote_comments, previous_comments)
      assert.equals(1, #result.comments)
      return assert.equals("Local new", result.comments[1].text)
    end
    it("keeps new local comments", _19_)
    local function _20_()
      local local_comments = {}
      local remote_comments = {{id = 1, author = "Bob", timestamp = "2026-01-10", text = "Remote new"}}
      local previous_comments = {}
      local result = comments_sync.merge(local_comments, remote_comments, previous_comments)
      assert.equals(1, #result.remote_added)
      return assert.equals(1, result.remote_added[1].id)
    end
    it("adds new remote comments", _20_)
    local function _21_()
      local local_comments = {{id = 1, text = "Local version", is_new = false}}
      local remote_comments = {{id = 1, text = "Remote version", is_new = false}}
      local previous_comments = {{id = 1, text = "Original", is_new = false}}
      local result = comments_sync.merge(local_comments, remote_comments, previous_comments)
      return assert.equals(1, #result.conflicts)
    end
    it("detects conflicts when both changed", _21_)
    local function _22_()
      local local_comments = {{id = 1, text = "Comment", is_new = false}}
      local remote_comments = {}
      local previous_comments = {{id = 1, text = "Comment", is_new = false}}
      local result = comments_sync.merge(local_comments, remote_comments, previous_comments)
      return assert.equals(1, #result.remote_deleted)
    end
    it("detects remote deletions", _22_)
    local function _23_()
      local local_comments = {{id = 1, text = "Updated locally", is_new = false}}
      local remote_comments = {{id = 1, text = "Original", is_new = false}}
      local previous_comments = {{id = 1, text = "Original", is_new = false}}
      local result = comments_sync.merge(local_comments, remote_comments, previous_comments)
      assert.equals(0, #result.conflicts)
      assert.equals(1, #result.comments)
      return assert.equals("Updated locally", result.comments[1].text)
    end
    it("keeps locally changed comment when remote unchanged", _23_)
    local function _24_()
      local result = comments_sync.merge({}, {}, {})
      assert.equals(0, #result.comments)
      return assert.equals(0, #result.conflicts)
    end
    return it("handles empty merge", _24_)
  end
  describe("merge", _18_)
  local function _25_()
    local function _26_()
      local local_content = "---\n**Alice** \194\183 2026-01-10 10:00 <!-- comment:101 -->\n\nExisting comment.\n\n---\n**Me** \194\183 2026-01-20 15:00 <!-- comment:new -->\n\nNew from user."
      local local_comments = comments_md["parse-section"](local_content)
      local remote_comments = {{id = 101, text = "Existing comment.", is_new = false}, {id = 102, text = "Another remote comment", is_new = false}}
      local diff = comments_sync.diff(local_comments, remote_comments)
      assert.equals(1, #diff.created)
      assert.equals(1, #diff.deleted)
      return assert.equals(102, diff.deleted[1])
    end
    it("parses markdown, diffs with remote, detects changes", _26_)
    local function _27_()
      local comments = {{id = 1, text = "Comment A"}, {id = 2, text = "Comment B"}}
      local hash1 = hash["comments-hash"](comments)
      local hash2 = hash["comments-hash"](comments)
      assert.equals(hash1, hash2)
      local modified = {{id = 1, text = "Changed A"}, {id = 2, text = "Comment B"}}
      local hash3 = hash["comments-hash"](modified)
      return assert.is_not.equals(hash1, hash3)
    end
    return it("computes stable hash for comments before and after round-trip", _27_)
  end
  return describe("integration: parse-diff round-trip", _25_)
end
return describe("longway.sync.comments", _1_)
