;; Tests for longway.util.slug
;;
;; Tests slug generation and sanitization functions

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local slug (require :longway.util.slug))

(describe "longway.util.slug"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "sanitize"
      (fn []
        (it "converts text to lowercase"
          (fn []
            (assert.equals "hello-world" (slug.sanitize "Hello World"))))

        (it "replaces spaces with hyphens"
          (fn []
            (assert.equals "hello-world" (slug.sanitize "hello world"))))

        (it "replaces underscores with hyphens"
          (fn []
            (assert.equals "hello-world" (slug.sanitize "hello_world"))))

        (it "removes special characters"
          (fn []
            (assert.equals "fix-bug-123" (slug.sanitize "Fix Bug #123!@$%"))))

        (it "collapses multiple hyphens"
          (fn []
            (assert.equals "hello-world" (slug.sanitize "hello---world"))))

        (it "removes leading hyphens"
          (fn []
            (assert.equals "hello" (slug.sanitize "---hello"))))

        (it "removes trailing hyphens"
          (fn []
            (assert.equals "hello" (slug.sanitize "hello---"))))

        (it "handles empty string"
          (fn []
            (assert.equals "" (slug.sanitize ""))))

        (it "handles string with only special characters"
          (fn []
            (assert.equals "" (slug.sanitize "!@#$%^&*()"))))

        (it "preserves numbers"
          (fn []
            (assert.equals "issue-42-fix" (slug.sanitize "Issue 42 Fix"))))))

    (describe "truncate"
      (fn []
        (it "returns short text unchanged"
          (fn []
            (assert.equals "hello" (slug.truncate "hello" 50))))

        (it "truncates text at max length"
          (fn []
            (let [result (slug.truncate "hello-world-this-is-long" 15)]
              (assert.is_true (<= (length result) 15)))))

        (it "breaks at hyphen boundaries when possible"
          (fn []
            ;; "hello-world" is 11 chars, truncate to 10 should give "hello"
            (assert.equals "hello" (slug.truncate "hello-world" 10))))

        (it "returns exact truncation when no hyphen found"
          (fn []
            (assert.equals "hello" (slug.truncate "helloworld" 5))))))

    (describe "generate"
      (fn []
        (it "generates valid slug from title"
          (fn []
            (let [result (slug.generate "My Story Title")]
              (assert.is_valid_slug result)
              (assert.equals "my-story-title" result))))

        (it "respects max length from config"
          (fn []
            (t.setup-test-config {:slug_max_length 10})
            (let [result (slug.generate "This Is A Very Long Story Title")]
              (assert.is_true (<= (length result) 10)))))

        (it "handles unicode by removing non-ascii"
          (fn []
            (let [result (slug.generate "Héllo Wörld")]
              ;; Non-ascii chars are removed, leaving what's valid
              (assert.is_valid_slug result))))))

    (describe "make_filename"
      (fn []
        (it "generates filename with id and slug"
          (fn []
            (let [result (slug.make_filename 12345 "My Story")]
              (assert.equals "12345-my-story.md" result))))

        (it "uses custom template from config"
          (fn []
            (t.setup-test-config {:filename_template "{slug}-{id}"})
            (let [result (slug.make_filename 42 "Test Story")]
              (assert.equals "test-story-42.md" result))))

        (it "handles type placeholder"
          (fn []
            (t.setup-test-config {:filename_template "{type}/{id}-{slug}"})
            (let [result (slug.make_filename 123 "Epic Name" "epic")]
              (assert.equals "epic/123-epic-name.md" result))))

        (it "defaults type to story"
          (fn []
            (t.setup-test-config {:filename_template "{type}-{id}"})
            (let [result (slug.make_filename 123 "Test")]
              (assert.equals "story-123.md" result))))))))
