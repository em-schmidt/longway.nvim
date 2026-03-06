;; Tests for longway.ui.diagnostics
;;
;; Tests header validation diagnostics for synced sections

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local diagnostics (require :longway.ui.diagnostics))

(describe "longway.ui.diagnostics"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "check"
      (fn []
        (it "sets warnings for unknown ## headers in longway files"
          (fn []
            (let [bufnr (vim.api.nvim_create_buf false true)
                  lines ["---"
                         "shortcut_id: 12345"
                         "shortcut_type: story"
                         "---"
                         ""
                         "# Title"
                         ""
                         "## Description"
                         ""
                         "Some text"
                         ""
                         "## CustomHeader"
                         ""
                         "Bad content"
                         ""
                         "## Tasks"
                         ""
                         "- [ ] task"]]
              (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
              (diagnostics.check bufnr)
              (let [diags (vim.diagnostic.get bufnr)]
                ;; Should have 1 warning for ## CustomHeader
                (assert.equals 1 (length diags))
                (assert.equals vim.diagnostic.severity.WARN (. diags 1 :severity))
                (assert.equals 11 (. diags 1 :lnum)))  ;; 0-indexed line 11 = "## CustomHeader"
              (vim.api.nvim_buf_delete bufnr {:force true}))))

        (it "does not warn for known section headers"
          (fn []
            (let [bufnr (vim.api.nvim_create_buf false true)
                  lines ["---"
                         "shortcut_id: 12345"
                         "shortcut_type: story"
                         "---"
                         ""
                         "# Title"
                         ""
                         "## Description"
                         ""
                         "Desc"
                         ""
                         "## Tasks"
                         ""
                         "## Comments"
                         ""
                         "## Local Notes"]]
              (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
              (diagnostics.check bufnr)
              (let [diags (vim.diagnostic.get bufnr)]
                (assert.equals 0 (length diags)))
              (vim.api.nvim_buf_delete bufnr {:force true}))))

        (it "does not warn for ### subheadings"
          (fn []
            (let [bufnr (vim.api.nvim_create_buf false true)
                  lines ["---"
                         "shortcut_id: 12345"
                         "shortcut_type: story"
                         "---"
                         ""
                         "# Title"
                         ""
                         "## Description"
                         ""
                         "### Subheading"
                         ""
                         "Details here"]]
              (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
              (diagnostics.check bufnr)
              (let [diags (vim.diagnostic.get bufnr)]
                (assert.equals 0 (length diags)))
              (vim.api.nvim_buf_delete bufnr {:force true}))))

        (it "warns for # (h1) headers after the title"
          (fn []
            (let [bufnr (vim.api.nvim_create_buf false true)
                  lines ["---"
                         "shortcut_id: 12345"
                         "shortcut_type: story"
                         "---"
                         ""
                         "# Title"
                         ""
                         "## Description"
                         ""
                         "# Bad H1 Header"
                         ""
                         "Content"]]
              (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
              (diagnostics.check bufnr)
              (let [diags (vim.diagnostic.get bufnr)]
                (assert.equals 1 (length diags))
                (assert.equals 9 (. diags 1 :lnum)))  ;; 0-indexed line 9 = "# Bad H1 Header"
              (vim.api.nvim_buf_delete bufnr {:force true}))))

        (it "does not set diagnostics for non-longway files"
          (fn []
            (let [bufnr (vim.api.nvim_create_buf false true)
                  lines ["# Regular File"
                         ""
                         "## Some Heading"
                         ""
                         "Content"]]
              (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
              (diagnostics.check bufnr)
              (let [diags (vim.diagnostic.get bufnr)]
                (assert.equals 0 (length diags)))
              (vim.api.nvim_buf_delete bufnr {:force true}))))))))
