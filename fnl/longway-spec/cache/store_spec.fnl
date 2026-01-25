;; Tests for longway.cache.store
;;
;; Tests cache module functionality

(local t (require :longway-spec.init))
(local cache (require :longway.cache.store))

(describe "longway.cache.store"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "get"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function cache.get)))

        (it "returns expired for missing cache"
          (fn []
            (let [result (cache.get :nonexistent)]
              (assert.is_true result.expired))))))

    (describe "set"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function cache.set)))))

    (describe "invalidate"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function cache.invalidate)))

        (it "returns ok for any cache type"
          (fn []
            (let [result (cache.invalidate :members)]
              (assert.is_true result.ok))))))

    (describe "invalidate-all"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. cache "invalidate-all"))))

        (it "returns ok"
          (fn []
            (let [invalidate-all (. cache "invalidate-all")
                  result (invalidate-all)]
              (assert.is_true result.ok))))))

    (describe "get-or-fetch"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. cache "get-or-fetch"))))

        (it "calls fetch function when cache is empty"
          (fn []
            ;; Invalidate first to ensure cache is empty
            (cache.invalidate :members)
            (var fetch-called false)
            (let [fetch-fn (fn []
                            (set fetch-called true)
                            {:ok true :data {:test true}})
                  get-or-fetch (. cache "get-or-fetch")]
              (get-or-fetch :members fetch-fn)
              (assert.is_true fetch-called))))))

    (describe "get-age"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. cache "get-age"))))

        (it "returns nil for missing cache"
          (fn []
            (let [get-age (. cache "get-age")
                  age (get-age :nonexistent)]
              (assert.is_nil age))))))

    (describe "get-status"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. cache "get-status"))))

        (it "returns a table"
          (fn []
            (let [get-status (. cache "get-status")
                  status (get-status)]
              (assert.is_table status))))))

    (describe "refresh"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function cache.refresh)))))))
