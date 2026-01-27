;; Tests for longway.markdown.renderer
;;
;; Tests markdown rendering from Shortcut data

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local renderer (require :longway.markdown.renderer))

(describe "longway.markdown.renderer"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "render-story"
      (fn []
        (it "renders story with frontmatter"
          (fn []
            (let [story (t.make-story {})
                  result ((. renderer "render-story") story)]
              (assert.has_frontmatter result))))

        (it "includes shortcut_id in frontmatter"
          (fn []
            (let [story (t.make-story {:id 12345})
                  result ((. renderer "render-story") story)]
              (assert.has_substring result "shortcut_id: 12345"))))

        (it "includes shortcut_type as story"
          (fn []
            (let [story (t.make-story {})
                  result ((. renderer "render-story") story)]
              (assert.has_substring result "shortcut_type: story"))))

        (it "renders story title as heading"
          (fn []
            (let [story (t.make-story {:name "My Test Story"})
                  result ((. renderer "render-story") story)]
              (assert.has_substring result "# My Test Story"))))

        (it "renders description in sync section"
          (fn []
            (let [story (t.make-story {:description "Story description here."})
                  result ((. renderer "render-story") story)]
              (assert.has_sync_section result "description")
              (assert.has_substring result "Story description here."))))

        (it "renders tasks section when enabled"
          (fn []
            (t.setup-test-config {:sync_sections {:tasks true}})
            (let [story (t.make-story {:tasks [(t.make-task {:description "Test task"})]})
                  result ((. renderer "render-story") story)]
              (assert.has_sync_section result "tasks")
              (assert.has_substring result "Test task"))))

        (it "renders task checkboxes correctly"
          (fn []
            (let [story (t.make-story {:tasks [(t.make-task {:description "Incomplete" :complete false})
                                                (t.make-task {:id 2 :description "Complete" :complete true})]})
                  result ((. renderer "render-story") story)]
              (assert.has_substring result "[ ] Incomplete")
              (assert.has_substring result "[x] Complete"))))

        (it "renders comments section when enabled"
          (fn []
            (t.setup-test-config {:sync_sections {:comments true}})
            (let [story (t.make-story {:comments [(t.make-parsed-comment {:text "Test comment"})]})
                  result ((. renderer "render-story") story)]
              (assert.has_sync_section result "comments")
              (assert.has_substring result "Test comment"))))

        (it "includes comment author"
          (fn []
            (let [story (t.make-story {:comments [(t.make-parsed-comment {:author "John Doe"})]})
                  result ((. renderer "render-story") story)]
              (assert.has_substring result "John Doe"))))

        (it "renders local notes section"
          (fn []
            (let [story (t.make-story {})
                  result ((. renderer "render-story") story)]
              (assert.has_substring result "## Local Notes")
              (assert.has_substring result "NOT synced to Shortcut"))))

        (it "includes workflow state"
          (fn []
            (let [story (t.make-story {:workflow_state_name "In Progress"})
                  result ((. renderer "render-story") story)]
              (assert.has_substring result "state: In Progress"))))

        (it "includes story type"
          (fn []
            (let [story (t.make-story {:story_type "bug"})
                  result ((. renderer "render-story") story)]
              (assert.has_substring result "story_type: bug"))))

        (it "handles empty description"
          (fn []
            (let [story (t.make-story {:description nil})
                  result ((. renderer "render-story") story)]
              (assert.has_sync_section result "description"))))

        (it "handles empty tasks"
          (fn []
            (let [story (t.make-story {:tasks []})
                  result ((. renderer "render-story") story)]
              (assert.has_sync_section result "tasks"))))

        (it "handles empty comments"
          (fn []
            (let [story (t.make-story {:comments []})
                  result ((. renderer "render-story") story)]
              (assert.has_sync_section result "comments"))))))

    (describe "render-epic"
      (fn []
        (it "renders epic with frontmatter"
          (fn []
            (let [epic {:id 100
                        :name "Test Epic"
                        :description "Epic description"
                        :state "in progress"
                        :app_url "https://example.com"
                        :created_at "2026-01-01T00:00:00Z"
                        :updated_at "2026-01-15T00:00:00Z"}
                  result ((. renderer "render-epic") epic [])]
              (assert.has_frontmatter result))))

        (it "includes shortcut_type as epic"
          (fn []
            (let [epic {:id 100
                        :name "Test Epic"
                        :description ""
                        :state "done"
                        :app_url "https://example.com"
                        :created_at "2026-01-01T00:00:00Z"
                        :updated_at "2026-01-15T00:00:00Z"}
                  result ((. renderer "render-epic") epic [])]
              (assert.has_substring result "shortcut_type: epic"))))

        (it "renders epic title as heading"
          (fn []
            (let [epic {:id 100
                        :name "My Epic Title"
                        :description ""
                        :state "done"
                        :app_url "https://example.com"
                        :created_at "2026-01-01T00:00:00Z"
                        :updated_at "2026-01-15T00:00:00Z"}
                  result ((. renderer "render-epic") epic [])]
              (assert.has_substring result "# My Epic Title"))))

        (it "renders stories table when provided"
          (fn []
            (let [epic {:id 100
                        :name "Epic"
                        :description ""
                        :state "done"
                        :app_url "https://example.com"
                        :created_at "2026-01-01T00:00:00Z"
                        :updated_at "2026-01-15T00:00:00Z"}
                  stories [(t.make-story {:id 1 :name "Story One"})
                           (t.make-story {:id 2 :name "Story Two"})]
                  result ((. renderer "render-epic") epic stories)]
              (assert.has_substring result "## Stories")
              (assert.has_substring result "Story One")
              (assert.has_substring result "Story Two"))))))

    (describe "vim.NIL handling"
      (fn []
        (it "renders story without crashing when optional fields are vim.NIL"
          (fn []
            (let [story (t.make-story {:epic_id vim.NIL
                                       :iteration_id vim.NIL
                                       :group_id vim.NIL
                                       :estimate vim.NIL})
                  result ((. renderer "render-story") story)]
              (assert.has_frontmatter result)
              (assert.has_substring result "shortcut_id: 12345")
              ;; vim.NIL fields should not appear as "vim.NIL" in output
              (assert.is_nil (string.find result "vim.NIL")))))

        (it "renders story when app_url and dates are vim.NIL"
          (fn []
            (let [story (t.make-story {:app_url vim.NIL
                                       :created_at vim.NIL
                                       :updated_at vim.NIL})
                  result ((. renderer "render-story") story)]
              (assert.has_frontmatter result)
              (assert.is_nil (string.find result "vim.NIL")))))

        (it "renders epic without crashing when stats is vim.NIL"
          (fn []
            (let [epic {:id 100
                        :name "Nil Stats Epic"
                        :description "Test"
                        :state "done"
                        :app_url "https://example.com"
                        :stats vim.NIL
                        :planned_start_date vim.NIL
                        :deadline vim.NIL
                        :created_at "2026-01-01T00:00:00Z"
                        :updated_at "2026-01-15T00:00:00Z"}
                  result ((. renderer "render-epic") epic [])]
              (assert.has_frontmatter result)
              (assert.has_substring result "# Nil Stats Epic")
              ;; Should show 0/0 progress, not crash
              (assert.has_substring result "0/0 stories done")
              (assert.is_nil (string.find result "vim.NIL")))))

        (it "truncates long story names in epic stories table"
          (fn []
            (let [epic {:id 100
                        :name "Epic"
                        :description ""
                        :state "done"
                        :app_url "https://example.com"
                        :created_at "2026-01-01T00:00:00Z"
                        :updated_at "2026-01-15T00:00:00Z"}
                  long-name "This is a very long story name that exceeds forty characters easily"
                  stories [(t.make-story {:id 1 :name long-name})]
                  result ((. renderer "render-epic") epic stories)]
              ;; The link title should be truncated to 40 chars with ellipsis
              (assert.has_substring result "This is a very long story name that e...")
              ;; The full name should NOT appear as the link title
              (assert.is_nil (string.find result (.. "[" long-name "]") 1 true)))))

        (it "does not truncate short story names in epic stories table"
          (fn []
            (let [epic {:id 100
                        :name "Epic"
                        :description ""
                        :state "done"
                        :app_url "https://example.com"
                        :created_at "2026-01-01T00:00:00Z"
                        :updated_at "2026-01-15T00:00:00Z"}
                  short-name "Short Story"
                  stories [(t.make-story {:id 1 :name short-name})]
                  result ((. renderer "render-epic") epic stories)]
              ;; Short name should appear in full
              (assert.has_substring result (.. "[" short-name "]")))))

        (it "renders epic stories table when story fields are vim.NIL"
          (fn []
            (let [epic {:id 100
                        :name "Epic"
                        :description ""
                        :state "done"
                        :app_url "https://example.com"
                        :created_at "2026-01-01T00:00:00Z"
                        :updated_at "2026-01-15T00:00:00Z"}
                  stories [{:id 1
                            :name "Story With Nils"
                            :estimate vim.NIL
                            :completed vim.NIL
                            :started vim.NIL
                            :workflow_state_name vim.NIL
                            :owners []
                            :labels []
                            :tasks []
                            :comments []
                            :description ""
                            :story_type "feature"
                            :app_url "https://example.com/1"
                            :created_at "2026-01-01T00:00:00Z"
                            :updated_at "2026-01-15T00:00:00Z"}]
                  result ((. renderer "render-epic") epic stories)]
              (assert.has_substring result "Story With Nils")
              ;; Should render with fallback "-" values, not "vim.NIL"
              (assert.is_nil (string.find result "vim.NIL")))))))))
