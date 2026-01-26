;; Tests for longway.sync.comments
;;
;; Tests comment synchronization logic

(local t (require :longway-spec.init))
(require :longway-spec.assertions)
(local comments-sync (require :longway.sync.comments))
(local comments-md (require :longway.markdown.comments))
(local hash (require :longway.util.hash))

(describe "longway.sync.comments"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "diff"
      (fn []
        (it "detects new local comments"
          (fn []
            (let [local-comments [{:text "New comment" :is_new true}]
                  remote-comments []
                  result (comments-sync.diff local-comments remote-comments)]
              (assert.equals 1 (length result.created))
              (assert.equals 0 (length result.deleted))
              (assert.equals 0 (length result.edited))
              (assert.equals 0 (length result.unchanged)))))

        (it "detects deleted comments"
          (fn []
            (let [local-comments []
                  remote-comments [{:id 1 :text "Remote comment" :is_new false}]
                  result (comments-sync.diff local-comments remote-comments)]
              (assert.equals 0 (length result.created))
              (assert.equals 1 (length result.deleted))
              (assert.equals 1 (. result.deleted 1)))))

        (it "detects edited comments"
          (fn []
            (let [local-comments [{:id 1 :text "Edited text" :is_new false}]
                  remote-comments [{:id 1 :text "Original text" :is_new false}]
                  result (comments-sync.diff local-comments remote-comments)]
              (assert.equals 0 (length result.created))
              (assert.equals 0 (length result.deleted))
              (assert.equals 1 (length result.edited)))))

        (it "detects unchanged comments"
          (fn []
            (let [local-comments [{:id 1 :text "Same text" :is_new false}]
                  remote-comments [{:id 1 :text "Same text" :is_new false}]
                  result (comments-sync.diff local-comments remote-comments)]
              (assert.equals 0 (length result.created))
              (assert.equals 0 (length result.deleted))
              (assert.equals 0 (length result.edited))
              (assert.equals 1 (length result.unchanged)))))

        (it "handles complex diff scenario"
          (fn []
            (let [local-comments [{:id 1 :text "Unchanged" :is_new false}
                                  {:id 2 :text "Edited text" :is_new false}
                                  {:text "Brand new" :is_new true}]
                  remote-comments [{:id 1 :text "Unchanged" :is_new false}
                                   {:id 2 :text "Original text" :is_new false}
                                   {:id 3 :text "Will be deleted" :is_new false}]
                  result (comments-sync.diff local-comments remote-comments)]
              (assert.equals 1 (length result.created))
              (assert.equals 1 (length result.deleted))
              (assert.equals 1 (length result.edited))
              (assert.equals 1 (length result.unchanged)))))

        (it "handles nil local comments"
          (fn []
            (let [remote-comments [{:id 1 :text "Comment" :is_new false}]
                  result (comments-sync.diff nil remote-comments)]
              (assert.equals 0 (length result.created))
              (assert.equals 1 (length result.deleted)))))

        (it "handles nil remote comments"
          (fn []
            (let [local-comments [{:text "New" :is_new true}]
                  result (comments-sync.diff local-comments nil)]
              (assert.equals 1 (length result.created))
              (assert.equals 0 (length result.deleted)))))

        (it "handles both nil"
          (fn []
            (let [result (comments-sync.diff nil nil)]
              (assert.equals 0 (length result.created))
              (assert.equals 0 (length result.deleted))
              (assert.equals 0 (length result.edited))
              (assert.equals 0 (length result.unchanged)))))

        (it "treats locally present comment missing from remote as new"
          (fn []
            (let [local-comments [{:id 99 :text "Retained" :is_new false}]
                  remote-comments [] ;; comment was deleted remotely
                  result (comments-sync.diff local-comments remote-comments)]
              ;; Comment should be treated as new (re-create) since remote deleted it
              (assert.equals 1 (length result.created))
              (assert.equals 0 (length result.edited)))))))

    (describe "has-changes?"
      (fn []
        (it "returns true when there are created comments"
          (fn []
            (let [diff {:created [{:text "New"}] :deleted [] :edited [] :unchanged []}
                  has-changes? (. comments-sync "has-changes?")]
              (assert.is_true (has-changes? diff)))))

        (it "returns true when there are deleted comments"
          (fn []
            (let [diff {:created [] :deleted [1] :edited [] :unchanged []}
                  has-changes? (. comments-sync "has-changes?")]
              (assert.is_true (has-changes? diff)))))

        (it "returns false when only edits (no creates or deletes)"
          (fn []
            (let [diff {:created [] :deleted [] :edited [{:id 1}] :unchanged []}
                  has-changes? (. comments-sync "has-changes?")]
              ;; Edits alone don't count as API changes (since Shortcut doesn't support edit)
              (assert.is_false (has-changes? diff)))))

        (it "returns false when no changes"
          (fn []
            (let [diff {:created [] :deleted [] :edited [] :unchanged [{:id 1}]}
                  has-changes? (. comments-sync "has-changes?")]
              (assert.is_false (has-changes? diff)))))))

    (describe "merge"
      (fn []
        (it "keeps new local comments"
          (fn []
            (let [local-comments [{:text "Local new" :is_new true}]
                  remote-comments []
                  previous-comments []
                  result (comments-sync.merge local-comments remote-comments previous-comments)]
              (assert.equals 1 (length result.comments))
              (assert.equals "Local new" (. result.comments 1 :text)))))

        (it "adds new remote comments"
          (fn []
            (let [local-comments []
                  remote-comments [{:id 1 :author "Bob" :timestamp "2026-01-10" :text "Remote new"}]
                  previous-comments []
                  result (comments-sync.merge local-comments remote-comments previous-comments)]
              (assert.equals 1 (length result.remote_added))
              (assert.equals 1 (. result.remote_added 1 :id)))))

        (it "detects conflicts when both changed"
          (fn []
            (let [local-comments [{:id 1 :text "Local version" :is_new false}]
                  remote-comments [{:id 1 :text "Remote version" :is_new false}]
                  previous-comments [{:id 1 :text "Original" :is_new false}]
                  result (comments-sync.merge local-comments remote-comments previous-comments)]
              ;; Both local and remote changed from previous - conflict
              (assert.equals 1 (length result.conflicts)))))

        (it "detects remote deletions"
          (fn []
            (let [local-comments [{:id 1 :text "Comment" :is_new false}]
                  remote-comments []
                  previous-comments [{:id 1 :text "Comment" :is_new false}]
                  result (comments-sync.merge local-comments remote-comments previous-comments)]
              ;; Comment was in previous sync but removed from remote
              (assert.equals 1 (length result.remote_deleted)))))

        (it "keeps locally changed comment when remote unchanged"
          (fn []
            (let [local-comments [{:id 1 :text "Updated locally" :is_new false}]
                  remote-comments [{:id 1 :text "Original" :is_new false}]
                  previous-comments [{:id 1 :text "Original" :is_new false}]
                  result (comments-sync.merge local-comments remote-comments previous-comments)]
              ;; Only local changed - no conflict, local wins
              (assert.equals 0 (length result.conflicts))
              (assert.equals 1 (length result.comments))
              (assert.equals "Updated locally" (. result.comments 1 :text)))))

        (it "handles empty merge"
          (fn []
            (let [result (comments-sync.merge [] [] [])]
              (assert.equals 0 (length result.comments))
              (assert.equals 0 (length result.conflicts)))))))

    (describe "integration: parse-diff round-trip"
      (fn []
        (it "parses markdown, diffs with remote, detects changes"
          (fn []
            (let [;; Simulate local markdown with one existing and one new comment
                  local-content "---\n**Alice** · 2026-01-10 10:00 <!-- comment:101 -->\n\nExisting comment.\n\n---\n**Me** · 2026-01-20 15:00 <!-- comment:new -->\n\nNew from user."
                  local-comments (comments-md.parse-section local-content)
                  ;; Simulate remote comments from API
                  remote-comments [{:id 101 :text "Existing comment." :is_new false}
                                   {:id 102 :text "Another remote comment" :is_new false}]
                  diff (comments-sync.diff local-comments remote-comments)]
              ;; new comment from user
              (assert.equals 1 (length diff.created))
              ;; comment 102 removed from local (deleted)
              (assert.equals 1 (length diff.deleted))
              (assert.equals 102 (. diff.deleted 1)))))

        (it "computes stable hash for comments before and after round-trip"
          (fn []
            (let [comments [{:id 1 :text "Comment A"}
                            {:id 2 :text "Comment B"}]
                  hash1 (hash.comments-hash comments)
                  hash2 (hash.comments-hash comments)]
              ;; Same input produces same hash
              (assert.equals hash1 hash2)
              ;; Changing a comment changes the hash
              (let [modified [{:id 1 :text "Changed A"}
                              {:id 2 :text "Comment B"}]
                    hash3 (hash.comments-hash modified)]
                (assert.is_not.equals hash1 hash3)))))))))
