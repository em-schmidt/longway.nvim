;; Tests for longway.ui.statusline
;;
;; Tests statusline component module including functional data-flow tests

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local statusline (require :longway.ui.statusline))

(describe "longway.ui.statusline"
  (fn []
    (before_each (fn []
      (t.setup-test-config {})
      (statusline.teardown)
      ;; Clear any leftover buffer variables on the current buffer
      (let [bufnr (vim.api.nvim_get_current_buf)]
        (pcall vim.api.nvim_buf_del_var bufnr "longway_id")
        (pcall vim.api.nvim_buf_del_var bufnr "longway_type")
        (pcall vim.api.nvim_buf_del_var bufnr "longway_state")
        (pcall vim.api.nvim_buf_del_var bufnr "longway_sync_status")
        (pcall vim.api.nvim_buf_del_var bufnr "longway_conflict")
        (pcall vim.api.nvim_buf_del_var bufnr "longway_changed_sections")
        (pcall vim.api.nvim_buf_del_var bufnr "longway_conflict_sections"))))

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
              (assert.is_false (is-longway-buffer)))))

        (it "returns true when longway_id is set"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 12345)
              (assert.is_true (statusline.is-longway-buffer)))))))

    (describe "get-status"
      (fn []
        (it "returns nil for non-longway buffer"
          (fn []
            (let [get-status (. statusline "get-status")]
              (assert.is_nil (get-status)))))

        (it "returns correct string for synced buffer"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 12345)
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "synced")
              (let [status (statusline.get-status)]
                (assert.is_not_nil status)
                (assert.has_substring status "SC:12345")
                (assert.has_substring status "[synced]")))))

        (it "returns modified indicator when sync_status is modified"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 67890)
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "modified")
              (let [status (statusline.get-status)]
                (assert.has_substring status "SC:67890")
                (assert.has_substring status "[modified]")))))

        (it "returns CONFLICT indicator when sync_status is conflict"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 11111)
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "conflict")
              (let [status (statusline.get-status)]
                (assert.has_substring status "SC:11111")
                (assert.has_substring status "[CONFLICT]")))))

        (it "returns new indicator when sync_status is new"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 99999)
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "new")
              (let [status (statusline.get-status)]
                (assert.has_substring status "SC:99999")
                (assert.has_substring status "[new]")))))))

    (describe "get-status-data"
      (fn []
        (it "returns nil for non-longway buffer"
          (fn []
            (let [get-status-data (. statusline "get-status-data")]
              (assert.is_nil (get-status-data)))))

        (it "returns structured table with all expected fields"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 12345)
              (vim.api.nvim_buf_set_var bufnr "longway_type" "story")
              (vim.api.nvim_buf_set_var bufnr "longway_state" "In Progress")
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "synced")
              (vim.api.nvim_buf_set_var bufnr "longway_conflict" false)
              (vim.api.nvim_buf_set_var bufnr "longway_changed_sections" [])
              (vim.api.nvim_buf_set_var bufnr "longway_conflict_sections" vim.NIL)
              (let [data (statusline.get-status-data)]
                (assert.is_not_nil data)
                (assert.equals 12345 data.shortcut_id)
                (assert.equals "story" data.shortcut_type)
                (assert.equals "In Progress" data.state)
                (assert.equals "synced" data.sync_status)
                (assert.is_table data.changed_sections)
                (assert.equals 0 (length data.changed_sections))
                (assert.is_nil data.conflict_sections)))))

        (it "returns changed_sections listing which sections differ"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 22222)
              (vim.api.nvim_buf_set_var bufnr "longway_type" "story")
              (vim.api.nvim_buf_set_var bufnr "longway_state" "Started")
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "modified")
              (vim.api.nvim_buf_set_var bufnr "longway_changed_sections"
                                        ["description" "tasks"])
              (vim.api.nvim_buf_set_var bufnr "longway_conflict_sections" vim.NIL)
              (let [data (statusline.get-status-data)]
                (assert.equals "modified" data.sync_status)
                (assert.is_table data.changed_sections)
                (assert.equals 2 (length data.changed_sections))
                (assert.equals "description" (. data.changed_sections 1))
                (assert.equals "tasks" (. data.changed_sections 2))
                (assert.is_nil data.conflict_sections)))))

        (it "returns conflict_sections when conflicts exist"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 33333)
              (vim.api.nvim_buf_set_var bufnr "longway_type" "story")
              (vim.api.nvim_buf_set_var bufnr "longway_state" "Started")
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "conflict")
              (vim.api.nvim_buf_set_var bufnr "longway_conflict" true)
              (vim.api.nvim_buf_set_var bufnr "longway_changed_sections" ["description"])
              (vim.api.nvim_buf_set_var bufnr "longway_conflict_sections"
                                        ["description" "tasks"])
              (let [data (statusline.get-status-data)]
                (assert.equals "conflict" data.sync_status)
                (assert.is_not_nil data.conflict_sections)
                (assert.is_table data.conflict_sections)
                (assert.equals 2 (length data.conflict_sections))
                (assert.equals "description" (. data.conflict_sections 1))
                (assert.equals "tasks" (. data.conflict_sections 2))))))))

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
              (assert.is_function component.color))))

        (it "color returns green for synced buffers"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 55555)
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "synced")
              (let [component (statusline.lualine-component)
                    color (component.color)]
                (assert.is_table color)
                (assert.equals "#a6e3a1" color.fg)))))

        (it "color returns yellow for modified buffers"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 55555)
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "modified")
              (let [component (statusline.lualine-component)
                    color (component.color)]
                (assert.equals "#f9e2af" color.fg)))))

        (it "color returns red for conflict buffers"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 55555)
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "conflict")
              (let [component (statusline.lualine-component)
                    color (component.color)]
                (assert.equals "#f38ba8" color.fg)))))

        (it "color returns blue for new buffers"
          (fn []
            (let [bufnr (vim.api.nvim_get_current_buf)]
              (vim.api.nvim_buf_set_var bufnr "longway_id" 55555)
              (vim.api.nvim_buf_set_var bufnr "longway_sync_status" "new")
              (let [component (statusline.lualine-component)
                    color (component.color)]
                (assert.equals "#89b4fa" color.fg)))))))

    (describe "autocmd refresh"
      (fn []
        (it "sets buffer variables for longway markdown files on BufEnter"
          (fn []
            ;; Create a markdown file with mismatched hashes (will show as modified)
            (let [markdown "---\nshortcut_id: 44444\nshortcut_type: story\nstate: Started\nsync_hash: oldhash\ntasks_hash: oldhash\ncomments_hash: oldhash\n---\n\n# Test Story\n\n## Description\n\n<!-- BEGIN SHORTCUT SYNC:description -->\nSome content\n<!-- END SHORTCUT SYNC:description -->\n\n## Tasks\n\n<!-- BEGIN SHORTCUT SYNC:tasks -->\n<!-- END SHORTCUT SYNC:tasks -->\n\n## Comments\n\n<!-- BEGIN SHORTCUT SYNC:comments -->\n<!-- END SHORTCUT SYNC:comments -->\n"
                  tmpfile "/tmp/longway-test-autocmd-refresh.md"]
              (let [f (io.open tmpfile "w")]
                (f:write markdown)
                (f:close))
              (vim.cmd (.. "edit " tmpfile))
              (let [bufnr (vim.api.nvim_get_current_buf)
                    lines (vim.split markdown "\n" {:plain true})]
                (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
                (statusline.setup)
                (vim.cmd "doautocmd BufEnter")
                ;; Check that buffer variables were set
                (let [id (vim.api.nvim_buf_get_var bufnr "longway_id")]
                  (assert.equals 44444 id))
                (let [sync-status (vim.api.nvim_buf_get_var bufnr "longway_sync_status")]
                  ;; With mismatched hashes, status should be "modified"
                  (assert.equals "modified" sync-status))
                (let [changed-sections (vim.api.nvim_buf_get_var bufnr "longway_changed_sections")]
                  (assert.is_table changed-sections)
                  ;; Description hash doesn't match, so description should be in changed_sections
                  (var found-desc false)
                  (each [_ s (ipairs changed-sections)]
                    (when (= s "description")
                      (set found-desc true)))
                  (assert.is_true found-desc)))
              (vim.cmd "bdelete!")
              (os.remove tmpfile))))

        (it "sets conflict status when conflict_sections is present"
          (fn []
            (let [markdown "---\nshortcut_id: 55555\nshortcut_type: story\nstate: Started\nsync_hash: abc\nconflict_sections:\n  - description\n---\n\n# Conflict Story\n\n## Description\n\n<!-- BEGIN SHORTCUT SYNC:description -->\nContent\n<!-- END SHORTCUT SYNC:description -->\n"
                  tmpfile "/tmp/longway-test-autocmd-conflict.md"]
              (let [f (io.open tmpfile "w")]
                (f:write markdown)
                (f:close))
              (vim.cmd (.. "edit " tmpfile))
              (let [bufnr (vim.api.nvim_get_current_buf)
                    lines (vim.split markdown "\n" {:plain true})]
                (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
                (statusline.setup)
                (vim.cmd "doautocmd BufEnter")
                (let [sync-status (vim.api.nvim_buf_get_var bufnr "longway_sync_status")]
                  (assert.equals "conflict" sync-status))
                (let [conflict (vim.api.nvim_buf_get_var bufnr "longway_conflict")]
                  (assert.is_true conflict)))
              (vim.cmd "bdelete!")
              (os.remove tmpfile))))

        (it "marks non-longway markdown files as non-longway"
          (fn []
            (let [markdown "# Just a regular markdown file\n\nNo frontmatter here.\n"
                  tmpfile "/tmp/longway-test-autocmd-nonlongway.md"]
              (let [f (io.open tmpfile "w")]
                (f:write markdown)
                (f:close))
              (vim.cmd (.. "edit " tmpfile))
              (let [bufnr (vim.api.nvim_get_current_buf)
                    lines (vim.split markdown "\n" {:plain true})]
                (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
                (statusline.setup)
                (vim.cmd "doautocmd BufEnter")
                ;; is-longway-buffer should return false for non-longway .md files
                (assert.is_false (statusline.is-longway-buffer))
                ;; get-status should return nil
                (assert.is_nil (statusline.get-status)))
              (vim.cmd "bdelete!")
              (os.remove tmpfile))))))

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
