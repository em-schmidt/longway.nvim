;; Tests for longway.api.tasks
;;
;; Tests task API operations with mock HTTP client

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local tasks (require :longway.api.tasks))

(describe "longway.api.tasks"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "module structure"
      (fn []
        (it "exports create function"
          (fn []
            (assert.is_function tasks.create)))

        (it "exports update function"
          (fn []
            (assert.is_function tasks.update)))

        (it "exports delete function"
          (fn []
            (assert.is_function tasks.delete)))

        (it "exports get function"
          (fn []
            (assert.is_function tasks.get)))

        (it "exports batch-create function"
          (fn []
            (assert.is_function (. tasks "batch-create"))))

        (it "exports batch-update function"
          (fn []
            (assert.is_function (. tasks "batch-update"))))

        (it "exports batch-delete function"
          (fn []
            (assert.is_function (. tasks "batch-delete"))))))

    (describe "batch-create"
      (fn []
        (it "returns ok true with empty tasks list"
          (fn []
            (let [batch-create (. tasks "batch-create")]
              (let [result (batch-create 12345 [])]
                (assert.is_true result.ok)
                (assert.equals 0 (length result.created))
                (assert.equals 0 (length result.errors))))))))

    (describe "batch-update"
      (fn []
        (it "returns ok true with empty updates list"
          (fn []
            (let [batch-update (. tasks "batch-update")]
              (let [result (batch-update 12345 [])]
                (assert.is_true result.ok)
                (assert.equals 0 (length result.updated))
                (assert.equals 0 (length result.errors))))))))

    (describe "batch-delete"
      (fn []
        (it "returns ok true with empty task-ids list"
          (fn []
            (let [batch-delete (. tasks "batch-delete")]
              (let [result (batch-delete 12345 [])]
                (assert.is_true result.ok)
                (assert.equals 0 (length result.deleted))
                (assert.equals 0 (length result.errors))))))))))
