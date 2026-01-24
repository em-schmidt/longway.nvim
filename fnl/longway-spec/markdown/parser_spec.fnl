;; Tests for longway.markdown.parser
;;
;; Tests markdown parsing and sync section extraction

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local parser (require :longway.markdown.parser))

(describe "longway.markdown.parser"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "extract-description"
      (fn []
        (it "extracts content from description sync section"
          (fn []
            (let [content "# Title

<!-- BEGIN SHORTCUT SYNC:description -->
This is the description content.
<!-- END SHORTCUT SYNC:description -->"
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
            (let [content "<!-- BEGIN SHORTCUT SYNC:description -->
Line 1
Line 2
Line 3
<!-- END SHORTCUT SYNC:description -->"
                  extract-description (. parser "extract-description")
                  result (extract-description content)]
              (assert.has_substring result "Line 1")
              (assert.has_substring result "Line 2")
              (assert.has_substring result "Line 3"))))))

    (describe "extract-tasks"
      (fn []
        (it "extracts incomplete tasks"
          (fn []
            (let [content "<!-- BEGIN SHORTCUT SYNC:tasks -->
- [ ] Task one <!-- task:1 complete:false -->
<!-- END SHORTCUT SYNC:tasks -->"
                  extract-tasks (. parser "extract-tasks")
                  result (extract-tasks content)]
              (assert.equals 1 (length result))
              (assert.equals "Task one" (. result 1 :description))
              (assert.is_false (. result 1 :complete)))))

        (it "extracts complete tasks"
          (fn []
            (let [content "<!-- BEGIN SHORTCUT SYNC:tasks -->
- [x] Done task <!-- task:2 complete:true -->
<!-- END SHORTCUT SYNC:tasks -->"
                  extract-tasks (. parser "extract-tasks")
                  result (extract-tasks content)]
              (assert.equals 1 (length result))
              (assert.is_true (. result 1 :complete)))))

        (it "extracts task IDs"
          (fn []
            (let [content "<!-- BEGIN SHORTCUT SYNC:tasks -->
- [ ] Task <!-- task:12345 complete:false -->
<!-- END SHORTCUT SYNC:tasks -->"
                  extract-tasks (. parser "extract-tasks")
                  result (extract-tasks content)]
              (assert.equals 12345 (. result 1 :id)))))

        (it "handles new tasks without ID"
          (fn []
            (let [content "<!-- BEGIN SHORTCUT SYNC:tasks -->
- [ ] New task <!-- task:new complete:false -->
<!-- END SHORTCUT SYNC:tasks -->"
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
            (let [content "<!-- BEGIN SHORTCUT SYNC:tasks -->
- [ ] First <!-- task:1 complete:false -->
- [x] Second <!-- task:2 complete:true -->
- [ ] Third <!-- task:3 complete:false -->
<!-- END SHORTCUT SYNC:tasks -->"
                  extract-tasks (. parser "extract-tasks")
                  result (extract-tasks content)]
              (assert.equals 3 (length result)))))))

    (describe "extract-comments"
      (fn []
        (it "extracts comment author and text"
          (fn []
            (let [content "<!-- BEGIN SHORTCUT SYNC:comments -->
---
**John Doe** · 2026-01-10 10:30 <!-- comment:123 -->

This is my comment.
<!-- END SHORTCUT SYNC:comments -->"
                  extract-comments (. parser "extract-comments")
                  result (extract-comments content)]
              (assert.equals 1 (length result))
              (assert.equals "John Doe" (. result 1 :author))
              (assert.has_substring (. result 1 :text) "This is my comment"))))

        (it "extracts comment IDs"
          (fn []
            (let [content "<!-- BEGIN SHORTCUT SYNC:comments -->
---
**Author** · 2026-01-10 10:30 <!-- comment:456 -->

Comment text
<!-- END SHORTCUT SYNC:comments -->"
                  extract-comments (. parser "extract-comments")
                  result (extract-comments content)]
              (assert.equals 456 (. result 1 :id)))))

        (it "returns empty array when no comments section"
          (fn []
            (let [content "# No comments"
                  extract-comments (. parser "extract-comments")
                  result (extract-comments content)]
              (assert.same [] result))))))

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
              (assert.equals "story" result.frontmatter.shortcut_type))))))

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
