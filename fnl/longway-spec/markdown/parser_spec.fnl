;; Tests for longway.markdown.parser
;;
;; Tests markdown parsing and header-based section extraction

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local parser (require :longway.markdown.parser))

(describe "longway.markdown.parser"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "extract-description"
      (fn []
        (it "extracts content from description section"
          (fn []
            (let [content "# Title\n\n## Description\n\nThis is the description content.\n\n## Tasks\n\nsome tasks"
                  extract-description (. parser "extract-description")
                  result (extract-description content)]
              (assert.equals "This is the description content." result))))

        (it "returns nil when no description section"
          (fn []
            (let [content "# Title\n\nJust regular content."
                  extract-description (. parser "extract-description")
                  result (extract-description content)]
              (assert.is_nil result))))

        (it "handles multiline description"
          (fn []
            (let [content "# Title\n\n## Description\n\nLine 1\nLine 2\nLine 3\n\n## Tasks\n"
                  extract-description (. parser "extract-description")
                  result (extract-description content)]
              (assert.has_substring result "Line 1")
              (assert.has_substring result "Line 2")
              (assert.has_substring result "Line 3"))))

        (it "extracts description that goes to EOF"
          (fn []
            (let [content "# Title\n\n## Description\n\nDescription to the end."
                  extract-description (. parser "extract-description")
                  result (extract-description content)]
              (assert.equals "Description to the end." result))))

        (it "handles empty description section"
          (fn []
            (let [content "# Title\n\n## Description\n\n## Tasks\n"
                  extract-description (. parser "extract-description")
                  result (extract-description content)]
              (assert.equals "" result))))

        (it "allows ### subheadings inside description"
          (fn []
            (let [content "# Title\n\n## Description\n\nSome text\n\n### Details\n\nMore details\n\n## Tasks\n"
                  extract-description (. parser "extract-description")
                  result (extract-description content)]
              (assert.has_substring result "### Details")
              (assert.has_substring result "More details"))))))

    (describe "extract-tasks"
      (fn []
        (it "extracts incomplete tasks"
          (fn []
            (let [content "## Description\n\nDesc\n\n## Tasks\n\n- [ ] Task one <!-- task:1 complete:false -->\n\n## Comments\n"
                  extract-tasks (. parser "extract-tasks")
                  result (extract-tasks content)]
              (assert.equals 1 (length result))
              (assert.equals "Task one" (. result 1 :description))
              (assert.is_false (. result 1 :complete)))))

        (it "extracts complete tasks"
          (fn []
            (let [content "## Tasks\n\n- [x] Done task <!-- task:2 complete:true -->\n\n## Comments\n"
                  extract-tasks (. parser "extract-tasks")
                  result (extract-tasks content)]
              (assert.equals 1 (length result))
              (assert.is_true (. result 1 :complete)))))

        (it "extracts task IDs"
          (fn []
            (let [content "## Tasks\n\n- [ ] Task <!-- task:12345 complete:false -->\n\n## Comments\n"
                  extract-tasks (. parser "extract-tasks")
                  result (extract-tasks content)]
              (assert.equals 12345 (. result 1 :id)))))

        (it "handles new tasks without ID"
          (fn []
            (let [content "## Tasks\n\n- [ ] New task <!-- task:new complete:false -->\n\n## Comments\n"
                  extract-tasks (. parser "extract-tasks")
                  result (extract-tasks content)]
              (assert.is_nil (. result 1 :id))
              (assert.is_true (. result 1 :is_new)))))

        (it "returns empty array when no tasks section"
          (fn []
            (let [content "# No tasks here"
                  extract-tasks (. parser "extract-tasks")
                  result (extract-tasks content)]
              (assert.same [] result))))

        (it "extracts multiple tasks"
          (fn []
            (let [content "## Tasks\n\n- [ ] First <!-- task:1 complete:false -->\n- [x] Second <!-- task:2 complete:true -->\n- [ ] Third <!-- task:3 complete:false -->\n\n## Comments\n"
                  extract-tasks (. parser "extract-tasks")
                  result (extract-tasks content)]
              (assert.equals 3 (length result)))))))

    (describe "extract-comments"
      (fn []
        (it "extracts comment author and text"
          (fn []
            (let [content "## Comments\n\n---\n**John Doe** · 2026-01-10 10:30 <!-- comment:123 -->\n\nThis is my comment.\n\n## Local Notes\n"
                  extract-comments (. parser "extract-comments")
                  result (extract-comments content)]
              (assert.equals 1 (length result))
              (assert.equals "John Doe" (. result 1 :author))
              (assert.has_substring (. result 1 :text) "This is my comment"))))

        (it "extracts comment IDs"
          (fn []
            (let [content "## Comments\n\n---\n**Author** · 2026-01-10 10:30 <!-- comment:456 -->\n\nComment text\n\n## Local Notes\n"
                  extract-comments (. parser "extract-comments")
                  result (extract-comments content)]
              (assert.equals 456 (. result 1 :id)))))

        (it "returns empty array when no comments section"
          (fn []
            (let [content "# No comments"
                  extract-comments (. parser "extract-comments")
                  result (extract-comments content)]
              (assert.same [] result))))))

    (describe "extract-local-notes"
      (fn []
        (it "extracts local notes section with user content"
          (fn []
            (let [content "# Title\n\n## Description\n\nSome desc\n\n## Local Notes\n\n<!-- This section is NOT synced to Shortcut -->\n\nMy custom notes here\n"
                  extract-local-notes (. parser "extract-local-notes")
                  result (extract-local-notes content)]
              (assert.is_not_nil result)
              (assert.has_substring result "## Local Notes")
              (assert.has_substring result "My custom notes here"))))

        (it "returns nil when no local notes section exists"
          (fn []
            (let [content "# Title\n\n## Description\n\nSome content\n"
                  extract-local-notes (. parser "extract-local-notes")
                  result (extract-local-notes content)]
              (assert.is_nil result))))

        (it "preserves multi-line local notes content"
          (fn []
            (let [content "# Title\n\n## Local Notes\n\n<!-- This section is NOT synced to Shortcut -->\n\n### My Heading\n\n- Item 1\n- Item 2\n\nSome paragraph.\n"
                  extract-local-notes (. parser "extract-local-notes")
                  result (extract-local-notes content)]
              (assert.has_substring result "### My Heading")
              (assert.has_substring result "- Item 1")
              (assert.has_substring result "Some paragraph."))))

        (it "extracts blank local notes template"
          (fn []
            (let [content "# Title\n\n## Local Notes\n\n<!-- This section is NOT synced to Shortcut -->\n"
                  extract-local-notes (. parser "extract-local-notes")
                  result (extract-local-notes content)]
              (assert.is_not_nil result)
              (assert.has_substring result "## Local Notes"))))))

    (describe "parse"
      (fn []
        (it "parses complete markdown file"
          (fn []
            (let [content (t.sample-markdown)
                  result (parser.parse content)]
              (assert.is_not_nil result.frontmatter)
              (assert.is_not_nil result.description)
              (assert.is_table result.tasks)
              (assert.is_table result.comments))))

        (it "extracts frontmatter fields"
          (fn []
            (let [content (t.sample-markdown)
                  result (parser.parse content)]
              (assert.equals 12345 result.frontmatter.shortcut_id)
              (assert.equals "story" result.frontmatter.shortcut_type))))

        (it "includes local_notes in parsed result"
          (fn []
            (let [content (t.sample-markdown)
                  result (parser.parse content)]
              (assert.is_not_nil result.local_notes)
              (assert.has_substring result.local_notes "## Local Notes"))))))

    (describe "legacy sync marker fallback"
      (fn []
        (it "falls back to legacy sync markers when headers not found"
          (fn []
            ;; Stub notify.warn to avoid side effects
            (let [notify (require :longway.ui.notify)
                  original-warn notify.warn]
              (set notify.warn (fn []))
              (let [content "# Title\n\n<!-- BEGIN SHORTCUT SYNC:description -->\nLegacy description.\n<!-- END SHORTCUT SYNC:description -->"
                    extract-description (. parser "extract-description")
                    result (extract-description content)]
                (assert.equals "Legacy description." result)
                (set notify.warn original-warn)))))))

    (describe "get-shortcut-id"
      (fn []
        (it "extracts ID from frontmatter"
          (fn []
            (let [content (t.sample-markdown)
                  get-shortcut-id (. parser "get-shortcut-id")
                  result (get-shortcut-id content)]
              (assert.equals 12345 result))))

        (it "returns nil when no ID"
          (fn []
            (let [content "# No frontmatter"
                  get-shortcut-id (. parser "get-shortcut-id")
                  result (get-shortcut-id content)]
              (assert.is_nil result))))))

    (describe "is-longway-file"
      (fn []
        (it "returns true for longway files"
          (fn []
            (let [content (t.sample-markdown)
                  is-longway-file (. parser "is-longway-file")]
              (assert.is_true (is-longway-file content)))))

        (it "returns false for regular markdown"
          (fn []
            (let [content "# Regular File\n\nJust content."
                  is-longway-file (. parser "is-longway-file")]
              (assert.is_false (is-longway-file content)))))))))
