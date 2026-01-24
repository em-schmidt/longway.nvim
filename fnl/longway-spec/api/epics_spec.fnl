;; Tests for longway.api.epics
;;
;; Tests Epics API module

(local t (require :longway-spec.init))
(local epics (require :longway.api.epics))

(describe "longway.api.epics"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "get"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function epics.get)))))

    (describe "list"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function epics.list)))))

    (describe "update"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function epics.update)))))

    (describe "create"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function epics.create)))))

    (describe "delete"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function epics.delete)))))

    (describe "list-stories"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function epics.list_stories)))))

    (describe "get-with-stories"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function epics.get_with_stories)))))

    (describe "get-stats"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function epics.get_stats)))

        (it "calculates stats from epic data"
          (fn []
            (let [epic {:stats {:num_stories 10
                                :num_stories_started 3
                                :num_stories_done 5
                                :num_stories_unstarted 2
                                :num_points 20
                                :num_points_done 10}}
                  stats (epics.get_stats epic)]
              (assert.equals 10 stats.total)
              (assert.equals 5 stats.done)
              (assert.equals 3 stats.started)
              (assert.equals 2 stats.unstarted))))))

    (describe "get-progress"
      (fn []
        (it "is a function"
          (fn []
            (assert.is_function epics.get_progress)))

        (it "calculates percentage progress"
          (fn []
            (let [epic {:stats {:num_stories 10 :num_stories_done 5}}
                  progress (epics.get_progress epic)]
              (assert.equals 50 progress))))

        (it "returns 0 for empty epic"
          (fn []
            (let [epic {:stats {:num_stories 0 :num_stories_done 0}}
                  progress (epics.get_progress epic)]
              (assert.equals 0 progress))))))))
