;; Tests for longway.api.iterations
;;
;; Tests Iterations API module

(local t (require :longway-spec.init))
(local iterations (require :longway.api.iterations))

(describe "longway.api.iterations"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "list"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function iterations.list)))))

    (describe "get"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function iterations.get)))))

    (describe "list-cached"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. iterations "list-cached"))))))

    (describe "refresh-cache"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. iterations "refresh-cache"))))))

    (describe "find-by-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. iterations "find-by-name"))))

        (it "finds iteration by partial name match"
          (fn []
            (let [test-iterations [{:id 1 :name "Sprint 1"}
                                   {:id 2 :name "Sprint 2"}
                                   {:id 3 :name "Backlog"}]
                  find-by-name (. iterations "find-by-name")
                  result (find-by-name "sprint 2" test-iterations)]
              (assert.equals 2 result.id))))))

    (describe "find-by-id"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. iterations "find-by-id"))))

        (it "finds iteration by exact id"
          (fn []
            (let [test-iterations [{:id 1 :name "Sprint 1"}
                                   {:id 2 :name "Sprint 2"}]
                  find-by-id (. iterations "find-by-id")
                  result (find-by-id 2 test-iterations)]
              (assert.equals "Sprint 2" result.name))))))

    (describe "get-current"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. iterations "get-current"))))))

    (describe "get-upcoming"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. iterations "get-upcoming"))))))

    (describe "resolve-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. iterations "resolve-name"))))))))
