;; Tests for longway.ui.picker
;;
;; Tests picker module structure and helper functions

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local picker (require :longway.ui.picker))

(describe "longway.ui.picker"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "module structure"
      (fn []
        (it "exports check-snacks function"
          (fn []
            (let [check-snacks (. picker "check-snacks")]
              (assert.is_function check-snacks))))

        (it "exports pick-stories function"
          (fn []
            (let [pick-stories (. picker "pick-stories")]
              (assert.is_function pick-stories))))

        (it "exports pick-epics function"
          (fn []
            (let [pick-epics (. picker "pick-epics")]
              (assert.is_function pick-epics))))

        (it "exports pick-presets function"
          (fn []
            (let [pick-presets (. picker "pick-presets")]
              (assert.is_function pick-presets))))

        (it "exports pick-modified function"
          (fn []
            (let [pick-modified (. picker "pick-modified")]
              (assert.is_function pick-modified))))

        (it "exports pick-comments function"
          (fn []
            (let [pick-comments (. picker "pick-comments")]
              (assert.is_function pick-comments))))))

    (describe "check-snacks"
      (fn []
        (it "returns a boolean"
          (fn []
            (let [check-snacks (. picker "check-snacks")
                  result (check-snacks)]
              (assert.is_boolean result))))

        (it "returns false when snacks is not installed"
          (fn []
            ;; In test environment snacks is not available
            (assert.is_false (picker.check-snacks))))))

    (describe "truncate"
      (fn []
        (it "returns empty string for nil input"
          (fn []
            (assert.equals "" (picker.truncate nil 10))))

        (it "returns original string when shorter than max"
          (fn []
            (assert.equals "hello" (picker.truncate "hello" 10))))

        (it "returns original string when exactly max length"
          (fn []
            (assert.equals "hello" (picker.truncate "hello" 5))))

        (it "truncates and appends ... when longer than max"
          (fn []
            (assert.equals "hel..." (picker.truncate "hello world" 6))))

        (it "handles empty string"
          (fn []
            (assert.equals "" (picker.truncate "" 10))))))

    (describe "first-line"
      (fn []
        (it "returns empty string for nil input"
          (fn []
            (assert.equals "" (picker.first-line nil))))

        (it "returns the only line of a single-line string"
          (fn []
            (assert.equals "hello" (picker.first-line "hello"))))

        (it "returns first line of multi-line string"
          (fn []
            (assert.equals "first" (picker.first-line "first\nsecond\nthird"))))

        (it "trims surrounding whitespace"
          (fn []
            (assert.equals "hello" (picker.first-line "  hello  "))))

        (it "handles empty string"
          (fn []
            (assert.equals "" (picker.first-line ""))))))

    (describe "find-local-file"
      (fn []
        (it "returns nil when no matching file exists"
          (fn []
            ;; Test workspace doesn't have any files
            (let [find-local-file (. picker "find-local-file")
                  result (find-local-file 99999 "story")]
              (assert.is_nil result))))

        (it "finds a story file by shortcut_id"
          (fn []
            ;; Create the stories directory and a test file
            (let [stories-dir (.. "/tmp/longway-test/stories")]
              (vim.fn.mkdir stories-dir "p")
              (let [filepath (.. stories-dir "/12345-test-story.md")
                    f (io.open filepath "w")]
                (f:write "test")
                (f:close)
                (let [result (picker.find-local-file 12345 "story")]
                  (assert.equals filepath result))
                ;; Clean up
                (os.remove filepath)))))

        (it "finds an epic file by shortcut_id"
          (fn []
            (let [epics-dir (.. "/tmp/longway-test/epics")]
              (vim.fn.mkdir epics-dir "p")
              (let [filepath (.. epics-dir "/99999-test-epic.md")
                    f (io.open filepath "w")]
                (f:write "test")
                (f:close)
                (let [result (picker.find-local-file 99999 "epic")]
                  (assert.equals filepath result))
                (os.remove filepath)))))))

    (describe "build-picker-layout"
      (fn []
        (it "returns default layout when no picker config"
          (fn []
            (t.setup-test-config {})
            (let [layout (picker.build-picker-layout)]
              (assert.is_table layout)
              (assert.equals "default" layout.preset)
              (assert.is_true layout.preview))))

        (it "respects custom layout setting"
          (fn []
            (t.setup-test-config {:picker {:layout "ivy" :preview true}})
            (let [layout (picker.build-picker-layout)]
              (assert.equals "ivy" layout.preset))))

        (it "respects preview=false setting"
          (fn []
            (t.setup-test-config {:picker {:layout "default" :preview false}})
            (let [layout (picker.build-picker-layout)]
              (assert.is_false layout.preview))))))))
