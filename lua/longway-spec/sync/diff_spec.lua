-- [nfnl] fnl/longway-spec/sync/diff_spec.fnl
local t = require("longway-spec.init")
require("longway-spec.assertions")
local diff = require("longway.sync.diff")
local hash = require("longway.util.hash")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      local first_sync_3f = diff["first-sync?"]
      local fm = {sync_hash = ""}
      return assert.is_true(first_sync_3f(fm))
    end
    it("returns true when sync_hash is empty string", _4_)
    local function _5_()
      local first_sync_3f = diff["first-sync?"]
      local fm = {}
      return assert.is_true(first_sync_3f(fm))
    end
    it("returns true when sync_hash is nil", _5_)
    local function _6_()
      local first_sync_3f = diff["first-sync?"]
      local fm = {sync_hash = "abc12345"}
      return assert.is_false(first_sync_3f(fm))
    end
    return it("returns false when sync_hash has a value", _6_)
  end
  describe("first-sync?", _3_)
  local function _7_()
    local function _8_()
      local compute = diff["compute-section-hashes"]
      local parsed = {description = "Some description", tasks = {{id = 1, description = "Task", complete = false}}, comments = {{id = 1, text = "Comment"}}, frontmatter = {}}
      local result = compute(parsed)
      assert.is_valid_hash(result.description)
      assert.is_valid_hash(result.tasks)
      return assert.is_valid_hash(result.comments)
    end
    it("returns valid hashes for all sections", _8_)
    local function _9_()
      local compute = diff["compute-section-hashes"]
      local content_hash = hash["content-hash"]
      local desc = "Test description content"
      local parsed = {description = desc, tasks = {}, comments = {}, frontmatter = {}}
      local result = compute(parsed)
      return assert.equals(content_hash(desc), result.description)
    end
    it("matches hash module output for description", _9_)
    local function _10_()
      local compute = diff["compute-section-hashes"]
      local tasks = {{id = 1, description = "A", complete = false}, {id = 2, description = "B", complete = true}}
      local parsed = {description = "", tasks = tasks, comments = {}, frontmatter = {}}
      local result = compute(parsed)
      return assert.equals(hash["tasks-hash"](tasks), result.tasks)
    end
    it("matches hash module output for tasks", _10_)
    local function _11_()
      local compute = diff["compute-section-hashes"]
      local comments = {{id = 1, text = "Hello"}, {id = 2, text = "World"}}
      local parsed = {description = "", tasks = {}, comments = comments, frontmatter = {}}
      local result = compute(parsed)
      return assert.equals(hash["comments-hash"](comments), result.comments)
    end
    it("matches hash module output for comments", _11_)
    local function _12_()
      local compute = diff["compute-section-hashes"]
      local parsed = {frontmatter = {}}
      local result = compute(parsed)
      assert.is_valid_hash(result.description)
      assert.is_valid_hash(result.tasks)
      return assert.is_valid_hash(result.comments)
    end
    return it("handles nil sections gracefully", _12_)
  end
  describe("compute-section-hashes", _7_)
  local function _13_()
    local function _14_()
      local detect = diff["detect-local-changes"]
      local content_hash = hash["content-hash"]
      local desc = "My description"
      local tasks = {{id = 1, description = "Task", complete = false}}
      local comments = {{id = 1, text = "Comment"}}
      local parsed = {description = desc, tasks = tasks, comments = comments, frontmatter = {sync_hash = content_hash(desc), tasks_hash = hash["tasks-hash"](tasks), comments_hash = hash["comments-hash"](comments)}}
      local result = detect(parsed)
      assert.is_false(result.description)
      assert.is_false(result.tasks)
      return assert.is_false(result.comments)
    end
    it("returns all false when hashes match", _14_)
    local function _15_()
      local detect = diff["detect-local-changes"]
      local content_hash = hash["content-hash"]
      local parsed = {description = "New description", tasks = {}, comments = {}, frontmatter = {sync_hash = content_hash("Old description"), tasks_hash = hash["tasks-hash"]({}), comments_hash = hash["comments-hash"]({})}}
      local result = detect(parsed)
      assert.is_true(result.description)
      assert.is_false(result.tasks)
      return assert.is_false(result.comments)
    end
    it("detects description change", _15_)
    local function _16_()
      local detect = diff["detect-local-changes"]
      local content_hash = hash["content-hash"]
      local old_tasks = {{id = 1, description = "Task", complete = false}}
      local new_tasks = {{id = 1, description = "Task", complete = true}}
      local parsed = {description = "", tasks = new_tasks, comments = {}, frontmatter = {sync_hash = content_hash(""), tasks_hash = hash["tasks-hash"](old_tasks), comments_hash = hash["comments-hash"]({})}}
      local result = detect(parsed)
      assert.is_false(result.description)
      assert.is_true(result.tasks)
      return assert.is_false(result.comments)
    end
    it("detects task change", _16_)
    local function _17_()
      local detect = diff["detect-local-changes"]
      local content_hash = hash["content-hash"]
      local old_comments = {{id = 1, text = "Old text"}}
      local new_comments = {{id = 1, text = "New text"}}
      local parsed = {description = "", tasks = {}, comments = new_comments, frontmatter = {sync_hash = content_hash(""), tasks_hash = hash["tasks-hash"]({}), comments_hash = hash["comments-hash"](old_comments)}}
      local result = detect(parsed)
      assert.is_false(result.description)
      assert.is_false(result.tasks)
      return assert.is_true(result.comments)
    end
    it("detects comment change", _17_)
    local function _18_()
      local detect = diff["detect-local-changes"]
      local content_hash = hash["content-hash"]
      local parsed = {description = "Changed desc", tasks = {{id = 1, description = "Changed", complete = true}}, comments = {{id = 1, text = "Changed"}}, frontmatter = {sync_hash = content_hash("Original desc"), tasks_hash = hash["tasks-hash"]({{id = 1, description = "Original", complete = false}}), comments_hash = hash["comments-hash"]({{id = 1, text = "Original"}})}}
      local result = detect(parsed)
      assert.is_true(result.description)
      assert.is_true(result.tasks)
      return assert.is_true(result.comments)
    end
    return it("detects multiple changes simultaneously", _18_)
  end
  describe("detect-local-changes", _13_)
  local function _19_()
    local function _20_()
      local any_change_3f = diff["any-local-change?"]
      local content_hash = hash["content-hash"]
      local desc = "Same"
      local parsed = {description = desc, tasks = {}, comments = {}, frontmatter = {sync_hash = content_hash(desc), tasks_hash = hash["tasks-hash"]({}), comments_hash = hash["comments-hash"]({})}}
      return assert.is_false(any_change_3f(parsed))
    end
    it("returns false when nothing changed", _20_)
    local function _21_()
      local any_change_3f = diff["any-local-change?"]
      local content_hash = hash["content-hash"]
      local parsed = {description = "Different", tasks = {}, comments = {}, frontmatter = {sync_hash = content_hash("Original"), tasks_hash = hash["tasks-hash"]({}), comments_hash = hash["comments-hash"]({})}}
      return assert.is_true(any_change_3f(parsed))
    end
    return it("returns true when any section changed", _21_)
  end
  describe("any-local-change?", _19_)
  local function _22_()
    local function _23_()
      local detect = diff["detect-remote-change"]
      local fm = {updated_at = "2026-01-15T12:00:00Z"}
      return assert.is_false(detect(fm, "2026-01-15T12:00:00Z"))
    end
    it("returns false when timestamps match", _23_)
    local function _24_()
      local detect = diff["detect-remote-change"]
      local fm = {updated_at = "2026-01-15T12:00:00Z"}
      return assert.is_true(detect(fm, "2026-01-16T08:00:00Z"))
    end
    it("returns true when timestamps differ", _24_)
    local function _25_()
      local detect = diff["detect-remote-change"]
      local fm = {updated_at = "2026-01-15T12:00:00Z"}
      return assert.is_false(detect(fm, nil))
    end
    it("returns false when remote updated_at is nil", _25_)
    local function _26_()
      local detect = diff["detect-remote-change"]
      local fm = {updated_at = "2026-01-15T12:00:00Z"}
      return assert.is_false(detect(fm, ""))
    end
    it("returns false when remote updated_at is empty", _26_)
    local function _27_()
      local detect = diff["detect-remote-change"]
      local fm = {updated_at = ""}
      return assert.is_true(detect(fm, "2026-01-15T12:00:00Z"))
    end
    return it("returns true when stored is empty but remote has value", _27_)
  end
  describe("detect-remote-change", _22_)
  local function _28_()
    local function _29_()
      local content_hash = hash["content-hash"]
      local desc = "Description"
      local ts = "2026-01-15T12:00:00Z"
      local parsed = {description = desc, tasks = {}, comments = {}, frontmatter = {sync_hash = content_hash(desc), tasks_hash = hash["tasks-hash"]({}), comments_hash = hash["comments-hash"]({}), updated_at = ts}}
      local result = diff.classify(parsed, ts)
      assert.equals("clean", result.status)
      assert.is_false(result.remote_changed)
      assert.is_false(result.local_changes.description)
      assert.is_false(result.local_changes.tasks)
      return assert.is_false(result.local_changes.comments)
    end
    it("returns :clean when nothing changed", _29_)
    local function _30_()
      local content_hash = hash["content-hash"]
      local ts = "2026-01-15T12:00:00Z"
      local parsed = {description = "New description", tasks = {}, comments = {}, frontmatter = {sync_hash = content_hash("Old description"), tasks_hash = hash["tasks-hash"]({}), comments_hash = hash["comments-hash"]({}), updated_at = ts}}
      local result = diff.classify(parsed, ts)
      assert.equals("local-only", result.status)
      assert.is_false(result.remote_changed)
      return assert.is_true(result.local_changes.description)
    end
    it("returns :local-only when only local changed", _30_)
    local function _31_()
      local content_hash = hash["content-hash"]
      local desc = "Same description"
      local parsed = {description = desc, tasks = {}, comments = {}, frontmatter = {sync_hash = content_hash(desc), tasks_hash = hash["tasks-hash"]({}), comments_hash = hash["comments-hash"]({}), updated_at = "2026-01-15T12:00:00Z"}}
      local result = diff.classify(parsed, "2026-01-16T08:00:00Z")
      assert.equals("remote-only", result.status)
      assert.is_true(result.remote_changed)
      return assert.is_false(result.local_changes.description)
    end
    it("returns :remote-only when only remote changed", _31_)
    local function _32_()
      local content_hash = hash["content-hash"]
      local parsed = {description = "Locally edited", tasks = {}, comments = {}, frontmatter = {sync_hash = content_hash("Original"), tasks_hash = hash["tasks-hash"]({}), comments_hash = hash["comments-hash"]({}), updated_at = "2026-01-15T12:00:00Z"}}
      local result = diff.classify(parsed, "2026-01-16T08:00:00Z")
      assert.equals("conflict", result.status)
      assert.is_true(result.remote_changed)
      return assert.is_true(result.local_changes.description)
    end
    it("returns :conflict when both changed", _32_)
    local function _33_()
      local content_hash = hash["content-hash"]
      local desc = "Same"
      local ts = "2026-01-15T12:00:00Z"
      local parsed = {description = desc, tasks = {{id = 1, description = "Changed", complete = true}}, comments = {}, frontmatter = {sync_hash = content_hash(desc), tasks_hash = hash["tasks-hash"]({{id = 1, description = "Original", complete = false}}), comments_hash = hash["comments-hash"]({}), updated_at = ts}}
      local result = diff.classify(parsed, ts)
      assert.equals("local-only", result.status)
      assert.is_false(result.local_changes.description)
      assert.is_true(result.local_changes.tasks)
      return assert.is_false(result.local_changes.comments)
    end
    return it("detects independent section changes", _33_)
  end
  return describe("classify", _28_)
end
return describe("longway.sync.diff", _1_)
