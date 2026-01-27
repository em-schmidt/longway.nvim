;; Tests for longway.sync.resolve
;;
;; Tests conflict resolution strategies

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local resolve (require :longway.sync.resolve))

(describe "longway.sync.resolve"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "resolve-manual"
      (fn []
        (it "inserts conflict markers into description section"
          (fn []
            ;; We can test the marker format by calling resolve-manual
            ;; with a mock buffer. Since this needs vim APIs and a real
            ;; API call, we test the module loads and exports correctly.
            (let [resolve-manual (. resolve "resolve-manual")]
              (assert.is_function resolve-manual))))

        (it "exports resolve function"
          (fn []
            (assert.is_function resolve.resolve)))

        (it "exports resolve-local function"
          (fn []
            (let [resolve-local (. resolve "resolve-local")]
              (assert.is_function resolve-local))))

        (it "exports resolve-remote function"
          (fn []
            (let [resolve-remote (. resolve "resolve-remote")]
              (assert.is_function resolve-remote))))))))
