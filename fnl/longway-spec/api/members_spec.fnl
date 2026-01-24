;; Tests for longway.api.members
;;
;; Tests Members API module

(local t (require :longway-spec.init))
(local members (require :longway.api.members))

(describe "longway.api.members"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "list"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function members.list)))))

    (describe "get-current"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. members "get-current"))))))

    (describe "get"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function members.get)))))

    (describe "list-cached"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. members "list-cached"))))))

    (describe "refresh-cache"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. members "refresh-cache"))))))

    (describe "find-by-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. members "find-by-name"))))

        (it "finds member by partial name match"
          (fn []
            (let [test-members [{:id "1" :profile {:name "John Doe"}}
                                {:id "2" :profile {:name "Jane Smith"}}]
                  find-by-name (. members "find-by-name")
                  result (find-by-name "john" test-members)]
              (assert.equals "1" result.id))))))

    (describe "find-by-id"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. members "find-by-id"))))

        (it "finds member by exact id"
          (fn []
            (let [test-members [{:id "1" :profile {:name "John Doe"}}
                                {:id "2" :profile {:name "Jane Smith"}}]
                  find-by-id (. members "find-by-id")
                  result (find-by-id "2" test-members)]
              (assert.equals "Jane Smith" result.profile.name))))))

    (describe "get-display-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. members "get-display-name"))))

        (it "returns profile name"
          (fn []
            (let [member {:id "1" :profile {:name "John Doe"}}
                  get-display-name (. members "get-display-name")
                  name (get-display-name member)]
              (assert.equals "John Doe" name))))

        (it "falls back to mention name"
          (fn []
            (let [member {:id "1" :profile {:mention_name "johnd"}}
                  get-display-name (. members "get-display-name")
                  name (get-display-name member)]
              (assert.equals "johnd" name))))))

    (describe "resolve-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. members "resolve-name"))))))))
