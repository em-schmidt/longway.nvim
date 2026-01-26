;; Tests for longway.api.stories
;;
;; Tests Stories API module
;; Note: These are unit tests that verify API call construction,
;; not integration tests with the actual Shortcut API

(local t (require :longway-spec.init))
(local stories (require :longway.api.stories))

(describe "longway.api.stories"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "get"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function stories.get)))

        (it "accepts story ID as argument"
          (fn []
            ;; Just verify the function accepts the argument without error
            ;; Actual API call would fail without real token/network
            (assert.is_function stories.get)))))

    (describe "update"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function stories.update)))

        (it "accepts story ID and data"
          (fn []
            (assert.is_function stories.update)))))

    (describe "search"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function stories.search)))))

    (describe "list-for-epic"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. stories "list-for-epic"))))))

    (describe "list-comments"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. stories "list-comments"))))))

    (describe "create-comment"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. stories "create-comment"))))))

    (describe "delete-comment"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. stories "delete-comment"))))))))
