;; Tests for longway.api.comments
;;
;; Tests comment API operations with mock HTTP client

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local comments (require :longway.api.comments))

(describe "longway.api.comments"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "module structure"
      (fn []
        (it "exports list function"
          (fn []
            (assert.is_function comments.list)))

        (it "exports get function"
          (fn []
            (assert.is_function comments.get)))

        (it "exports create function"
          (fn []
            (assert.is_function comments.create)))

        (it "exports delete function"
          (fn []
            (assert.is_function comments.delete)))

        (it "exports batch-create function"
          (fn []
            (assert.is_function (. comments "batch-create"))))

        (it "exports batch-delete function"
          (fn []
            (assert.is_function (. comments "batch-delete"))))))

    (describe "batch-create"
      (fn []
        (it "returns ok true with empty comments list"
          (fn []
            (let [batch-create (. comments "batch-create")]
              (let [result (batch-create 12345 [])]
                (assert.is_true result.ok)
                (assert.equals 0 (length result.created))
                (assert.equals 0 (length result.errors))))))

        (it "creates comments sequentially and collects results"
          (fn []
            ;; Stub the create function to simulate successful API calls
            (let [original-create comments.create
                  counter {:n 0}]
              (set comments.create
                   (fn [story-id data]
                     (set counter.n (+ 1 counter.n))
                     {:ok true :data {:id counter.n :text data.text}}))
              (let [batch-create (. comments "batch-create")
                    result (batch-create 12345 [{:text "First"} {:text "Second"}])]
                (assert.is_true result.ok)
                (assert.equals 2 (length result.created))
                (assert.equals 0 (length result.errors))
                (assert.equals "First" (. result.created 1 :text))
                (assert.equals "Second" (. result.created 2 :text)))
              (set comments.create original-create))))

        (it "aggregates errors from failed creates"
          (fn []
            (let [original-create comments.create
                  counter {:n 0}]
              ;; Stub create to fail on second call
              (set comments.create
                   (fn [story-id data]
                     (set counter.n (+ 1 counter.n))
                     (if (= counter.n 2)
                         {:ok false :error "Server error"}
                         {:ok true :data {:id counter.n :text data.text}})))
              (let [batch-create (. comments "batch-create")
                    result (batch-create 12345 [{:text "OK"} {:text "Fail"} {:text "Also OK"}])]
                (assert.is_false result.ok)
                (assert.equals 2 (length result.created))
                (assert.equals 1 (length result.errors))
                (assert.has_substring (. result.errors 1) "Comment 2"))
              (set comments.create original-create))))))

    (describe "batch-delete"
      (fn []
        (it "returns ok true with empty comment-ids list"
          (fn []
            (let [batch-delete (. comments "batch-delete")]
              (let [result (batch-delete 12345 [])]
                (assert.is_true result.ok)
                (assert.equals 0 (length result.deleted))
                (assert.equals 0 (length result.errors))))))

        (it "deletes comments sequentially and collects results"
          (fn []
            (let [original-delete comments.delete]
              (set comments.delete (fn [story-id comment-id] {:ok true}))
              (let [batch-delete (. comments "batch-delete")
                    result (batch-delete 12345 [101 102 103])]
                (assert.is_true result.ok)
                (assert.equals 3 (length result.deleted))
                (assert.equals 0 (length result.errors)))
              (set comments.delete original-delete))))

        (it "aggregates errors from failed deletes"
          (fn []
            (let [original-delete comments.delete]
              (set comments.delete
                   (fn [story-id comment-id]
                     (if (= comment-id 102)
                         {:ok false :error "Not found"}
                         {:ok true})))
              (let [batch-delete (. comments "batch-delete")
                    result (batch-delete 12345 [101 102 103])]
                (assert.is_false result.ok)
                (assert.equals 2 (length result.deleted))
                (assert.equals 1 (length result.errors))
                (assert.has_substring (. result.errors 1) "102"))
              (set comments.delete original-delete))))))))
