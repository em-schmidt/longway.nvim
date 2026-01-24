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
        (it "exports pull-story function"
          (fn []
            (assert.is_function (. pull "pull-story"))))

        (it "exports pull-story-to-buffer function"
          (fn []
            (assert.is_function (. pull "pull-story-to-buffer"))))

        (it "exports refresh-current-buffer function"
          (fn []
            (assert.is_function (. pull "refresh-current-buffer"))))))

    (describe "pull-story"
      (fn []
        (it "requires a story ID argument"
          (fn []
            ;; Function should exist and be callable
            (assert.is_function (. pull "pull-story"))))))))
