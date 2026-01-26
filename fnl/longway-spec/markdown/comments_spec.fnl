;; Tests for longway.markdown.comments
;;
;; Tests comment markdown parsing and rendering

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local comments-md (require :longway.markdown.comments))
(local hash (require :longway.util.hash))

(describe "longway.markdown.comments"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "parse-block"
      (fn []
        (it "parses a valid comment block"
          (fn []
            (let [block "**Test Author** · 2026-01-10 10:30 <!-- comment:11111 -->\n\nThis is a comment."
                  result (comments-md.parse-block block)]
              (assert.is_not_nil result)
              (assert.equals "Test Author" result.author)
              (assert.equals "2026-01-10 10:30" result.timestamp)
              (assert.equals 11111 result.id)
              (assert.is_false result.is_new)
              (assert.equals "This is a comment." result.text))))

        (it "parses a new comment block"
          (fn []
            (let [block "**My Name** · 2026-01-20 15:00 <!-- comment:new -->\n\nBrand new comment."
                  result (comments-md.parse-block block)]
              (assert.is_not_nil result)
              (assert.equals "My Name" result.author)
              (assert.is_nil result.id)
              (assert.is_true result.is_new)
              (assert.equals "Brand new comment." result.text))))

        (it "returns nil for invalid block"
          (fn []
            (let [block "Just plain text without metadata"
                  result (comments-md.parse-block block)]
              (assert.is_nil result))))

        (it "handles multi-line comment text"
          (fn []
            (let [block "**Author** · 2026-01-10 10:30 <!-- comment:222 -->\n\nLine one\nLine two\nLine three"
                  result (comments-md.parse-block block)]
              (assert.is_not_nil result)
              (assert.has_substring result.text "Line one")
              (assert.has_substring result.text "Line two")
              (assert.has_substring result.text "Line three"))))

        (it "handles empty comment text"
          (fn []
            (let [block "**Author** · 2026-01-10 10:30 <!-- comment:333 -->"
                  result (comments-md.parse-block block)]
              (assert.is_not_nil result)
              (assert.equals "" result.text))))))

    (describe "parse-section"
      (fn []
        (it "parses multiple comments"
          (fn []
            (let [content "---\n**Author A** · 2026-01-10 10:00 <!-- comment:111 -->\n\nFirst comment.\n\n---\n**Author B** · 2026-01-10 11:00 <!-- comment:222 -->\n\nSecond comment."
                  result (comments-md.parse-section content)]
              (assert.equals 2 (length result))
              (assert.equals "Author A" (. result 1 :author))
              (assert.equals "Author B" (. result 2 :author)))))

        (it "handles empty content"
          (fn []
            (let [result (comments-md.parse-section "")]
              (assert.equals 0 (length result)))))

        (it "handles content with only separators"
          (fn []
            (let [result (comments-md.parse-section "---\n---\n---")]
              (assert.equals 0 (length result)))))))

    (describe "render-comment"
      (fn []
        (it "renders a comment with all fields"
          (fn []
            (let [cmt {:id 123 :author "John" :timestamp "2026-01-10 10:30" :text "Hello world" :is_new false}
                  result (comments-md.render-comment cmt)]
              (assert.has_substring result "---")
              (assert.has_substring result "**John**")
              (assert.has_substring result "2026-01-10 10:30")
              (assert.has_substring result "comment:123")
              (assert.has_substring result "Hello world"))))

        (it "renders a new comment"
          (fn []
            (let [cmt {:author "Jane" :timestamp "2026-01-20 15:00" :text "New!" :is_new true}
                  result (comments-md.render-comment cmt)]
              (assert.has_substring result "comment:new")
              (assert.has_substring result "**Jane**")
              (assert.has_substring result "New!"))))))

    (describe "render-comments"
      (fn []
        (it "renders multiple comments"
          (fn []
            (let [cmts [{:id 1 :author "A" :timestamp "2026-01-01 10:00" :text "First" :is_new false}
                        {:id 2 :author "B" :timestamp "2026-01-02 10:00" :text "Second" :is_new false}]
                  result (comments-md.render-comments cmts)]
              (assert.has_substring result "First")
              (assert.has_substring result "Second"))))

        (it "returns empty string for no comments"
          (fn []
            (assert.equals "" (comments-md.render-comments []))
            (assert.equals "" (comments-md.render-comments nil))))))

    (describe "render-section"
      (fn []
        (it "wraps comments in sync markers"
          (fn []
            (let [cmts [{:id 1 :author "A" :timestamp "2026-01-01 10:00" :text "Comment" :is_new false}]
                  result (comments-md.render-section cmts)]
              (assert.has_substring result "<!-- BEGIN SHORTCUT SYNC:comments -->")
              (assert.has_substring result "<!-- END SHORTCUT SYNC:comments -->")
              (assert.has_substring result "Comment"))))))

    (describe "comment-changed?"
      (fn []
        (it "detects text change"
          (fn []
            (let [local-cmt {:id 1 :text "Updated text"}
                  remote-cmt {:id 1 :text "Original text"}
                  comment-changed? (. comments-md "comment-changed?")]
              (assert.is_true (comment-changed? local-cmt remote-cmt)))))

        (it "returns false for same text"
          (fn []
            (let [local-cmt {:id 1 :text "Same text"}
                  remote-cmt {:id 1 :text "Same text"}
                  comment-changed? (. comments-md "comment-changed?")]
              (assert.is_false (comment-changed? local-cmt remote-cmt)))))

        (it "ignores leading/trailing whitespace"
          (fn []
            (let [local-cmt {:id 1 :text "  Text  "}
                  remote-cmt {:id 1 :text "Text"}
                  comment-changed? (. comments-md "comment-changed?")]
              (assert.is_false (comment-changed? local-cmt remote-cmt)))))

        (it "handles nil text"
          (fn []
            (let [local-cmt {:id 1 :text nil}
                  remote-cmt {:id 1 :text nil}
                  comment-changed? (. comments-md "comment-changed?")]
              (assert.is_false (comment-changed? local-cmt remote-cmt)))))))

    (describe "find-comment-by-id"
      (fn []
        (it "finds comment by ID"
          (fn []
            (let [cmts [{:id 1 :text "First"}
                        {:id 2 :text "Second"}
                        {:id 3 :text "Third"}]
                  find-comment-by-id (. comments-md "find-comment-by-id")
                  result (find-comment-by-id cmts 2)]
              (assert.is_not_nil result)
              (assert.equals "Second" result.text))))

        (it "returns nil when not found"
          (fn []
            (let [cmts [{:id 1 :text "First"}]
                  find-comment-by-id (. comments-md "find-comment-by-id")
                  result (find-comment-by-id cmts 999)]
              (assert.is_nil result))))))

    (describe "comments-equal?"
      (fn []
        (it "returns true for identical lists"
          (fn []
            (let [a [{:id 1 :text "Hello"}]
                  b [{:id 1 :text "Hello"}]
                  comments-equal? (. comments-md "comments-equal?")]
              (assert.is_true (comments-equal? a b)))))

        (it "returns false for different lengths"
          (fn []
            (let [a [{:id 1 :text "Hello"}]
                  b [{:id 1 :text "Hello"} {:id 2 :text "World"}]
                  comments-equal? (. comments-md "comments-equal?")]
              (assert.is_false (comments-equal? a b)))))

        (it "returns false for different text"
          (fn []
            (let [a [{:id 1 :text "Hello"}]
                  b [{:id 1 :text "Goodbye"}]
                  comments-equal? (. comments-md "comments-equal?")]
              (assert.is_false (comments-equal? a b)))))

        (it "returns true for two empty lists"
          (fn []
            (let [comments-equal? (. comments-md "comments-equal?")]
              (assert.is_true (comments-equal? [] [])))))))

    (describe "round-trip parse-render"
      (fn []
        (it "parsed comment can be re-rendered with same metadata"
          (fn []
            (let [original-block "**Author** · 2026-01-10 10:30 <!-- comment:456 -->\n\nSome text here"
                  parsed (comments-md.parse-block original-block)
                  rendered (comments-md.render-comment parsed)]
              (assert.has_substring rendered "comment:456")
              (assert.has_substring rendered "**Author**")
              (assert.has_substring rendered "Some text here"))))

        (it "comments hash is stable across render-parse cycles"
          (fn []
            (let [cmts [{:id 1 :text "Comment A"} {:id 2 :text "Comment B"}]
                  hash1 (hash.comments-hash cmts)
                  hash2 (hash.comments-hash cmts)]
              ;; Same input produces same hash
              (assert.equals hash1 hash2)
              ;; Changing text changes the hash
              (let [modified [{:id 1 :text "Changed"} {:id 2 :text "Comment B"}]
                    hash3 (hash.comments-hash modified)]
                (assert.is_not.equals hash1 hash3)))))))))
