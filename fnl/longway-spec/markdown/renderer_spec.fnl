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
            (let [story (t.make-story {:comments [(t.make-comment {:text "Test comment"})]})
                  result ((. renderer "render-story") story)]
              (assert.has_sync_section result "comments")
              (assert.has_substring result "Test comment"))))

        (it "includes comment author"
          (fn []
            (let [story (t.make-story {:comments [(t.make-comment {:author {:profile {:name "John Doe"}}})]})
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
              (assert.has_substring result "Story Two"))))))))
