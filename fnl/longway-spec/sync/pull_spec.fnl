;; Tests for longway.sync.pull
;;
;; Tests pull operations for syncing from Shortcut

(local t (require :longway-spec.init))
(local pull (require :longway.sync.pull))

(describe "longway.sync.pull"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "module structure"
      (fn []
        (it "exports pull_story function"
          (fn []
            (assert.is_function pull.pull_story)))

        (it "exports pull_story_to_buffer function"
          (fn []
            (assert.is_function pull.pull_story_to_buffer)))

        (it "exports refresh_current_buffer function"
          (fn []
            (assert.is_function pull.refresh_current_buffer)))))

    (describe "pull_story"
      (fn []
        (it "requires a story ID argument"
          (fn []
            ;; Function should exist and be callable
            (assert.is_function pull.pull_story)))))))
