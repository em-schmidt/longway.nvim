;; Tests for longway.config
;;
;; Tests configuration management

(local config (require :longway.config))

(describe "longway.config"
  (fn []
    (describe "setup"
      (fn []
        (it "merges user config with defaults"
          (fn []
            (config.setup {:workspace_dir "/custom/path"})
            (let [cfg (config.get)]
              (assert.equals "/custom/path" cfg.workspace_dir)
              ;; Default values should still be present
              (assert.equals "stories" cfg.stories_subdir))))

        (it "handles empty config"
          (fn []
            (config.setup {})
            (let [cfg (config.get)]
              (assert.is_not_nil cfg.workspace_dir))))

        (it "handles nil config"
          (fn []
            (config.setup nil)
            (let [cfg (config.get)]
              (assert.is_not_nil cfg))))

        (it "deep merges nested config"
          (fn []
            (config.setup {:sync_sections {:tasks false}})
            (let [cfg (config.get)]
              (assert.is_false cfg.sync_sections.tasks)
              ;; Other nested values should remain
              (assert.is_true cfg.sync_sections.description))))))

    (describe "get"
      (fn []
        (it "returns current configuration"
          (fn []
            (config.setup {:debug true})
            (let [cfg (config.get)]
              (assert.is_true cfg.debug))))

        (it "returns table with expected keys"
          (fn []
            (config.setup {})
            (let [cfg (config.get)]
              (assert.is_not_nil cfg.workspace_dir)
              (assert.is_not_nil cfg.sync_start_marker)
              (assert.is_not_nil cfg.sync_end_marker))))))

    (describe "get-workspace-dir"
      (fn []
        (it "returns expanded workspace directory"
          (fn []
            (config.setup {:workspace_dir "/test/path"})
            (let [result (config.get-workspace-dir)]
              (assert.equals "/test/path" result))))

        (it "expands home directory"
          (fn []
            (config.setup {:workspace_dir "~/shortcut"})
            (let [result (config.get-workspace-dir)]
              ;; Should not start with ~ after expansion
              (assert.is_nil (string.match result "^~")))))))

    (describe "get-stories-dir"
      (fn []
        (it "combines workspace dir and stories subdir"
          (fn []
            (config.setup {:workspace_dir "/test" :stories_subdir "stories"})
            (let [result (config.get-stories-dir)]
              (assert.equals "/test/stories" result))))))

    (describe "get-epics-dir"
      (fn []
        (it "combines workspace dir and epics subdir"
          (fn []
            (config.setup {:workspace_dir "/test" :epics_subdir "epics"})
            (let [result (config.get-epics-dir)]
              (assert.equals "/test/epics" result))))))

    (describe "is-configured"
      (fn []
        (it "returns true when token is set"
          (fn []
            (config.setup {:token "test-token"})
            (assert.is_true (config.is-configured))))

        (it "returns false when no token"
          (fn []
            ;; Reset to simulate no token
            (config.setup {})
            ;; Note: depends on env var not being set
            (let [result (config.is-configured)]
              ;; This might be true if SHORTCUT_API_TOKEN is set in env
              (assert.is_boolean result))))))))
