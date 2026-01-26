;; Tests for longway.sync.tasks
;;
;; Tests task synchronization logic

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local tasks-sync (require :longway.sync.tasks))
(local tasks-md (require :longway.markdown.tasks))
(local hash (require :longway.util.hash))

(describe "longway.sync.tasks"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "diff"
      (fn []
        (it "detects new local tasks"
          (fn []
            (let [local-tasks [{:description "New task" :complete false :is_new true}]
                  remote-tasks []
                  result (tasks-sync.diff local-tasks remote-tasks)]
              (assert.equals 1 (length result.created))
              (assert.equals 0 (length result.updated))
              (assert.equals 0 (length result.deleted))
              (assert.equals 0 (length result.unchanged)))))

        (it "detects updated tasks"
          (fn []
            (let [local-tasks [{:id 1 :description "Task" :complete true :is_new false}]
                  remote-tasks [{:id 1 :description "Task" :complete false}]
                  result (tasks-sync.diff local-tasks remote-tasks)]
              (assert.equals 0 (length result.created))
              (assert.equals 1 (length result.updated))
              (assert.equals 0 (length result.deleted)))))

        (it "detects deleted tasks"
          (fn []
            (let [local-tasks []
                  remote-tasks [{:id 1 :description "Remote task" :complete false}]
                  result (tasks-sync.diff local-tasks remote-tasks)]
              (assert.equals 0 (length result.created))
              (assert.equals 0 (length result.updated))
              (assert.equals 1 (length result.deleted))
              (assert.equals 1 (. result.deleted 1)))))

        (it "detects unchanged tasks"
          (fn []
            (let [local-tasks [{:id 1 :description "Same" :complete false :is_new false}]
                  remote-tasks [{:id 1 :description "Same" :complete false}]
                  result (tasks-sync.diff local-tasks remote-tasks)]
              (assert.equals 0 (length result.created))
              (assert.equals 0 (length result.updated))
              (assert.equals 0 (length result.deleted))
              (assert.equals 1 (length result.unchanged)))))

        (it "handles complex diff scenario"
          (fn []
            (let [local-tasks [{:id 1 :description "Unchanged" :complete false :is_new false}
                               {:id 2 :description "Updated desc" :complete false :is_new false}
                               {:description "Brand new" :complete false :is_new true}]
                  remote-tasks [{:id 1 :description "Unchanged" :complete false}
                                {:id 2 :description "Original desc" :complete false}
                                {:id 3 :description "Will be deleted" :complete false}]
                  result (tasks-sync.diff local-tasks remote-tasks)]
              (assert.equals 1 (length result.created))
              (assert.equals 1 (length result.updated))
              (assert.equals 1 (length result.deleted))
              (assert.equals 1 (length result.unchanged)))))

        (it "handles nil local tasks"
          (fn []
            (let [remote-tasks [{:id 1 :description "Task" :complete false}]
                  result (tasks-sync.diff nil remote-tasks)]
              (assert.equals 0 (length result.created))
              (assert.equals 1 (length result.deleted)))))

        (it "handles nil remote tasks"
          (fn []
            (let [local-tasks [{:description "New" :complete false :is_new true}]
                  result (tasks-sync.diff local-tasks nil)]
              (assert.equals 1 (length result.created))
              (assert.equals 0 (length result.deleted)))))

        (it "handles both nil"
          (fn []
            (let [result (tasks-sync.diff nil nil)]
              (assert.equals 0 (length result.created))
              (assert.equals 0 (length result.updated))
              (assert.equals 0 (length result.deleted))
              (assert.equals 0 (length result.unchanged)))))

        (it "treats locally present task missing from remote as new"
          (fn []
            (let [local-tasks [{:id 99 :description "Locally retained" :complete false :is_new false}]
                  remote-tasks [] ;; task was deleted remotely
                  result (tasks-sync.diff local-tasks remote-tasks)]
              ;; Task should be treated as new (re-create) since remote deleted it
              (assert.equals 1 (length result.created))
              (assert.equals 0 (length result.updated)))))

        (it "detects description change only"
          (fn []
            (let [local-tasks [{:id 1 :description "Changed description" :complete false :is_new false}]
                  remote-tasks [{:id 1 :description "Original description" :complete false}]
                  result (tasks-sync.diff local-tasks remote-tasks)]
              (assert.equals 1 (length result.updated))
              (assert.equals "Changed description" (. result.updated 1 :description)))))))

    (describe "has-changes?"
      (fn []
        (it "returns true when there are created tasks"
          (fn []
            (let [diff {:created [{:description "New"}] :updated [] :deleted [] :unchanged []}
                  has-changes? (. tasks-sync "has-changes?")]
              (assert.is_true (has-changes? diff)))))

        (it "returns true when there are updated tasks"
          (fn []
            (let [diff {:created [] :updated [{:id 1}] :deleted [] :unchanged []}
                  has-changes? (. tasks-sync "has-changes?")]
              (assert.is_true (has-changes? diff)))))

        (it "returns true when there are deleted tasks"
          (fn []
            (let [diff {:created [] :updated [] :deleted [1] :unchanged []}
                  has-changes? (. tasks-sync "has-changes?")]
              (assert.is_true (has-changes? diff)))))

        (it "returns false when no changes"
          (fn []
            (let [diff {:created [] :updated [] :deleted [] :unchanged [{:id 1}]}
                  has-changes? (. tasks-sync "has-changes?")]
              (assert.is_false (has-changes? diff)))))))

    (describe "pull"
      (fn []
        (it "extracts tasks from story"
          (fn []
            (let [story {:tasks [{:id 1 :description "Task 1" :complete false}
                                 {:id 2 :description "Task 2" :complete true}]}
                  result (tasks-sync.pull story)]
              (assert.is_true result.ok)
              (assert.equals 2 (length result.tasks)))))

        (it "handles story with no tasks"
          (fn []
            (let [story {:tasks []}
                  result (tasks-sync.pull story)]
              (assert.is_true result.ok)
              (assert.equals 0 (length result.tasks)))))

        (it "handles story with nil tasks"
          (fn []
            (let [story {}
                  result (tasks-sync.pull story)]
              (assert.is_true result.ok)
              (assert.equals 0 (length result.tasks)))))

        (it "preserves task IDs and descriptions"
          (fn []
            (let [story {:tasks [{:id 42 :description "My task" :complete true}]}
                  result (tasks-sync.pull story)]
              (assert.equals 42 (. result.tasks 1 :id))
              (assert.equals "My task" (. result.tasks 1 :description))
              (assert.is_true (. result.tasks 1 :complete)))))

        (it "sets is_new to false for all pulled tasks"
          (fn []
            (let [story {:tasks [{:id 1 :description "Task" :complete false}]}
                  result (tasks-sync.pull story)]
              (assert.is_false (. result.tasks 1 :is_new)))))

        (it "assigns positions"
          (fn []
            (let [story {:tasks [{:id 1 :description "First" :complete false}
                                 {:id 2 :description "Second" :complete false}]}
                  result (tasks-sync.pull story)]
              (assert.equals 1 (. result.tasks 1 :position))
              (assert.equals 2 (. result.tasks 2 :position)))))))

    (describe "merge"
      (fn []
        (it "keeps new local tasks"
          (fn []
            (let [local-tasks [{:description "Local new" :is_new true}]
                  remote-tasks []
                  previous-tasks []
                  result (tasks-sync.merge local-tasks remote-tasks previous-tasks)]
              (assert.equals 1 (length result.tasks))
              (assert.equals "Local new" (. result.tasks 1 :description)))))

        (it "adds new remote tasks"
          (fn []
            (let [local-tasks []
                  remote-tasks [{:id 1 :description "Remote new" :complete false}]
                  previous-tasks []
                  result (tasks-sync.merge local-tasks remote-tasks previous-tasks)]
              (assert.equals 1 (length result.remote_added))
              (assert.equals 1 (. result.remote_added 1 :id)))))

        (it "detects conflicts when both changed"
          (fn []
            (let [local-tasks [{:id 1 :description "Local version" :complete true}]
                  remote-tasks [{:id 1 :description "Remote version" :complete false}]
                  previous-tasks [{:id 1 :description "Original" :complete false}]
                  result (tasks-sync.merge local-tasks remote-tasks previous-tasks)]
              ;; Both local and remote changed from previous - conflict
              (assert.equals 1 (length result.conflicts)))))

        (it "detects remote deletions"
          (fn []
            (let [local-tasks [{:id 1 :description "Task" :complete false}]
                  remote-tasks []
                  previous-tasks [{:id 1 :description "Task" :complete false}]
                  result (tasks-sync.merge local-tasks remote-tasks previous-tasks)]
              ;; Task was in previous sync but removed from remote
              (assert.equals 1 (length result.remote_deleted)))))

        (it "keeps locally changed task when remote unchanged"
          (fn []
            (let [local-tasks [{:id 1 :description "Updated locally" :complete true}]
                  remote-tasks [{:id 1 :description "Original" :complete false}]
                  previous-tasks [{:id 1 :description "Original" :complete false}]
                  result (tasks-sync.merge local-tasks remote-tasks previous-tasks)]
              ;; Only local changed - no conflict, local wins
              (assert.equals 0 (length result.conflicts))
              (assert.equals 1 (length result.tasks))
              (assert.equals "Updated locally" (. result.tasks 1 :description)))))

        (it "handles empty merge"
          (fn []
            (let [result (tasks-sync.merge [] [] [])]
              (assert.equals 0 (length result.tasks))
              (assert.equals 0 (length result.conflicts)))))))

    (describe "integration: parse-diff round-trip"
      (fn []
        (it "parses markdown, diffs with remote, detects changes"
          (fn []
            (let [parse-section (. tasks-md "parse-section")
                  ;; Simulate local markdown with one completed and one new task
                  local-content "- [x] Design auth flow <!-- task:101 complete:true -->
- [ ] New task from user <!-- task:new -->"
                  local-tasks (parse-section local-content)
                  ;; Simulate remote tasks from API
                  remote-tasks [{:id 101 :description "Design auth flow" :complete false}
                                {:id 102 :description "Set up schema" :complete false}]
                  diff (tasks-sync.diff local-tasks remote-tasks)]
              ;; task 101 was toggled complete locally
              (assert.equals 1 (length diff.updated))
              ;; new task from user
              (assert.equals 1 (length diff.created))
              ;; task 102 removed from local (deleted)
              (assert.equals 1 (length diff.deleted))
              (assert.equals 102 (. diff.deleted 1)))))

        (it "computes stable hash for tasks before and after round-trip"
          (fn []
            (let [tasks [{:id 1 :description "Task A" :complete false}
                         {:id 2 :description "Task B" :complete true}]
                  hash1 (hash.tasks-hash tasks)
                  hash2 (hash.tasks-hash tasks)]
              ;; Same input produces same hash
              (assert.equals hash1 hash2)
              ;; Changing a task changes the hash
              (let [modified [{:id 1 :description "Task A" :complete true}
                              {:id 2 :description "Task B" :complete true}]
                    hash3 (hash.tasks-hash modified)]
                (assert.is_not.equals hash1 hash3)))))))))
