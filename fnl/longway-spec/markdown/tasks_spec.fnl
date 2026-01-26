;; Tests for longway.markdown.tasks
;;
;; Tests task markdown parsing and rendering

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local tasks-md (require :longway.markdown.tasks))

(describe "longway.markdown.tasks"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "parse-line"
      (fn []
        (it "parses incomplete task with metadata"
          (fn []
            (let [line "- [ ] Do something <!-- task:123 complete:false -->"
                  parse-line (. tasks-md "parse-line")
                  result (parse-line line)]
              (assert.is_not_nil result)
              (assert.equals "Do something" result.description)
              (assert.equals 123 result.id)
              (assert.is_false result.complete)
              (assert.is_false result.is_new))))

        (it "parses complete task with metadata"
          (fn []
            (let [line "- [x] Done task <!-- task:456 complete:true -->"
                  parse-line (. tasks-md "parse-line")
                  result (parse-line line)]
              (assert.is_not_nil result)
              (assert.is_true result.complete)
              (assert.equals 456 result.id))))

        (it "parses task with owner mention"
          (fn []
            (let [line "- [ ] Task <!-- task:789 @eric complete:false -->"
                  parse-line (. tasks-md "parse-line")
                  result (parse-line line)]
              (assert.is_not_nil result)
              (assert.equals "eric" result.owner_mention))))

        (it "parses new task marker"
          (fn []
            (let [line "- [ ] New task <!-- task:new complete:false -->"
                  parse-line (. tasks-md "parse-line")
                  result (parse-line line)]
              (assert.is_not_nil result)
              (assert.is_nil result.id)
              (assert.is_true result.is_new))))

        (it "parses task without metadata as new"
          (fn []
            (let [line "- [ ] Plain task without metadata"
                  parse-line (. tasks-md "parse-line")
                  result (parse-line line)]
              (assert.is_not_nil result)
              (assert.equals "Plain task without metadata" result.description)
              (assert.is_nil result.id)
              (assert.is_true result.is_new))))

        (it "returns nil for non-task lines"
          (fn []
            (let [parse-line (. tasks-md "parse-line")]
              (assert.is_nil (parse-line "Regular text"))
              (assert.is_nil (parse-line "# Heading"))
              (assert.is_nil (parse-line "* Bullet point")))))))

    (describe "parse-section"
      (fn []
        (it "parses multiple tasks"
          (fn []
            (let [content "- [ ] First <!-- task:1 complete:false -->
- [x] Second <!-- task:2 complete:true -->
- [ ] Third <!-- task:3 complete:false -->"
                  parse-section (. tasks-md "parse-section")
                  result (parse-section content)]
              (assert.equals 3 (length result))
              (assert.equals "First" (. result 1 :description))
              (assert.equals "Second" (. result 2 :description))
              (assert.equals "Third" (. result 3 :description)))))

        (it "assigns positions to tasks"
          (fn []
            (let [content "- [ ] First <!-- task:1 complete:false -->
- [ ] Second <!-- task:2 complete:false -->"
                  parse-section (. tasks-md "parse-section")
                  result (parse-section content)]
              (assert.equals 1 (. result 1 :position))
              (assert.equals 2 (. result 2 :position)))))

        (it "ignores non-task lines"
          (fn []
            (let [content "Some text before
- [ ] Only task <!-- task:1 complete:false -->
Some text after"
                  parse-section (. tasks-md "parse-section")
                  result (parse-section content)]
              (assert.equals 1 (length result)))))))

    (describe "render-task"
      (fn []
        (it "renders incomplete task"
          (fn []
            (let [task {:id 123 :description "Do thing" :complete false :is_new false}
                  render-task (. tasks-md "render-task")
                  result (render-task task)]
              (assert.has_substring result "- [ ]")
              (assert.has_substring result "Do thing")
              (assert.has_substring result "task:123")
              (assert.has_substring result "complete:false"))))

        (it "renders complete task"
          (fn []
            (let [task {:id 456 :description "Done" :complete true :is_new false}
                  render-task (. tasks-md "render-task")
                  result (render-task task)]
              (assert.has_substring result "- [x]")
              (assert.has_substring result "complete:true"))))

        (it "renders new task without ID"
          (fn []
            (let [task {:description "New task" :complete false :is_new true}
                  render-task (. tasks-md "render-task")
                  result (render-task task)]
              (assert.has_substring result "task:new"))))))

    (describe "render-tasks"
      (fn []
        (it "renders multiple tasks"
          (fn []
            (let [tasks [{:id 1 :description "First" :complete false :position 1}
                         {:id 2 :description "Second" :complete true :position 2}]
                  render-tasks (. tasks-md "render-tasks")
                  result (render-tasks tasks)]
              (assert.has_substring result "First")
              (assert.has_substring result "Second"))))

        (it "returns empty string for no tasks"
          (fn []
            (let [render-tasks (. tasks-md "render-tasks")]
              (assert.equals "" (render-tasks []))
              (assert.equals "" (render-tasks nil)))))))

    (describe "task-changed?"
      (fn []
        (it "detects completion change"
          (fn []
            (let [local-task {:id 1 :description "Task" :complete true}
                  remote-task {:id 1 :description "Task" :complete false}
                  task-changed? (. tasks-md "task-changed?")]
              (assert.is_true (task-changed? local-task remote-task)))))

        (it "detects description change"
          (fn []
            (let [local-task {:id 1 :description "Updated task" :complete false}
                  remote-task {:id 1 :description "Original task" :complete false}
                  task-changed? (. tasks-md "task-changed?")]
              (assert.is_true (task-changed? local-task remote-task)))))

        (it "returns false for unchanged task"
          (fn []
            (let [local-task {:id 1 :description "Same task" :complete false}
                  remote-task {:id 1 :description "Same task" :complete false}
                  task-changed? (. tasks-md "task-changed?")]
              (assert.is_false (task-changed? local-task remote-task)))))))

    (describe "find-task-by-id"
      (fn []
        (it "finds task by ID"
          (fn []
            (let [tasks [{:id 1 :description "First"}
                         {:id 2 :description "Second"}
                         {:id 3 :description "Third"}]
                  find-task-by-id (. tasks-md "find-task-by-id")
                  result (find-task-by-id tasks 2)]
              (assert.is_not_nil result)
              (assert.equals "Second" result.description))))

        (it "returns nil when not found"
          (fn []
            (let [tasks [{:id 1 :description "First"}]
                  find-task-by-id (. tasks-md "find-task-by-id")
                  result (find-task-by-id tasks 999)]
              (assert.is_nil result))))))))
