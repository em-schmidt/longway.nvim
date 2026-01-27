;; Tests for longway.sync.auto
;;
;; Tests auto-push on save setup and teardown

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local auto (require :longway.sync.auto))

(describe "longway.sync.auto"
  (fn []
    (before_each (fn []
      (t.setup-test-config {})
      ;; Ensure clean state
      (auto.teardown)))

    (after_each (fn []
      ;; Clean up after each test
      (auto.teardown)))

    (describe "is-active"
      (fn []
        (it "returns false when not set up"
          (fn []
            (let [is-active (. auto "is-active")]
              (assert.is_false (is-active)))))

        (it "returns true after setup"
          (fn []
            (let [is-active (. auto "is-active")]
              (auto.setup)
              (assert.is_true (is-active)))))

        (it "returns false after teardown"
          (fn []
            (let [is-active (. auto "is-active")]
              (auto.setup)
              (auto.teardown)
              (assert.is_false (is-active)))))))

    (describe "setup"
      (fn []
        (it "creates augroup"
          (fn []
            (auto.setup)
            ;; Verify the augroup exists by trying to get its autocmds
            (let [autocmds (vim.api.nvim_get_autocmds {:group "longway_auto_push"})]
              (assert.is_true (>= (length autocmds) 1)))))

        (it "registers BufWritePost autocmd for markdown files"
          (fn []
            (auto.setup)
            (let [autocmds (vim.api.nvim_get_autocmds {:group "longway_auto_push"
                                                       :event "BufWritePost"})]
              (assert.equals 1 (length autocmds))
              (assert.equals "*.md" (. autocmds 1 :pattern)))))

        (it "clears previous setup on re-setup"
          (fn []
            (auto.setup)
            (auto.setup)
            ;; Should only have one autocmd, not two
            (let [autocmds (vim.api.nvim_get_autocmds {:group "longway_auto_push"})]
              (assert.equals 1 (length autocmds)))))))

    (describe "teardown"
      (fn []
        (it "removes augroup"
          (fn []
            (auto.setup)
            (auto.teardown)
            ;; Augroup should not exist anymore
            (let [(ok _) (pcall vim.api.nvim_get_autocmds {:group "longway_auto_push"})]
              (assert.is_false ok))))

        (it "is safe to call when not set up"
          (fn []
            ;; Should not error
            (auto.teardown)
            (assert.is_true true)))))))
