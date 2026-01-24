;; Tests for longway.api.workflows
;;
;; Tests Workflows API module

(local t (require :longway-spec.init))
(local workflows (require :longway.api.workflows))

(describe "longway.api.workflows"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "list"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function workflows.list)))))

    (describe "list-cached"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function workflows.list_cached)))))

    (describe "refresh-cache"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function workflows.refresh_cache)))))

    (describe "get-states"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function workflows.get_states)))

        (it "returns states from workflow"
          (fn []
            (let [workflow {:states [{:id 1 :name "To Do"}
                                     {:id 2 :name "In Progress"}
                                     {:id 3 :name "Done"}]}
                  states (workflows.get_states workflow)]
              (assert.equals 3 (length states)))))))

    (describe "get-all-states"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function workflows.get_all_states)))))

    (describe "find-state-by-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function workflows.find_state_by_name)))

        (it "finds state by partial name match"
          (fn []
            (let [test-workflows [{:states [{:id 1 :name "To Do" :type "unstarted"}
                                            {:id 2 :name "In Progress" :type "started"}
                                            {:id 3 :name "Done" :type "done"}]}]
                  result (workflows.find_state_by_name "progress" test-workflows)]
              (assert.equals 2 result.id))))))

    (describe "find-state-by-id"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function workflows.find_state_by_id)))

        (it "finds state by exact id"
          (fn []
            (let [test-workflows [{:states [{:id 1 :name "To Do"}
                                            {:id 2 :name "In Progress"}]}]
                  result (workflows.find_state_by_id 2 test-workflows)]
              (assert.equals "In Progress" result.name))))))

    (describe "get-state-type"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function workflows.get_state_type)))

        (it "returns state type"
          (fn []
            (let [state {:id 1 :name "Done" :type "done"}
                  type (workflows.get_state_type state)]
              (assert.equals "done" type))))))

    (describe "is-done-state"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function workflows.is_done_state)))

        (it "returns true for done states"
          (fn []
            (let [state {:type "done"}]
              (assert.is_true (workflows.is_done_state state)))))

        (it "returns false for other states"
          (fn []
            (let [state {:type "started"}]
              (assert.is_false (workflows.is_done_state state)))))))

    (describe "is-started-state"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function workflows.is_started_state)))

        (it "returns true for started states"
          (fn []
            (let [state {:type "started"}]
              (assert.is_true (workflows.is_started_state state)))))))))
