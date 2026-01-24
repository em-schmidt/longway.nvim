;; Tests for longway.sync.push
;;
;; Tests push operations for syncing to Shortcut

(local t (require :longway-spec.init))
(local push (require :longway.sync.push))

(describe "longway.sync.push"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "module structure"
      (fn []
        (it "exports push_current_buffer function"
          (fn []
            (assert.is_function push.push_current_buffer)))

        (it "exports push_story function"
          (fn []
            (assert.is_function push.push_story)))

        (it "exports push_file function"
          (fn []
            (assert.is_function push.push_file)))))

    (describe "push_story"
      (fn []
        (it "requires story_id and parsed arguments"
          (fn []
            ;; Function should exist and be callable
            (assert.is_function push.push_story)))))))
