;; Tests for longway.ui.statusline
;;
;; Tests statusline component module

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local statusline (require :longway.ui.statusline))

(describe "longway.ui.statusline"
  (fn []
    (before_each (fn []
      (t.setup-test-config {})
      (statusline.teardown)))

    (after_each (fn []
      (statusline.teardown)))

    (describe "module structure"
      (fn []
        (it "exports is-longway-buffer function"
          (fn []
            (let [is-longway-buffer (. statusline "is-longway-buffer")]
              (assert.is_function is-longway-buffer))))

        (it "exports get-status function"
          (fn []
            (let [get-status (. statusline "get-status")]
              (assert.is_function get-status))))

        (it "exports get-status-data function"
          (fn []
            (let [get-status-data (. statusline "get-status-data")]
              (assert.is_function get-status-data))))

        (it "exports lualine-component function"
          (fn []
            (let [lualine-component (. statusline "lualine-component")]
              (assert.is_function lualine-component))))

        (it "exports setup function"
          (fn []
            (assert.is_function statusline.setup)))

        (it "exports teardown function"
          (fn []
            (assert.is_function statusline.teardown)))))

    (describe "is-longway-buffer"
      (fn []
        (it "returns false for a non-longway buffer"
          (fn []
            (let [is-longway-buffer (. statusline "is-longway-buffer")]
              ;; Current test buffer is not a longway file
              (assert.is_false (is-longway-buffer)))))))

    (describe "get-status"
      (fn []
        (it "returns nil for non-longway buffer"
          (fn []
            (let [get-status (. statusline "get-status")]
              (assert.is_nil (get-status)))))))

    (describe "get-status-data"
      (fn []
        (it "returns nil for non-longway buffer"
          (fn []
            (let [get-status-data (. statusline "get-status-data")]
              (assert.is_nil (get-status-data)))))))

    (describe "lualine-component"
      (fn []
        (it "returns a table with expected fields"
          (fn []
            (let [lualine-component (. statusline "lualine-component")
                  component (lualine-component)]
              (assert.is_table component)
              ;; The function field (lualine uses numeric key 1)
              (assert.is_function (. component 1))
              ;; The cond field
              (assert.is_function component.cond)
              ;; The color field
              (assert.is_function component.color))))))

    (describe "setup"
      (fn []
        (it "creates augroup"
          (fn []
            (statusline.setup)
            (let [autocmds (vim.api.nvim_get_autocmds {:group "longway_statusline"})]
              (assert.is_true (>= (length autocmds) 1)))))

        (it "registers BufEnter and BufWritePost autocmds"
          (fn []
            (statusline.setup)
            (let [enter-cmds (vim.api.nvim_get_autocmds {:group "longway_statusline"
                                                          :event "BufEnter"})
                  write-cmds (vim.api.nvim_get_autocmds {:group "longway_statusline"
                                                          :event "BufWritePost"})]
              (assert.equals 1 (length enter-cmds))
              (assert.equals 1 (length write-cmds)))))

        (it "is idempotent"
          (fn []
            (statusline.setup)
            (statusline.setup)
            (let [autocmds (vim.api.nvim_get_autocmds {:group "longway_statusline"})]
              ;; Should have exactly 2 autocmds (BufEnter + BufWritePost), not more
              (assert.equals 2 (length autocmds)))))))

    (describe "teardown"
      (fn []
        (it "removes augroup"
          (fn []
            (statusline.setup)
            (statusline.teardown)
            (let [(ok _) (pcall vim.api.nvim_get_autocmds {:group "longway_statusline"})]
              (assert.is_false ok))))

        (it "is safe to call when not set up"
          (fn []
            (statusline.teardown)
            (assert.is_true true)))))))
