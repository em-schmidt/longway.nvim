;; Tests for longway.sync.diff
;;
;; Tests change detection and sync classification

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local diff (require :longway.sync.diff))
(local hash (require :longway.util.hash))

(describe "longway.sync.diff"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "first-sync?"
      (fn []
        (it "returns true when sync_hash is empty string"
          (fn []
            (let [first-sync? (. diff "first-sync?")
                  fm {:sync_hash ""}]
              (assert.is_true (first-sync? fm)))))

        (it "returns true when sync_hash is nil"
          (fn []
            (let [first-sync? (. diff "first-sync?")
                  fm {}]
              (assert.is_true (first-sync? fm)))))

        (it "returns false when sync_hash has a value"
          (fn []
            (let [first-sync? (. diff "first-sync?")
                  fm {:sync_hash "abc12345"}]
              (assert.is_false (first-sync? fm)))))))

    (describe "compute-section-hashes"
      (fn []
        (it "returns valid hashes for all sections"
          (fn []
            (let [compute (. diff "compute-section-hashes")
                  parsed {:description "Some description"
                          :tasks [{:id 1 :description "Task" :complete false}]
                          :comments [{:id 1 :text "Comment"}]
                          :frontmatter {}}
                  result (compute parsed)]
              (assert.is_valid_hash result.description)
              (assert.is_valid_hash result.tasks)
              (assert.is_valid_hash result.comments))))

        (it "matches hash module output for description"
          (fn []
            (let [compute (. diff "compute-section-hashes")
                  content-hash (. hash "content-hash")
                  desc "Test description content"
                  parsed {:description desc :tasks [] :comments [] :frontmatter {}}
                  result (compute parsed)]
              (assert.equals (content-hash desc) result.description))))

        (it "matches hash module output for tasks"
          (fn []
            (let [compute (. diff "compute-section-hashes")
                  tasks [{:id 1 :description "A" :complete false}
                         {:id 2 :description "B" :complete true}]
                  parsed {:description "" :tasks tasks :comments [] :frontmatter {}}
                  result (compute parsed)]
              (assert.equals (hash.tasks-hash tasks) result.tasks))))

        (it "matches hash module output for comments"
          (fn []
            (let [compute (. diff "compute-section-hashes")
                  comments [{:id 1 :text "Hello"} {:id 2 :text "World"}]
                  parsed {:description "" :tasks [] :comments comments :frontmatter {}}
                  result (compute parsed)]
              (assert.equals (hash.comments-hash comments) result.comments))))

        (it "handles nil sections gracefully"
          (fn []
            (let [compute (. diff "compute-section-hashes")
                  parsed {:frontmatter {}}
                  result (compute parsed)]
              (assert.is_valid_hash result.description)
              (assert.is_valid_hash result.tasks)
              (assert.is_valid_hash result.comments))))))

    (describe "detect-local-changes"
      (fn []
        (it "returns all false when hashes match"
          (fn []
            (let [detect (. diff "detect-local-changes")
                  content-hash (. hash "content-hash")
                  desc "My description"
                  tasks [{:id 1 :description "Task" :complete false}]
                  comments [{:id 1 :text "Comment"}]
                  parsed {:description desc
                          :tasks tasks
                          :comments comments
                          :frontmatter {:sync_hash (content-hash desc)
                                        :tasks_hash (hash.tasks-hash tasks)
                                        :comments_hash (hash.comments-hash comments)}}
                  result (detect parsed)]
              (assert.is_false result.description)
              (assert.is_false result.tasks)
              (assert.is_false result.comments))))

        (it "detects description change"
          (fn []
            (let [detect (. diff "detect-local-changes")
                  content-hash (. hash "content-hash")
                  parsed {:description "New description"
                          :tasks []
                          :comments []
                          :frontmatter {:sync_hash (content-hash "Old description")
                                        :tasks_hash (hash.tasks-hash [])
                                        :comments_hash (hash.comments-hash [])}}
                  result (detect parsed)]
              (assert.is_true result.description)
              (assert.is_false result.tasks)
              (assert.is_false result.comments))))

        (it "detects task change"
          (fn []
            (let [detect (. diff "detect-local-changes")
                  content-hash (. hash "content-hash")
                  old-tasks [{:id 1 :description "Task" :complete false}]
                  new-tasks [{:id 1 :description "Task" :complete true}]
                  parsed {:description ""
                          :tasks new-tasks
                          :comments []
                          :frontmatter {:sync_hash (content-hash "")
                                        :tasks_hash (hash.tasks-hash old-tasks)
                                        :comments_hash (hash.comments-hash [])}}
                  result (detect parsed)]
              (assert.is_false result.description)
              (assert.is_true result.tasks)
              (assert.is_false result.comments))))

        (it "detects comment change"
          (fn []
            (let [detect (. diff "detect-local-changes")
                  content-hash (. hash "content-hash")
                  old-comments [{:id 1 :text "Old text"}]
                  new-comments [{:id 1 :text "New text"}]
                  parsed {:description ""
                          :tasks []
                          :comments new-comments
                          :frontmatter {:sync_hash (content-hash "")
                                        :tasks_hash (hash.tasks-hash [])
                                        :comments_hash (hash.comments-hash old-comments)}}
                  result (detect parsed)]
              (assert.is_false result.description)
              (assert.is_false result.tasks)
              (assert.is_true result.comments))))

        (it "detects multiple changes simultaneously"
          (fn []
            (let [detect (. diff "detect-local-changes")
                  content-hash (. hash "content-hash")
                  parsed {:description "Changed desc"
                          :tasks [{:id 1 :description "Changed" :complete true}]
                          :comments [{:id 1 :text "Changed"}]
                          :frontmatter {:sync_hash (content-hash "Original desc")
                                        :tasks_hash (hash.tasks-hash [{:id 1 :description "Original" :complete false}])
                                        :comments_hash (hash.comments-hash [{:id 1 :text "Original"}])}}
                  result (detect parsed)]
              (assert.is_true result.description)
              (assert.is_true result.tasks)
              (assert.is_true result.comments))))))

    (describe "any-local-change?"
      (fn []
        (it "returns false when nothing changed"
          (fn []
            (let [any-change? (. diff "any-local-change?")
                  content-hash (. hash "content-hash")
                  desc "Same"
                  parsed {:description desc
                          :tasks []
                          :comments []
                          :frontmatter {:sync_hash (content-hash desc)
                                        :tasks_hash (hash.tasks-hash [])
                                        :comments_hash (hash.comments-hash [])}}]
              (assert.is_false (any-change? parsed)))))

        (it "returns true when any section changed"
          (fn []
            (let [any-change? (. diff "any-local-change?")
                  content-hash (. hash "content-hash")
                  parsed {:description "Different"
                          :tasks []
                          :comments []
                          :frontmatter {:sync_hash (content-hash "Original")
                                        :tasks_hash (hash.tasks-hash [])
                                        :comments_hash (hash.comments-hash [])}}]
              (assert.is_true (any-change? parsed)))))))

    (describe "detect-remote-change"
      (fn []
        (it "returns false when timestamps match"
          (fn []
            (let [detect (. diff "detect-remote-change")
                  fm {:updated_at "2026-01-15T12:00:00Z"}]
              (assert.is_false (detect fm "2026-01-15T12:00:00Z")))))

        (it "returns true when timestamps differ"
          (fn []
            (let [detect (. diff "detect-remote-change")
                  fm {:updated_at "2026-01-15T12:00:00Z"}]
              (assert.is_true (detect fm "2026-01-16T08:00:00Z")))))

        (it "returns false when remote updated_at is nil"
          (fn []
            (let [detect (. diff "detect-remote-change")
                  fm {:updated_at "2026-01-15T12:00:00Z"}]
              (assert.is_false (detect fm nil)))))

        (it "returns false when remote updated_at is empty"
          (fn []
            (let [detect (. diff "detect-remote-change")
                  fm {:updated_at "2026-01-15T12:00:00Z"}]
              (assert.is_false (detect fm "")))))

        (it "returns true when stored is empty but remote has value"
          (fn []
            (let [detect (. diff "detect-remote-change")
                  fm {:updated_at ""}]
              (assert.is_true (detect fm "2026-01-15T12:00:00Z")))))))

    (describe "classify"
      (fn []
        (it "returns :clean when nothing changed"
          (fn []
            (let [content-hash (. hash "content-hash")
                  desc "Description"
                  ts "2026-01-15T12:00:00Z"
                  parsed {:description desc
                          :tasks []
                          :comments []
                          :frontmatter {:sync_hash (content-hash desc)
                                        :tasks_hash (hash.tasks-hash [])
                                        :comments_hash (hash.comments-hash [])
                                        :updated_at ts}}
                  result (diff.classify parsed ts)]
              (assert.equals :clean result.status)
              (assert.is_false result.remote_changed)
              (assert.is_false result.local_changes.description)
              (assert.is_false result.local_changes.tasks)
              (assert.is_false result.local_changes.comments))))

        (it "returns :local-only when only local changed"
          (fn []
            (let [content-hash (. hash "content-hash")
                  ts "2026-01-15T12:00:00Z"
                  parsed {:description "New description"
                          :tasks []
                          :comments []
                          :frontmatter {:sync_hash (content-hash "Old description")
                                        :tasks_hash (hash.tasks-hash [])
                                        :comments_hash (hash.comments-hash [])
                                        :updated_at ts}}
                  result (diff.classify parsed ts)]
              (assert.equals :local-only result.status)
              (assert.is_false result.remote_changed)
              (assert.is_true result.local_changes.description))))

        (it "returns :remote-only when only remote changed"
          (fn []
            (let [content-hash (. hash "content-hash")
                  desc "Same description"
                  parsed {:description desc
                          :tasks []
                          :comments []
                          :frontmatter {:sync_hash (content-hash desc)
                                        :tasks_hash (hash.tasks-hash [])
                                        :comments_hash (hash.comments-hash [])
                                        :updated_at "2026-01-15T12:00:00Z"}}
                  result (diff.classify parsed "2026-01-16T08:00:00Z")]
              (assert.equals :remote-only result.status)
              (assert.is_true result.remote_changed)
              (assert.is_false result.local_changes.description))))

        (it "returns :conflict when both changed"
          (fn []
            (let [content-hash (. hash "content-hash")
                  parsed {:description "Locally edited"
                          :tasks []
                          :comments []
                          :frontmatter {:sync_hash (content-hash "Original")
                                        :tasks_hash (hash.tasks-hash [])
                                        :comments_hash (hash.comments-hash [])
                                        :updated_at "2026-01-15T12:00:00Z"}}
                  result (diff.classify parsed "2026-01-16T08:00:00Z")]
              (assert.equals :conflict result.status)
              (assert.is_true result.remote_changed)
              (assert.is_true result.local_changes.description))))

        (it "detects independent section changes"
          (fn []
            (let [content-hash (. hash "content-hash")
                  desc "Same"
                  ts "2026-01-15T12:00:00Z"
                  parsed {:description desc
                          :tasks [{:id 1 :description "Changed" :complete true}]
                          :comments []
                          :frontmatter {:sync_hash (content-hash desc)
                                        :tasks_hash (hash.tasks-hash [{:id 1 :description "Original" :complete false}])
                                        :comments_hash (hash.comments-hash [])
                                        :updated_at ts}}
                  result (diff.classify parsed ts)]
              (assert.equals :local-only result.status)
              (assert.is_false result.local_changes.description)
              (assert.is_true result.local_changes.tasks)
              (assert.is_false result.local_changes.comments))))))))
