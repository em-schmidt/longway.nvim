;; Tests for longway.util.hash
;;
;; Tests content hashing functions

(require :longway-spec.assertions)
(local hash (require :longway.util.hash))

(describe "longway.util.hash"
  (fn []
    (describe "djb2"
      (fn []
        (it "returns 8-character hex string"
          (fn []
            (let [result (hash.djb2 "hello")]
              (assert.is_valid_hash result))))

        (it "returns consistent hash for same input"
          (fn []
            (let [hash1 (hash.djb2 "test string")
                  hash2 (hash.djb2 "test string")]
              (assert.equals hash1 hash2))))

        (it "returns different hash for different input"
          (fn []
            (let [hash1 (hash.djb2 "hello")
                  hash2 (hash.djb2 "world")]
              (assert.not_equals hash1 hash2))))

        (it "handles empty string"
          (fn []
            (let [result (hash.djb2 "")]
              (assert.is_valid_hash result))))

        (it "handles long strings"
          (fn []
            (let [long-string (string.rep "a" 10000)
                  result (hash.djb2 long-string)]
              (assert.is_valid_hash result))))))

    (describe "content_hash"
      (fn []
        (it "normalizes line endings"
          (fn []
            (let [hash1 (hash.content_hash "line1\nline2")
                  hash2 (hash.content_hash "line1\r\nline2")]
              (assert.equals hash1 hash2))))

        (it "normalizes trailing whitespace"
          (fn []
            (let [hash1 (hash.content_hash "line1\nline2")
                  hash2 (hash.content_hash "line1  \nline2  ")]
              (assert.equals hash1 hash2))))

        (it "trims leading and trailing whitespace"
          (fn []
            (let [hash1 (hash.content_hash "content")
                  hash2 (hash.content_hash "  \n  content  \n  ")]
              (assert.equals hash1 hash2))))

        (it "returns valid hash"
          (fn []
            (let [result (hash.content_hash "Test content")]
              (assert.is_valid_hash result))))))

    (describe "has_changed"
      (fn []
        (it "returns false when content matches hash"
          (fn []
            (let [content "Test content"
                  stored-hash (hash.content_hash content)]
              (assert.is_false (hash.has_changed stored-hash content)))))

        (it "returns true when content differs from hash"
          (fn []
            (let [old-content "Original content"
                  new-content "Modified content"
                  stored-hash (hash.content_hash old-content)]
              (assert.is_true (hash.has_changed stored-hash new-content)))))

        (it "handles whitespace normalization in comparison"
          (fn []
            (let [content "Test content"
                  stored-hash (hash.content_hash content)
                  content-with-whitespace "  Test content  \n"]
              (assert.is_false (hash.has_changed stored-hash content-with-whitespace)))))))))
