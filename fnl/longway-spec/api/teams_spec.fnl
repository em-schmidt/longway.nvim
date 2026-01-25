;; Tests for longway.api.teams
;;
;; Tests Teams API module

(local t (require :longway-spec.init))
(local teams (require :longway.api.teams))

(describe "longway.api.teams"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "list"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function teams.list)))))

    (describe "get"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function teams.get)))))

    (describe "list-cached"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. teams "list-cached"))))))

    (describe "refresh-cache"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. teams "refresh-cache"))))))

    (describe "find-by-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. teams "find-by-name"))))

        (it "finds team by partial name match"
          (fn []
            (let [test-teams [{:id "1" :name "Engineering"}
                              {:id "2" :name "Design"}
                              {:id "3" :name "Product"}]
                  find-by-name (. teams "find-by-name")
                  result (find-by-name "eng" test-teams)]
              (assert.equals "1" result.id))))))

    (describe "find-by-id"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. teams "find-by-id"))))

        (it "finds team by exact id"
          (fn []
            (let [test-teams [{:id "1" :name "Engineering"}
                              {:id "2" :name "Design"}]
                  find-by-id (. teams "find-by-id")
                  result (find-by-id "2" test-teams)]
              (assert.equals "Design" result.name))))))

    (describe "get-members"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. teams "get-members"))))

        (it "returns member IDs from team"
          (fn []
            (let [team {:id "1" :name "Engineering" :member_ids ["a" "b" "c"]}
                  get-members (. teams "get-members")
                  member-ids (get-members team)]
              (assert.equals 3 (length member-ids)))))))

    (describe "resolve-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. teams "resolve-name"))))))))
