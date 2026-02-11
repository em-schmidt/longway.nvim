;; Tests for longway.markdown.frontmatter
;;
;; Tests YAML frontmatter parsing and generation

(require :longway-spec.assertions)
(local frontmatter (require :longway.markdown.frontmatter))

(describe "longway.markdown.frontmatter"
  (fn []
    (describe "parse"
      (fn []
        (it "parses simple key-value pairs"
          (fn []
            (let [content "---
shortcut_id: 12345
story_type: feature
---

# Content"
                  result (frontmatter.parse content)]
              (assert.equals 12345 result.frontmatter.shortcut_id)
              (assert.equals "feature" result.frontmatter.story_type))))

        (it "parses boolean values"
          (fn []
            (let [content "---
enabled: true
disabled: false
---
body"
                  result (frontmatter.parse content)]
              (assert.is_true result.frontmatter.enabled)
              (assert.is_false result.frontmatter.disabled))))

        (it "parses quoted strings"
          (fn []
            (let [content "---
title: \"Hello: World\"
---
body"
                  result (frontmatter.parse content)]
              (assert.equals "Hello: World" result.frontmatter.title))))

        (it "extracts body after frontmatter"
          (fn []
            (let [content "---
id: 123
---

# Title

Body content here."
                  result (frontmatter.parse content)]
              (assert.has_substring result.body "# Title")
              (assert.has_substring result.body "Body content here."))))

        (it "returns empty frontmatter when not present"
          (fn []
            (let [content "# No Frontmatter\n\nJust content."
                  result (frontmatter.parse content)]
              (assert.same {} result.frontmatter)
              (assert.equals content result.body))))

        (it "returns raw frontmatter string"
          (fn []
            (let [content "---
id: 123
name: test
---
body"
                  result (frontmatter.parse content)]
              (assert.is_not_nil result.raw_frontmatter)
              (assert.has_substring result.raw_frontmatter "id: 123"))))

        (it "strips leading and trailing whitespace from body"
          (fn []
            (let [content "---
id: 123
---

# Title"
                  result (frontmatter.parse content)]
              ;; Body should be "# Title" without leading/trailing whitespace
              (assert.equals "# Title" result.body))))

        (it "prevents blank line accumulation on parse-render cycles"
          (fn []
            (let [initial-fm {:shortcut_id 12345 :story_type "feature"}
                  ;; Generate initial content
                  generated (frontmatter.generate initial-fm)
                  initial-content (.. generated "\n\n" "# Test Story")
                  ;; Parse it
                  parsed1 (frontmatter.parse initial-content)
                  ;; Re-generate (simulating an update)
                  regenerated (frontmatter.generate parsed1.frontmatter)
                  updated-content (.. regenerated "\n\n" parsed1.body)
                  ;; Parse again
                  parsed2 (frontmatter.parse updated-content)]
              ;; After parse-render cycle, body should remain the same
              (assert.equals parsed1.body parsed2.body)
              ;; And the full content should have exactly 2 newlines between --- and #
              (let [pattern "---\n\n# Test Story"]
                (assert.is_not_nil (string.find updated-content pattern 1 true))))))))

    (describe "generate"
      (fn []
        (it "generates valid YAML frontmatter"
          (fn []
            (let [data {:shortcut_id 12345 :story_type "feature"}
                  result (frontmatter.generate data)]
              (assert.has_frontmatter result)
              (assert.has_substring result "shortcut_id: 12345"))))

        (it "handles string values"
          (fn []
            (let [data {:name "Test Story"}
                  result (frontmatter.generate data)]
              (assert.has_substring result "name: Test Story"))))

        (it "handles boolean values"
          (fn []
            (let [data {:enabled true :disabled false}
                  result (frontmatter.generate data)]
              (assert.has_substring result "enabled: true")
              (assert.has_substring result "disabled: false"))))

        (it "handles numeric values"
          (fn []
            (let [data {:count 42 :estimate 3.5}
                  result (frontmatter.generate data)]
              (assert.has_substring result "count: 42"))))

        (it "skips internal fields starting with underscore"
          (fn []
            (let [data {:name "Test" :_internal "secret"}
                  result (frontmatter.generate data)]
              (assert.has_substring result "name: Test")
              (assert.is_nil (string.find result "_internal")))))

        (it "handles array values"
          (fn []
            (let [data {:labels ["bug" "urgent"]}
                  result (frontmatter.generate data)]
              (assert.has_substring result "labels:")
              (assert.has_substring result "- bug")
              (assert.has_substring result "- urgent"))))

        (it "omits vim.NIL values from output"
          (fn []
            (let [data {:shortcut_id 12345 :estimate vim.NIL :state "active"}
                  result (frontmatter.generate data)]
              (assert.has_substring result "shortcut_id: 12345")
              (assert.has_substring result "state: active")
              ;; vim.NIL value should be omitted entirely
              (assert.is_nil (string.find result "estimate")))))

        (it "omits vim.NIL values in nested object fields"
          (fn []
            (let [data {:stats {:num_stories 10 :num_points vim.NIL}}
                  result (frontmatter.generate data)]
              (assert.has_substring result "num_stories: 10")
              (assert.is_nil (string.find result "num_points")))))

        (it "omits vim.NIL items in arrays"
          (fn []
            (let [data {:items ["keep" vim.NIL "also_keep"]}
                  result (frontmatter.generate data)]
              (assert.has_substring result "- keep")
              (assert.has_substring result "- also_keep"))))

        (it "omits vim.NIL values in array-of-objects"
          (fn []
            (let [data {:owners [{:name "Alice" :id "uuid-1"} {:name vim.NIL :id "uuid-2"}]}
                  result (frontmatter.generate data)]
              (assert.has_substring result "name: Alice")
              (assert.has_substring result "id: uuid-1")
              ;; The second owner should have id but no name
              (assert.has_substring result "id: uuid-2"))))))))
