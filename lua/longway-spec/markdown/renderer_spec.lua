local t = require("longway-spec.init")
require("longway-spec.assertions")
local renderer = require("longway.markdown.renderer")
local function _1_()
  local function _2_()
    return t["setup-test-config"]({})
  end
  before_each(_2_)
  local function _3_()
    local function _4_()
      local story = t["make-story"]({})
      local result = renderer.render_story(story)
      return assert.has_frontmatter(result)
    end
    it("renders story with frontmatter", _4_)
    local function _5_()
      local story = t["make-story"]({id = 12345})
      local result = renderer.render_story(story)
      return assert.has_substring(result, "shortcut_id: 12345")
    end
    it("includes shortcut_id in frontmatter", _5_)
    local function _6_()
      local story = t["make-story"]({})
      local result = renderer.render_story(story)
      return assert.has_substring(result, "shortcut_type: story")
    end
    it("includes shortcut_type as story", _6_)
    local function _7_()
      local story = t["make-story"]({name = "My Test Story"})
      local result = renderer.render_story(story)
      return assert.has_substring(result, "# My Test Story")
    end
    it("renders story title as heading", _7_)
    local function _8_()
      local story = t["make-story"]({description = "Story description here."})
      local result = renderer.render_story(story)
      assert.has_sync_section(result, "description")
      return assert.has_substring(result, "Story description here.")
    end
    it("renders description in sync section", _8_)
    local function _9_()
      t["setup-test-config"]({sync_sections = {tasks = true}})
      local story = t["make-story"]({tasks = {t["make-task"]({description = "Test task"})}})
      local result = renderer.render_story(story)
      assert.has_sync_section(result, "tasks")
      return assert.has_substring(result, "Test task")
    end
    it("renders tasks section when enabled", _9_)
    local function _10_()
      local story = t["make-story"]({tasks = {t["make-task"]({description = "Incomplete", complete = false}), t["make-task"]({id = 2, description = "Complete", complete = true})}})
      local result = renderer.render_story(story)
      assert.has_substring(result, "[ ] Incomplete")
      return assert.has_substring(result, "[x] Complete")
    end
    it("renders task checkboxes correctly", _10_)
    local function _11_()
      t["setup-test-config"]({sync_sections = {comments = true}})
      local story = t["make-story"]({comments = {t["make-comment"]({text = "Test comment"})}})
      local result = renderer.render_story(story)
      assert.has_sync_section(result, "comments")
      return assert.has_substring(result, "Test comment")
    end
    it("renders comments section when enabled", _11_)
    local function _12_()
      local story = t["make-story"]({comments = {t["make-comment"]({author = {profile = {name = "John Doe"}}})}})
      local result = renderer.render_story(story)
      return assert.has_substring(result, "John Doe")
    end
    it("includes comment author", _12_)
    local function _13_()
      local story = t["make-story"]({})
      local result = renderer.render_story(story)
      assert.has_substring(result, "## Local Notes")
      return assert.has_substring(result, "NOT synced to Shortcut")
    end
    it("renders local notes section", _13_)
    local function _14_()
      local story = t["make-story"]({workflow_state_name = "In Progress"})
      local result = renderer.render_story(story)
      return assert.has_substring(result, "state: In Progress")
    end
    it("includes workflow state", _14_)
    local function _15_()
      local story = t["make-story"]({story_type = "bug"})
      local result = renderer.render_story(story)
      return assert.has_substring(result, "story_type: bug")
    end
    it("includes story type", _15_)
    local function _16_()
      local story = t["make-story"]({description = nil})
      local result = renderer.render_story(story)
      return assert.has_sync_section(result, "description")
    end
    it("handles empty description", _16_)
    local function _17_()
      local story = t["make-story"]({tasks = {}})
      local result = renderer.render_story(story)
      return assert.has_sync_section(result, "tasks")
    end
    it("handles empty tasks", _17_)
    local function _18_()
      local story = t["make-story"]({comments = {}})
      local result = renderer.render_story(story)
      return assert.has_sync_section(result, "comments")
    end
    return it("handles empty comments", _18_)
  end
  describe("render_story", _3_)
  local function _19_()
    local function _20_()
      local epic = {id = 100, name = "Test Epic", description = "Epic description", state = "in progress", app_url = "https://example.com", created_at = "2026-01-01T00:00:00Z", updated_at = "2026-01-15T00:00:00Z"}
      local result = renderer.render_epic(epic, {})
      return assert.has_frontmatter(result)
    end
    it("renders epic with frontmatter", _20_)
    local function _21_()
      local epic = {id = 100, name = "Test Epic", description = "", state = "done", app_url = "https://example.com", created_at = "2026-01-01T00:00:00Z", updated_at = "2026-01-15T00:00:00Z"}
      local result = renderer.render_epic(epic, {})
      return assert.has_substring(result, "shortcut_type: epic")
    end
    it("includes shortcut_type as epic", _21_)
    local function _22_()
      local epic = {id = 100, name = "My Epic Title", description = "", state = "done", app_url = "https://example.com", created_at = "2026-01-01T00:00:00Z", updated_at = "2026-01-15T00:00:00Z"}
      local result = renderer.render_epic(epic, {})
      return assert.has_substring(result, "# My Epic Title")
    end
    it("renders epic title as heading", _22_)
    local function _23_()
      local epic = {id = 100, name = "Epic", description = "", state = "done", app_url = "https://example.com", created_at = "2026-01-01T00:00:00Z", updated_at = "2026-01-15T00:00:00Z"}
      local stories = {t["make-story"]({id = 1, name = "Story One"}), t["make-story"]({id = 2, name = "Story Two"})}
      local result = renderer.render_epic(epic, stories)
      assert.has_substring(result, "## Stories")
      assert.has_substring(result, "Story One")
      return assert.has_substring(result, "Story Two")
    end
    return it("renders stories table when provided", _23_)
  end
  return describe("render_epic", _19_)
end
return describe("longway.markdown.renderer", _1_)
