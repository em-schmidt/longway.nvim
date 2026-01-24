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
return M
