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
            (assert.is_function (. workflows "list-cached"))))))

    (describe "refresh-cache"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. workflows "refresh-cache"))))))

    (describe "get-states"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. workflows "get-states"))))

        (it "returns states from workflow"
          (fn []
            (let [workflow {:states [{:id 1 :name "To Do"}
                                     {:id 2 :name "In Progress"}
                                     {:id 3 :name "Done"}]}
                  get-states (. workflows "get-states")
                  states (get-states workflow)]
              (assert.equals 3 (length states)))))))

    (describe "get-all-states"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. workflows "get-all-states"))))))

    (describe "find-state-by-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. workflows "find-state-by-name"))))

        (it "finds state by partial name match"
          (fn []
            (let [test-workflows [{:states [{:id 1 :name "To Do" :type "unstarted"}
                                            {:id 2 :name "In Progress" :type "started"}
                                            {:id 3 :name "Done" :type "done"}]}]
                  find-state-by-name (. workflows "find-state-by-name")
                  result (find-state-by-name "progress" test-workflows)]
              (assert.equals 2 result.id))))))

    (describe "find-state-by-id"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. workflows "find-state-by-id"))))

        (it "finds state by exact id"
          (fn []
            (let [test-workflows [{:states [{:id 1 :name "To Do"}
                                            {:id 2 :name "In Progress"}]}]
                  find-state-by-id (. workflows "find-state-by-id")
                  result (find-state-by-id 2 test-workflows)]
              (assert.equals "In Progress" result.name))))))

    (describe "get-state-type"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. workflows "get-state-type"))))

        (it "returns state type"
          (fn []
            (let [state {:id 1 :name "Done" :type "done"}
                  get-state-type (. workflows "get-state-type")
                  type (get-state-type state)]
              (assert.equals "done" type))))))

    (describe "is-done-state"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. workflows "is-done-state"))))

        (it "returns true for done states"
          (fn []
            (let [state {:type "done"}
                  is-done-state (. workflows "is-done-state")]
              (assert.is_true (is-done-state state)))))

        (it "returns false for other states"
          (fn []
            (let [state {:type "started"}
                  is-done-state (. workflows "is-done-state")]
              (assert.is_false (is-done-state state)))))))

    (describe "is-started-state"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. workflows "is-started-state"))))

        (it "returns true for started states"
          (fn []
            (let [state {:type "started"}
                  is-started-state (. workflows "is-started-state")]
              (assert.is_true (is-started-state state)))))))))
