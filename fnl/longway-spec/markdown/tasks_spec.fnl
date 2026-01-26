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
              (assert.is_nil (parse-line "* Bullet point")))))

        ;; Edge cases
        (it "parses task with leading whitespace"
          (fn []
            (let [line "  - [ ] Indented task <!-- task:100 complete:false -->"
                  parse-line (. tasks-md "parse-line")
                  result (parse-line line)]
              (assert.is_not_nil result)
              (assert.equals "Indented task" result.description)
              (assert.equals 100 result.id))))

        (it "parses task with special characters in description"
          (fn []
            (let [line "- [ ] Task with 'quotes' & symbols! <!-- task:200 complete:false -->"
                  parse-line (. tasks-md "parse-line")
                  result (parse-line line)]
              (assert.is_not_nil result)
              (assert.has_substring result.description "quotes")
              (assert.has_substring result.description "symbols"))))

        (it "returns nil for empty string"
          (fn []
            (let [parse-line (. tasks-md "parse-line")]
              (assert.is_nil (parse-line "")))))

        (it "handles task with minimal description"
          (fn []
            (let [line "- [ ] X <!-- task:300 complete:false -->"
                  parse-line (. tasks-md "parse-line")
                  result (parse-line line)]
              (assert.is_not_nil result)
              (assert.equals "X" result.description))))

        (it "initializes owner_ids as empty table"
          (fn []
            (let [line "- [ ] Task <!-- task:123 complete:false -->"
                  parse-line (. tasks-md "parse-line")
                  result (parse-line line)]
              (assert.is_not_nil result.owner_ids)
              (assert.equals 0 (length result.owner_ids)))))))

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
              (assert.equals 1 (length result)))))

        (it "handles empty content"
          (fn []
            (let [parse-section (. tasks-md "parse-section")
                  result (parse-section "")]
              (assert.equals 0 (length result)))))

        (it "handles mixed new and existing tasks"
          (fn []
            (let [content "- [x] Done task <!-- task:1 complete:true -->
- [ ] New task <!-- task:new -->
- [ ] Another existing <!-- task:2 complete:false -->"
                  parse-section (. tasks-md "parse-section")
                  result (parse-section content)]
              (assert.equals 3 (length result))
              (assert.equals 1 (. result 1 :id))
              (assert.is_true (. result 2 :is_new))
              (assert.equals 2 (. result 3 :id)))))))

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
              (assert.has_substring result "task:new"))))

        (it "renders task with owner mention"
          (fn []
            (let [task {:id 789 :description "Owned task" :complete false
                        :owner_mention "eric" :is_new false}
                  render-task (. tasks-md "render-task")
                  result (render-task task)]
              (assert.has_substring result "@eric")
              (assert.has_substring result "task:789"))))))

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
              (assert.equals "" (render-tasks nil)))))

        (it "preserves task order by position"
          (fn []
            (let [tasks [{:id 2 :description "Second" :complete false :position 2}
                         {:id 1 :description "First" :complete false :position 1}]
                  render-tasks (. tasks-md "render-tasks")
                  result (render-tasks tasks)
                  first-pos (string.find result "First" 1 true)
                  second-pos (string.find result "Second" 1 true)]
              (assert.is_not_nil first-pos)
              (assert.is_not_nil second-pos)
              (assert.is_true (< first-pos second-pos)))))))

    (describe "render-section"
      (fn []
        (it "wraps tasks in sync markers"
          (fn []
            (let [tasks [{:id 1 :description "Task" :complete false :position 1}]
                  render-section (. tasks-md "render-section")
                  result (render-section tasks)]
              (assert.has_substring result "<!-- BEGIN SHORTCUT SYNC:tasks -->")
              (assert.has_substring result "<!-- END SHORTCUT SYNC:tasks -->")
              (assert.has_substring result "Task"))))

        (it "renders empty section with markers"
          (fn []
            (let [render-section (. tasks-md "render-section")
                  result (render-section [])]
              (assert.has_substring result "<!-- BEGIN SHORTCUT SYNC:tasks -->")
              (assert.has_substring result "<!-- END SHORTCUT SYNC:tasks -->"))))))

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
              (assert.is_false (task-changed? local-task remote-task)))))

        (it "ignores leading and trailing whitespace in descriptions"
          (fn []
            (let [local-task {:id 1 :description "  Task text  " :complete false}
                  remote-task {:id 1 :description "Task text" :complete false}
                  task-changed? (. tasks-md "task-changed?")]
              (assert.is_false (task-changed? local-task remote-task)))))

        (it "handles nil descriptions"
          (fn []
            (let [local-task {:id 1 :description nil :complete false}
                  remote-task {:id 1 :description nil :complete false}
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
              (assert.is_nil result))))

        (it "returns first match when duplicate IDs exist"
          (fn []
            (let [tasks [{:id 1 :description "First"}
                         {:id 1 :description "Duplicate"}]
                  find-task-by-id (. tasks-md "find-task-by-id")
                  result (find-task-by-id tasks 1)]
              (assert.equals "First" result.description))))))

    (describe "tasks-equal?"
      (fn []
        (it "returns true for identical task lists"
          (fn []
            (let [a [{:id 1 :description "Task" :complete false}]
                  b [{:id 1 :description "Task" :complete false}]
                  tasks-equal? (. tasks-md "tasks-equal?")]
              (assert.is_true (tasks-equal? a b)))))

        (it "returns false for different lengths"
          (fn []
            (let [a [{:id 1 :description "Task" :complete false}]
                  b [{:id 1 :description "Task" :complete false}
                     {:id 2 :description "Another" :complete false}]
                  tasks-equal? (. tasks-md "tasks-equal?")]
              (assert.is_false (tasks-equal? a b)))))

        (it "returns false for different completion states"
          (fn []
            (let [a [{:id 1 :description "Task" :complete true}]
                  b [{:id 1 :description "Task" :complete false}]
                  tasks-equal? (. tasks-md "tasks-equal?")]
              (assert.is_false (tasks-equal? a b)))))

        (it "returns true for two empty lists"
          (fn []
            (let [tasks-equal? (. tasks-md "tasks-equal?")]
              (assert.is_true (tasks-equal? [] [])))))))

    (describe "round-trip parse-render"
      (fn []
        (it "parsed task can be re-rendered with same metadata"
          (fn []
            (let [parse-line (. tasks-md "parse-line")
                  render-task (. tasks-md "render-task")
                  original "- [ ] Do something <!-- task:123 complete:false -->"
                  parsed (parse-line original)
                  rendered (render-task parsed)]
              (assert.has_substring rendered "task:123")
              (assert.has_substring rendered "Do something")
              (assert.has_substring rendered "complete:false")
              (assert.has_substring rendered "- [ ]"))))

        (it "completed task round-trips correctly"
          (fn []
            (let [parse-line (. tasks-md "parse-line")
                  render-task (. tasks-md "render-task")
                  original "- [x] Completed <!-- task:456 complete:true -->"
                  parsed (parse-line original)
                  rendered (render-task parsed)]
              (assert.has_substring rendered "- [x]")
              (assert.has_substring rendered "task:456")
              (assert.has_substring rendered "complete:true"))))))))
