-- [nfnl] fnl/longway-spec/init.fnl
local M = {}
M["setup-test-config"] = function(overrides)
  local config = require("longway.config")
  local test_config = vim.tbl_deep_extend("force", {workspace_dir = "/tmp/longway-test", stories_subdir = "stories", epics_subdir = "epics", filename_template = "{id}-{slug}", slug_max_length = 50, sync_start_marker = "<!-- BEGIN SHORTCUT SYNC:{section} -->", sync_end_marker = "<!-- END SHORTCUT SYNC:{section} -->", sync_sections = {description = true, tasks = true, comments = true}, tasks = {show_owners = true}, _resolved_token = "test-token"}, (overrides or {}))
  config.setup(test_config)
  return test_config
end
M["reset-config"] = function()
  return M["setup-test-config"]({})
end
M["make-story"] = function(overrides)
  return vim.tbl_deep_extend("force", {id = 12345, name = "Test Story Title", description = "This is the story description.", story_type = "feature", workflow_state_name = "In Progress", app_url = "https://app.shortcut.com/test/story/12345", created_at = "2026-01-01T00:00:00Z", updated_at = "2026-01-15T12:00:00Z", tasks = {}, comments = {}, owners = {}, labels = {}}, (overrides or {}))
end
M["make-task"] = function(overrides)
  return vim.tbl_deep_extend("force", {id = 67890, description = "Test task description", owner_ids = {}, complete = false}, (overrides or {}))
end
M["make-comment"] = function(overrides)
  return vim.tbl_deep_extend("force", {id = 11111, text = "This is a test comment.", created_at = "2026-01-10T10:30:00Z", author = {id = "author-1", profile = {name = "Test Author"}}}, (overrides or {}))
end
M["sample-markdown"] = function()
  return "---\nshortcut_id: 12345\nshortcut_type: story\nshortcut_url: https://app.shortcut.com/test/story/12345\nstory_type: feature\nstate: In Progress\nsync_hash: abc123\n---\n\n# Test Story Title\n\n## Description\n\n<!-- BEGIN SHORTCUT SYNC:description -->\nThis is the story description.\n<!-- END SHORTCUT SYNC:description -->\n\n## Tasks\n\n<!-- BEGIN SHORTCUT SYNC:tasks -->\n- [ ] First task <!-- task:1 complete:false -->\n- [x] Second task <!-- task:2 complete:true -->\n<!-- END SHORTCUT SYNC:tasks -->\n\n## Comments\n\n<!-- BEGIN SHORTCUT SYNC:comments -->\n---\n**Test Author** \194\183 2026-01-10 10:30 <!-- comment:11111 -->\n\nThis is a test comment.\n<!-- END SHORTCUT SYNC:comments -->\n\n## Local Notes\n\n<!-- This section is NOT synced to Shortcut -->\n"
end

-- Phase 2 test helpers
M["make-epic"] = function(overrides)
  return vim.tbl_deep_extend("force", {
    id = 99999,
    name = "Test Epic",
    description = "This is the epic description.",
    state = "in progress",
    app_url = "https://app.shortcut.com/test/epic/99999",
    created_at = "2026-01-01T00:00:00Z",
    updated_at = "2026-01-15T12:00:00Z",
    planned_start_date = "2026-01-01",
    deadline = "2026-03-01",
    stats = {
      num_stories = 10,
      num_stories_started = 3,
      num_stories_done = 5,
      num_stories_unstarted = 2,
      num_points = 20,
      num_points_done = 10
    }
  }, (overrides or {}))
end

M["make-member"] = function(overrides)
  return vim.tbl_deep_extend("force", {
    id = "member-uuid-123",
    profile = {
      name = "Test User",
      mention_name = "testuser",
      email_address = "test@example.com"
    }
  }, (overrides or {}))
end

M["make-workflow"] = function(overrides)
  return vim.tbl_deep_extend("force", {
    id = 1,
    name = "Default Workflow",
    states = {
      { id = 101, name = "To Do", type = "unstarted" },
      { id = 102, name = "In Progress", type = "started" },
      { id = 103, name = "Done", type = "done" }
    }
  }, (overrides or {}))
end

M["make-iteration"] = function(overrides)
  return vim.tbl_deep_extend("force", {
    id = 1001,
    name = "Sprint 1",
    status = "started",
    start_date = "2026-01-01",
    end_date = "2026-01-14"
  }, (overrides or {}))
end

M["make-team"] = function(overrides)
  return vim.tbl_deep_extend("force", {
    id = "team-uuid-123",
    name = "Engineering",
    member_ids = { "member-1", "member-2", "member-3" }
  }, (overrides or {}))
end

-- Lua-friendly aliases (underscores instead of hyphens)
M.setup_test_config = M["setup-test-config"]
M.reset_config = M["reset-config"]
M.make_story = M["make-story"]
M.make_task = M["make-task"]
M.make_comment = M["make-comment"]
M.sample_markdown = M["sample-markdown"]
M.make_epic = M["make-epic"]
M.make_member = M["make-member"]
M.make_workflow = M["make-workflow"]
M.make_iteration = M["make-iteration"]
M.make_team = M["make-team"]

return M
