;; Tests for longway.ui.progress
;;
;; Tests progress tracking module

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local progress (require :longway.ui.progress))

(describe "longway.ui.progress"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "module structure"
      (fn []
        (it "exports start function"
          (fn []
            (assert.is_function progress.start)))

        (it "exports update function"
          (fn []
            (assert.is_function progress.update)))

        (it "exports finish function"
          (fn []
            (assert.is_function progress.finish)))

        (it "exports is-available function"
          (fn []
            (let [is-available (. progress "is-available")]
              (assert.is_function is-available))))))

    (describe "start"
      (fn []
        (it "returns a progress ID string"
          (fn []
            (let [id (progress.start "Syncing" 10)]
              (assert.is_string id)
              (assert.has_substring id "longway_progress_"))))

        (it "includes operation name in progress ID"
          (fn []
            (let [id (progress.start "Pushing" 5)]
              (assert.has_substring id "Pushing"))))))

    (describe "update"
      (fn []
        (it "does not error with valid arguments"
          (fn []
            (let [id (progress.start "Syncing" 10)]
              (progress.update id 1 10 "Test item")
              (assert.is_true true))))

        (it "does not error without item name"
          (fn []
            (let [id (progress.start "Syncing" 10)]
              (progress.update id 1 10 nil)
              (assert.is_true true))))

        (it "does not error with unknown progress ID"
          (fn []
            (progress.update "unknown_id" 1 10 "Test")
            (assert.is_true true)))))

    (describe "finish"
      (fn []
        (it "does not error with valid arguments"
          (fn []
            (let [id (progress.start "Syncing" 10)]
              (progress.finish id 8 2)
              (assert.is_true true))))

        (it "does not error with zero failed"
          (fn []
            (let [id (progress.start "Syncing" 5)]
              (progress.finish id 5 0)
              (assert.is_true true))))

        (it "does not error with nil failed"
          (fn []
            (let [id (progress.start "Syncing" 5)]
              (progress.finish id 5 nil)
              (assert.is_true true))))))

    (describe "is-available"
      (fn []
        (it "returns a boolean"
          (fn []
            (let [is-available (. progress "is-available")
                  result (is-available)]
              (assert.is_boolean result))))))

    (describe "progress suppression"
      (fn []
        (it "update respects config.progress = false"
          (fn []
            (t.setup-test-config {:progress false})
            (let [id (progress.start "Syncing" 10)]
              ;; Should not error even when progress is disabled
              (progress.update id 1 10 "Test")
              (assert.is_true true))))))))
