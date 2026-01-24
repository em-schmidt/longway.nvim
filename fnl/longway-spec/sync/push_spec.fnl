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
        (it "exports push-current-buffer function"
          (fn []
            (assert.is_function push.push-current-buffer)))

        (it "exports push-story function"
          (fn []
            (assert.is_function push.push-story)))

        (it "exports push-file function"
          (fn []
            (assert.is_function push.push-file)))))

    (describe "push-story"
      (fn []
        (it "requires story-id and parsed arguments"
          (fn []
            ;; Function should exist and be callable
            (assert.is_function push.push-story)))))))
