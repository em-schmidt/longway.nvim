;; Test utilities for longway.nvim
;; Common helpers used across test specs

(local M {})

(fn M.setup-test-config [overrides]
  "Setup a test configuration with optional overrides"
  (let [config (require :longway.config)
        test-config (vim.tbl_deep_extend :force
                                         {:workspace_dir "/tmp/longway-test"
                                          :stories_subdir "stories"
                                          :epics_subdir "epics"
                                          :filename_template "{id}-{slug}"
                                          :slug_max_length 50
                                          :sync_start_marker "<!-- BEGIN SHORTCUT SYNC:{section} -->"
                                          :sync_end_marker "<!-- END SHORTCUT SYNC:{section} -->"
                                          :sync_sections {:description true
                                                          :tasks true
                                                          :comments true}
                                          :tasks {:show_owners true
                                                          :confirm_delete true
                                                          :auto_assign_on_complete false}
                                          :comments {:max_pull 50
                                                     :show_timestamps true
                                                     :timestamp_format "%Y-%m-%d %H:%M"
                                                     :confirm_delete true}
                                          :_resolved_token "test-token"}
                                         (or overrides {}))]
    (config.setup test-config)
    test-config))

(fn M.reset-config []
  "Reset configuration to test defaults"
  (M.setup-test-config {}))

(fn M.make-story [overrides]
  "Create a mock story with optional overrides"
  (vim.tbl_deep_extend :force
                       {:id 12345
                        :name "Test Story Title"
                        :description "This is the story description."
                        :story_type "feature"
                        :workflow_state_name "In Progress"
                        :app_url "https://app.shortcut.com/test/story/12345"
                        :created_at "2026-01-01T00:00:00Z"
                        :updated_at "2026-01-15T12:00:00Z"
                        :tasks []
                        :comments []
                        :owners []
                        :labels []}
                       (or overrides {})))

(fn M.make-task [overrides]
  "Create a mock task with optional overrides"
  (vim.tbl_deep_extend :force
                       {:id 67890
                        :description "Test task description"
                        :complete false
                        :owner_ids []}
                       (or overrides {})))

(fn M.make-comment [overrides]
  "Create a mock comment with optional overrides"
  (vim.tbl_deep_extend :force
                       {:id 11111
                        :text "This is a test comment."
                        :created_at "2026-01-10T10:30:00Z"
                        :author {:id "author-1"
                                 :profile {:name "Test Author"}}}
                       (or overrides {})))

(fn M.make-api-comment [overrides]
  "Create a mock API comment response (raw from Shortcut API)"
  (vim.tbl_deep_extend :force
                       {:id 11111
                        :text "This is a test comment."
                        :author_id "author-uuid-1"
                        :created_at "2026-01-10T10:30:00Z"
                        :updated_at "2026-01-10T10:30:00Z"
                        :story_id 12345}
                       (or overrides {})))

(fn M.make-parsed-comment [overrides]
  "Create a mock parsed comment (as returned by markdown parser)"
  (vim.tbl_deep_extend :force
                       {:id 11111
                        :author "Test Author"
                        :timestamp "2026-01-10 10:30"
                        :text "This is a test comment."
                        :is_new false}
                       (or overrides {})))

(fn M.sample-markdown []
  "Return a sample markdown file for testing"
  "---
shortcut_id: 12345
shortcut_type: story
shortcut_url: https://app.shortcut.com/test/story/12345
story_type: feature
state: In Progress
sync_hash: abc123
---

# Test Story Title

## Description

<!-- BEGIN SHORTCUT SYNC:description -->
This is the story description.
<!-- END SHORTCUT SYNC:description -->

## Tasks

<!-- BEGIN SHORTCUT SYNC:tasks -->
- [ ] First task <!-- task:1 complete:false -->
- [x] Second task <!-- task:2 complete:true -->
<!-- END SHORTCUT SYNC:tasks -->

## Comments

<!-- BEGIN SHORTCUT SYNC:comments -->
---
**Test Author** · 2026-01-10 10:30 <!-- comment:11111 -->

This is a test comment.
<!-- END SHORTCUT SYNC:comments -->

## Local Notes

<!-- This section is NOT synced to Shortcut -->
")

;; Phase 2 test helpers

(fn M.make-epic [overrides]
  "Create a mock epic with optional overrides"
  (vim.tbl_deep_extend :force
                       {:id 99999
                        :name "Test Epic"
                        :description "This is the epic description."
                        :state "in progress"
                        :app_url "https://app.shortcut.com/test/epic/99999"
                        :created_at "2026-01-01T00:00:00Z"
                        :updated_at "2026-01-15T12:00:00Z"
                        :planned_start_date "2026-01-01"
                        :deadline "2026-03-01"
                        :stats {:num_stories_total 10
                                :num_stories_started 3
                                :num_stories_done 5
                                :num_stories_unstarted 2
                                :num_points 20
                                :num_points_done 10}}
                       (or overrides {})))

(fn M.make-member [overrides]
  "Create a mock member with optional overrides"
  (vim.tbl_deep_extend :force
                       {:id "member-uuid-123"
                        :profile {:name "Test User"
                                  :mention_name "testuser"
                                  :email_address "test@example.com"}}
                       (or overrides {})))

(fn M.make-workflow [overrides]
  "Create a mock workflow with optional overrides"
  (vim.tbl_deep_extend :force
                       {:id 1
                        :name "Default Workflow"
                        :states [{:id 101 :name "To Do" :type "unstarted"}
                                 {:id 102 :name "In Progress" :type "started"}
                                 {:id 103 :name "Done" :type "done"}]}
                       (or overrides {})))

(fn M.make-iteration [overrides]
  "Create a mock iteration with optional overrides"
  (vim.tbl_deep_extend :force
                       {:id 1001
                        :name "Sprint 1"
                        :status "started"
                        :start_date "2026-01-01"
                        :end_date "2026-01-14"}
                       (or overrides {})))

(fn M.make-team [overrides]
  "Create a mock team/group with optional overrides"
  (vim.tbl_deep_extend :force
                       {:id "team-uuid-123"
                        :name "Engineering"
                        :member_ids ["member-1" "member-2" "member-3"]}
                       (or overrides {})))

M
