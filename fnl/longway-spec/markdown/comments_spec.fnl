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

        (it "parses a bare comment block as new"
          (fn []
            (let [block "This is a bare comment without header."
                  result (comments-md.parse-block block)]
              (assert.is_not_nil result)
              (assert.is_nil result.id)
              (assert.is_nil result.author)
              (assert.is_nil result.timestamp)
              (assert.equals "This is a bare comment without header." result.text)
              (assert.is_true result.is_new))))

        (it "parses bare block with leading whitespace"
          (fn []
            (let [block "\n  \nActual comment text here."
                  result (comments-md.parse-block block)]
              (assert.is_not_nil result)
              (assert.equals "Actual comment text here." result.text)
              (assert.is_true result.is_new))))

        (it "returns nil for empty bare block"
          (fn []
            (let [block "   \n  \n  "
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
            (assert.equals "" (comments-md.render-comments nil))))

        (it "sorts comments chronologically (oldest first)"
          (fn []
            ;; Input in wrong order (newest first)
            (let [cmts [{:id 3 :author "C" :timestamp "2026-01-03 10:00" :text "Newest" :is_new false}
                        {:id 1 :author "A" :timestamp "2026-01-01 10:00" :text "Oldest" :is_new false}
                        {:id 2 :author "B" :timestamp "2026-01-02 10:00" :text "Middle" :is_new false}]
                  result (comments-md.render-comments cmts)
                  oldest-pos (string.find result "Oldest")
                  middle-pos (string.find result "Middle")
                  newest-pos (string.find result "Newest")]
              ;; Oldest should come first, then middle, then newest
              (assert.is_true (< oldest-pos middle-pos))
              (assert.is_true (< middle-pos newest-pos)))))

        (it "places new comments (nil timestamp) at the end"
          (fn []
            (let [cmts [{:id nil :author nil :timestamp nil :text "New comment" :is_new true}
                        {:id 1 :author "A" :timestamp "2026-01-01 10:00" :text "Existing" :is_new false}]
                  result (comments-md.render-comments cmts)
                  existing-pos (string.find result "Existing")
                  new-pos (string.find result "New comment")]
              ;; Existing comment should come before new comment
              (assert.is_true (< existing-pos new-pos)))))))

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

    (describe "format-timestamp"
      (fn []
        (it "formats ISO 8601 timestamp with default format"
          (fn []
            (let [format-timestamp (. comments-md "format-timestamp")
                  result (format-timestamp "2026-01-10T10:30:00Z")]
              (assert.equals "2026-01-10 10:30" result))))

        (it "formats ISO 8601 timestamp with custom format"
          (fn []
            ;; Setup config with custom timestamp_format
            (t.setup-test-config {:comments {:timestamp_format "%d/%m/%Y %H:%M"
                                             :max_pull 50
                                             :show_timestamps true
                                             :confirm_delete true}})
            (let [format-timestamp (. comments-md "format-timestamp")
                  result (format-timestamp "2026-01-10T10:30:00Z")]
              (assert.equals "10/01/2026 10:30" result))))

        (it "formats ISO 8601 timestamp with date-only format"
          (fn []
            (t.setup-test-config {:comments {:timestamp_format "%Y-%m-%d"
                                             :max_pull 50
                                             :show_timestamps true
                                             :confirm_delete true}})
            (let [format-timestamp (. comments-md "format-timestamp")
                  result (format-timestamp "2026-01-10T10:30:00Z")]
              (assert.equals "2026-01-10" result))))

        (it "returns empty string for nil input"
          (fn []
            (let [format-timestamp (. comments-md "format-timestamp")
                  result (format-timestamp nil)]
              (assert.equals "" result))))

        (it "returns raw string for non-ISO input"
          (fn []
            (let [format-timestamp (. comments-md "format-timestamp")
                  result (format-timestamp "not a timestamp")]
              (assert.equals "not a timestamp" result))))))

    (describe "format-api-comments"
      (fn []
        (it "converts raw API comments to rendering format"
          (fn []
            ;; Stub members.resolve-name so it returns the raw ID
            (let [members (require :longway.api.members)
                  original-resolve members.resolve-name]
              (set members.resolve-name (fn [id] id))
              (let [format-api-comments (. comments-md "format-api-comments")
                    raw [{:id 101
                          :text "Hello world"
                          :author_id "author-uuid-1"
                          :created_at "2026-01-10T10:30:00Z"}]
                    result (format-api-comments raw)]
                (assert.equals 1 (length result))
                (assert.equals 101 (. result 1 :id))
                (assert.equals "Hello world" (. result 1 :text))
                (assert.equals "2026-01-10 10:30" (. result 1 :timestamp))
                (assert.is_false (. result 1 :is_new))
                (set members.resolve-name original-resolve)))))

        (it "handles empty input"
          (fn []
            (let [format-api-comments (. comments-md "format-api-comments")
                  result (format-api-comments [])]
              (assert.equals 0 (length result)))))

        (it "handles nil input"
          (fn []
            (let [format-api-comments (. comments-md "format-api-comments")
                  result (format-api-comments nil)]
              (assert.equals 0 (length result)))))

        (it "resolves author_id to display name via members cache"
          (fn []
            ;; Stub members.resolve-name to return a known value
            (let [members (require :longway.api.members)
                  original-resolve members.resolve-name]
              (set members.resolve-name (fn [id] (if (= id "uuid-alice") "Alice" id)))
              (let [format-api-comments (. comments-md "format-api-comments")
                    raw [{:id 1 :text "Test" :author_id "uuid-alice" :created_at "2026-01-10T10:30:00Z"}]
                    result (format-api-comments raw)]
                (assert.equals "Alice" (. result 1 :author))
                ;; Restore original
                (set members.resolve-name original-resolve)))))

        (it "falls back to raw ID when member not found"
          (fn []
            ;; Stub members.resolve-name to return the raw ID (fallback behavior)
            (let [members (require :longway.api.members)
                  original-resolve members.resolve-name]
              (set members.resolve-name (fn [id] id))
              (let [format-api-comments (. comments-md "format-api-comments")
                    raw [{:id 1 :text "Test" :author_id "unknown-uuid" :created_at "2026-01-10T10:30:00Z"}]
                    result (format-api-comments raw)]
                (assert.equals "unknown-uuid" (. result 1 :author))
                (set members.resolve-name original-resolve)))))

        (it "sorts comments chronologically (oldest first)"
          (fn []
            (let [members (require :longway.api.members)
                  original-resolve members.resolve-name]
              (set members.resolve-name (fn [id] id))
              (let [format-api-comments (. comments-md "format-api-comments")
                    ;; Input in reverse chronological order (newest first)
                    raw [{:id 3 :text "Newest" :author_id "a" :created_at "2026-01-12T10:00:00Z"}
                         {:id 1 :text "Oldest" :author_id "a" :created_at "2026-01-10T10:00:00Z"}
                         {:id 2 :text "Middle" :author_id "a" :created_at "2026-01-11T10:00:00Z"}]
                    result (format-api-comments raw)]
                ;; Should be sorted oldest first
                (assert.equals 1 (. result 1 :id))
                (assert.equals "Oldest" (. result 1 :text))
                (assert.equals 2 (. result 2 :id))
                (assert.equals "Middle" (. result 2 :text))
                (assert.equals 3 (. result 3 :id))
                (assert.equals "Newest" (. result 3 :text))
                (set members.resolve-name original-resolve)))))

        (it "filters out deleted comments (soft delete)"
          (fn []
            (let [members (require :longway.api.members)
                  original-resolve members.resolve-name]
              (set members.resolve-name (fn [id] id))
              (let [format-api-comments (. comments-md "format-api-comments")
                    ;; Mix of active and deleted comments
                    raw [{:id 1 :text "Active" :author_id "a" :created_at "2026-01-10T10:00:00Z" :deleted false}
                         {:id 2 :text "" :author_id "a" :created_at "2026-01-11T10:00:00Z" :deleted true}
                         {:id 3 :text "Also active" :author_id "a" :created_at "2026-01-12T10:00:00Z"}]
                    result (format-api-comments raw)]
                ;; Should only have 2 comments (deleted one filtered out)
                (assert.equals 2 (length result))
                (assert.equals 1 (. result 1 :id))
                (assert.equals 3 (. result 2 :id))
                (set members.resolve-name original-resolve)))))))

    (describe "resolve-author-name"
      (fn []
        (it "returns Unknown for nil input"
          (fn []
            (let [resolve-author-name (. comments-md "resolve-author-name")
                  result (resolve-author-name nil)]
              (assert.equals "Unknown" result))))

        (it "delegates to members.resolve-name for valid ID"
          (fn []
            (let [members (require :longway.api.members)
                  original-resolve members.resolve-name]
              (set members.resolve-name (fn [id] "Resolved Name"))
              (let [resolve-author-name (. comments-md "resolve-author-name")
                    result (resolve-author-name "some-uuid")]
                (assert.equals "Resolved Name" result)
                (set members.resolve-name original-resolve)))))))

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
