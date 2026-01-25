;; Tests for longway.sync.tasks
;;
;; Tests task synchronization logic

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local tasks-sync (require :longway.sync.tasks))

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
              (assert.equals 1 (length result.unchanged)))))))

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
              (assert.equals 0 (length result.tasks)))))))

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
              (assert.equals 1 (length result.conflicts)))))))))
