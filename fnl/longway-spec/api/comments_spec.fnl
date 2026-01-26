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
                (assert.equals 0 (length result.errors))))))))

    (describe "batch-delete"
      (fn []
        (it "returns ok true with empty comment-ids list"
          (fn []
            (let [batch-delete (. comments "batch-delete")]
              (let [result (batch-delete 12345 [])]
                (assert.is_true result.ok)
                (assert.equals 0 (length result.deleted))
                (assert.equals 0 (length result.errors))))))))))
