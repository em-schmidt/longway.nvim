;; Tests for longway.api.tasks
;;
;; Tests task API operations

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
            (assert.is_function (. tasks "batch-delete"))))))))
