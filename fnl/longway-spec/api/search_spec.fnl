;; Tests for longway.api.search
;;
;; Tests Search API module

(local t (require :longway-spec.init))
(local search (require :longway.api.search))

(describe "longway.api.search"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "search-stories"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. search "search-stories"))))))

    (describe "search-stories-all"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. search "search-stories-all"))))))

    (describe "search-epics"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. search "search-epics"))))))

    (describe "build-query"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. search "build-query"))))

        (it "builds query from simple filters"
          (fn []
            (let [build-query (. search "build-query")
                  query (build-query {:owner "me" :type "feature"})]
              (assert.is_string query)
              (assert.truthy (string.find query "owner:me"))
              (assert.truthy (string.find query "type:feature")))))

        (it "quotes values with spaces"
          (fn []
            (let [build-query (. search "build-query")
                  query (build-query {:state "In Progress"})]
              (assert.truthy (string.find query "\"In Progress\"")))))))

    (describe "parse-query"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function (. search "parse-query"))))

        (it "parses key:value pairs"
          (fn []
            (let [parse-query (. search "parse-query")
                  result (parse-query "owner:me state:started")]
              (assert.is_table result)
              (assert.is_table result.params))))))))
