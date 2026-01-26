;; Tests for longway.ui.confirm
;;
;; Tests confirmation UI module

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local confirm (require :longway.ui.confirm))

(describe "longway.ui.confirm"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "module structure"
      (fn []
        (it "exports confirm function"
          (fn []
            (assert.is_function confirm.confirm)))

        (it "exports confirm-sync function"
          (fn []
            (assert.is_function (. confirm "confirm-sync"))))

        (it "exports confirm-delete-tasks function"
          (fn []
            (assert.is_function (. confirm "confirm-delete-tasks"))))

        (it "exports confirm-delete-task-ids function"
          (fn []
            (assert.is_function (. confirm "confirm-delete-task-ids"))))

        (it "exports confirm-overwrite function"
          (fn []
            (assert.is_function (. confirm "confirm-overwrite"))))

        (it "exports prompt-delete-or-skip function"
          (fn []
            (assert.is_function (. confirm "prompt-delete-or-skip"))))))))
