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

    (describe "content-hash"
      (fn []
        (it "normalizes line endings"
          (fn []
            (let [content-hash (. hash "content-hash")
                  hash1 (content-hash "line1\nline2")
                  hash2 (content-hash "line1\r\nline2")]
              (assert.equals hash1 hash2))))

        (it "normalizes trailing whitespace"
          (fn []
            (let [content-hash (. hash "content-hash")
                  hash1 (content-hash "line1\nline2")
                  hash2 (content-hash "line1  \nline2  ")]
              (assert.equals hash1 hash2))))

        (it "trims leading and trailing whitespace"
          (fn []
            (let [content-hash (. hash "content-hash")
                  hash1 (content-hash "content")
                  hash2 (content-hash "  \n  content  \n  ")]
              (assert.equals hash1 hash2))))

        (it "returns valid hash"
          (fn []
            (let [content-hash (. hash "content-hash")
                  result (content-hash "Test content")]
              (assert.is_valid_hash result))))))

    (describe "has-changed"
      (fn []
        (it "returns false when content matches hash"
          (fn []
            (let [content-hash (. hash "content-hash")
                  has-changed (. hash "has-changed")
                  content "Test content"
                  stored-hash (content-hash content)]
              (assert.is_false (has-changed stored-hash content)))))

        (it "returns true when content differs from hash"
          (fn []
            (let [content-hash (. hash "content-hash")
                  has-changed (. hash "has-changed")
                  old-content "Original content"
                  new-content "Modified content"
                  stored-hash (content-hash old-content)]
              (assert.is_true (has-changed stored-hash new-content)))))

        (it "handles whitespace normalization in comparison"
          (fn []
            (let [content-hash (. hash "content-hash")
                  has-changed (. hash "has-changed")
                  content "Test content"
                  stored-hash (content-hash content)
                  content-with-whitespace "  Test content  \n"]
              (assert.is_false (has-changed stored-hash content-with-whitespace)))))))

    (describe "tasks-hash"
      (fn []
        (it "returns valid hash for tasks"
          (fn []
            (let [tasks-hash (. hash "tasks-hash")
                  tasks [{:id 1 :description "Task 1" :complete false}
                         {:id 2 :description "Task 2" :complete true}]
                  result (tasks-hash tasks)]
              (assert.is_valid_hash result))))

        (it "returns consistent hash for same tasks"
          (fn []
            (let [tasks-hash (. hash "tasks-hash")
                  tasks [{:id 1 :description "Task" :complete false}]
                  hash1 (tasks-hash tasks)
                  hash2 (tasks-hash tasks)]
              (assert.equals hash1 hash2))))

        (it "returns different hash for different tasks"
          (fn []
            (let [tasks-hash (. hash "tasks-hash")
                  tasks1 [{:id 1 :description "Task" :complete false}]
                  tasks2 [{:id 1 :description "Task" :complete true}]
                  hash1 (tasks-hash tasks1)
                  hash2 (tasks-hash tasks2)]
              (assert.not_equals hash1 hash2))))

        (it "handles empty task list"
          (fn []
            (let [tasks-hash (. hash "tasks-hash")
                  result (tasks-hash [])]
              (assert.is_valid_hash result))))

        (it "handles nil task list"
          (fn []
            (let [tasks-hash (. hash "tasks-hash")
                  result (tasks-hash nil)]
              (assert.is_valid_hash result))))

        (it "returns same hash regardless of task order"
          (fn []
            (let [tasks-hash (. hash "tasks-hash")
                  tasks1 [{:id 1 :description "First" :complete false}
                          {:id 2 :description "Second" :complete false}]
                  tasks2 [{:id 2 :description "Second" :complete false}
                          {:id 1 :description "First" :complete false}]
                  hash1 (tasks-hash tasks1)
                  hash2 (tasks-hash tasks2)]
              ;; Should be same because tasks are sorted by ID before hashing
              (assert.equals hash1 hash2))))))

    (describe "tasks-changed?"
      (fn []
        (it "returns false when tasks match hash"
          (fn []
            (let [tasks-hash (. hash "tasks-hash")
                  tasks-changed? (. hash "tasks-changed?")
                  tasks [{:id 1 :description "Task" :complete false}]
                  stored-hash (tasks-hash tasks)]
              (assert.is_false (tasks-changed? stored-hash tasks)))))

        (it "returns true when tasks differ from hash"
          (fn []
            (let [tasks-hash (. hash "tasks-hash")
                  tasks-changed? (. hash "tasks-changed?")
                  old-tasks [{:id 1 :description "Task" :complete false}]
                  new-tasks [{:id 1 :description "Task" :complete true}]
                  stored-hash (tasks-hash old-tasks)]
              (assert.is_true (tasks-changed? stored-hash new-tasks)))))))))
