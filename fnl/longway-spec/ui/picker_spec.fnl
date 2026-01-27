;; Tests for longway.ui.picker
;;
;; Tests picker module structure and helpers

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
              (assert.is_boolean result))))))))
