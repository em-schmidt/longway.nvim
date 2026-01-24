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
            (assert.is_function members.get_current)))))

    (describe "get"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function members.get)))))

    (describe "list-cached"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function members.list_cached)))))

    (describe "refresh-cache"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function members.refresh_cache)))))

    (describe "find-by-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function members.find_by_name)))

        (it "finds member by partial name match"
          (fn []
            (let [test-members [{:id "1" :profile {:name "John Doe"}}
                                {:id "2" :profile {:name "Jane Smith"}}]
                  result (members.find_by_name "john" test-members)]
              (assert.equals "1" result.id))))))

    (describe "find-by-id"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function members.find_by_id)))

        (it "finds member by exact id"
          (fn []
            (let [test-members [{:id "1" :profile {:name "John Doe"}}
                                {:id "2" :profile {:name "Jane Smith"}}]
                  result (members.find_by_id "2" test-members)]
              (assert.equals "Jane Smith" result.profile.name))))))

    (describe "get-display-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function members.get_display_name)))

        (it "returns profile name"
          (fn []
            (let [member {:id "1" :profile {:name "John Doe"}}
                  name (members.get_display_name member)]
              (assert.equals "John Doe" name))))

        (it "falls back to mention name"
          (fn []
            (let [member {:id "1" :profile {:mention_name "johnd"}}
                  name (members.get_display_name member)]
              (assert.equals "johnd" name))))))

    (describe "resolve-name"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function members.resolve_name)))))))
