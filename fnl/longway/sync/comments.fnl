;; Comment synchronization logic for longway.nvim
;; Handles diffing and syncing comments between local markdown and Shortcut

(local comments-api (require :longway.api.comments))
(local comments-md (require :longway.markdown.comments))
(local config (require :longway.config))
(local notify (require :longway.ui.notify))

(local M {})

;;; ============================================================================
;;; Comment Diffing
;;; ============================================================================

(fn build-remote-comment-map [remote-comments]
  "Build a map of comment ID -> comment for quick lookup
   Returns: {id: comment, ...}"
  (let [comment-map {}]
    (each [_ cmt (ipairs (or remote-comments []))]
      (when cmt.id
        (tset comment-map cmt.id cmt)))
    comment-map))

(fn M.diff [local-comments remote-comments]
  "Compute the diff between local and remote comments
   Returns: {:created [comments] :deleted [comment-ids] :edited [comments] :unchanged [comments]}
   Note: 'edited' comments generate warnings — Shortcut API does not support editing."
  (let [remote-map (build-remote-comment-map remote-comments)
        seen-ids {}
        created []
        deleted []
        edited []
        unchanged []]

    ;; Process local comments
    (each [_ local-cmt (ipairs (or local-comments []))]
      (if local-cmt.is_new
          ;; New comment (no ID or marked as new)
          (table.insert created local-cmt)
          ;; Existing comment - check for changes
          (when local-cmt.id
            (tset seen-ids local-cmt.id true)
            (let [remote-cmt (. remote-map local-cmt.id)]
              (if (not remote-cmt)
                  ;; Comment was deleted remotely - treat as new
                  (do
                    (set local-cmt.is_new true)
                    (set local-cmt.id nil)
                    (table.insert created local-cmt))
                  ;; Check if text was edited locally
                  (if (comments-md.comment-changed? local-cmt remote-cmt)
                      (table.insert edited local-cmt)
                      (table.insert unchanged local-cmt)))))))

    ;; Find deleted comments (in remote but not in local)
    (each [_ remote-cmt (ipairs (or remote-comments []))]
      (when (and remote-cmt.id (not (. seen-ids remote-cmt.id)))
        (table.insert deleted remote-cmt.id)))

    {:created created
     :deleted deleted
     :edited edited
     :unchanged unchanged}))

(fn M.has-changes? [diff]
  "Check if a diff contains any changes
   Returns: bool"
  (or (> (length diff.created) 0)
      (> (length diff.deleted) 0)))

;;; ============================================================================
;;; Push Operations
;;; ============================================================================

(fn push-created-comments [story-id comments]
  "Create new comments via API
   Returns: {:ok bool :comments [comments with IDs] :errors [string]}"
  (let [result-comments []
        errors []]
    (each [_ cmt (ipairs comments)]
      (let [result (comments-api.create story-id {:text cmt.text})]
        (if result.ok
            ;; Update local comment with assigned ID
            (do
              (set cmt.id result.data.id)
              (set cmt.is_new false)
              ;; Update author/timestamp from server response
              (when result.data.created_at
                (set cmt.timestamp (comments-md.format-timestamp result.data.created_at)))
              (table.insert result-comments cmt))
            (table.insert errors (string.format "Create comment: %s"
                                                (or result.error "unknown error"))))))
    {:ok (= (length errors) 0)
     :comments result-comments
     :errors errors}))

(fn push-deleted-comments [story-id comment-ids]
  "Delete comments via API
   Returns: {:ok bool :deleted [ids] :errors [string]}"
  (let [deleted []
        errors []]
    (each [_ comment-id (ipairs comment-ids)]
      (let [result (comments-api.delete story-id comment-id)]
        (if result.ok
            (table.insert deleted comment-id)
            (table.insert errors (string.format "Delete comment %s: %s"
                                                (tostring comment-id)
                                                (or result.error "unknown error"))))))
    {:ok (= (length errors) 0)
     :deleted deleted
     :errors errors}))

(fn M.push [story-id local-comments remote-comments opts]
  "Push local comment changes to Shortcut
   story-id: The story ID
   local-comments: Comments parsed from local markdown
   remote-comments: Comments from Shortcut API
   opts: {:confirm_delete bool :skip_delete bool}
   Returns: {:ok bool :created n :deleted n :warned n :errors [] :comments [updated comment list]}"
  (let [opts (or opts {})
        diff (M.diff local-comments remote-comments)
        all-errors []
        result-comments []]

    ;; If no changes (ignoring edits), return early
    (when (not (M.has-changes? diff))
      ;; Still warn about edits
      (when (> (length diff.edited) 0)
        (notify.warn (string.format "%d comment(s) edited locally. Shortcut does not support comment editing — changes will not sync."
                                    (length diff.edited))))
      (lua "return {ok = true, created = 0, deleted = 0, warned = #diff.edited, errors = {}, comments = local_comments}"))

    ;; Create new comments
    (when (> (length diff.created) 0)
      (notify.info (string.format "Creating %d new comment(s)..." (length diff.created)))
      (let [create-result (push-created-comments story-id diff.created)]
        (each [_ cmt (ipairs create-result.comments)]
          (table.insert result-comments cmt))
        (each [_ err (ipairs create-result.errors)]
          (table.insert all-errors err))))

    ;; Handle unchanged comments
    (each [_ cmt (ipairs diff.unchanged)]
      (table.insert result-comments cmt))

    ;; Handle edited comments (keep local version but warn)
    (when (> (length diff.edited) 0)
      (notify.warn (string.format "%d comment(s) edited locally. Shortcut does not support comment editing — changes will not sync."
                                  (length diff.edited)))
      (each [_ cmt (ipairs diff.edited)]
        (table.insert result-comments cmt)))

    ;; Delete removed comments (if not skipped)
    (var deleted-count 0)
    (when (and (> (length diff.deleted) 0) (not opts.skip_delete))
      (notify.info (string.format "Deleting %d comment(s)..." (length diff.deleted)))
      (let [delete-result (push-deleted-comments story-id diff.deleted)]
        (set deleted-count (length delete-result.deleted))
        (each [_ err (ipairs delete-result.errors)]
          (table.insert all-errors err))))

    ;; Report results
    (let [created-count (length diff.created)
          warned-count (length diff.edited)]
      (if (= (length all-errors) 0)
          (notify.info (string.format "Comments synced: %d created, %d deleted"
                                      created-count deleted-count))
          (notify.warn (string.format "Comment sync completed with %d error(s)" (length all-errors))))

      {:ok (= (length all-errors) 0)
       :created created-count
       :deleted deleted-count
       :warned warned-count
       :errors all-errors
       :comments result-comments})))

;;; ============================================================================
;;; Pull Operations
;;; ============================================================================

(fn M.pull [story-id]
  "Fetch and format comments from Shortcut API
   story-id: The story ID
   Returns: {:ok bool :comments [formatted comments] :error string}"
  (let [cfg (config.get)
        result (comments-api.list story-id)]
    (if (not result.ok)
        {:ok false :error result.error :comments []}
        (let [raw-comments (or result.data [])
              ;; Respect max_pull limit
              limited (if (and cfg.comments.max_pull
                              (> (length raw-comments) cfg.comments.max_pull))
                         (do
                           (let [trimmed []]
                             (for [i 1 cfg.comments.max_pull]
                               (table.insert trimmed (. raw-comments i)))
                             trimmed))
                         raw-comments)
              formatted (comments-md.format-api-comments limited)]
          {:ok true :comments formatted}))))

;;; ============================================================================
;;; Merge Operations (for bidirectional sync with conflict detection)
;;; ============================================================================

(fn M.merge [local-comments remote-comments previous-comments]
  "Merge local and remote comments, detecting conflicts
   local-comments: Current local comments
   remote-comments: Current remote comments
   previous-comments: Comments from last sync (for conflict detection)
   Returns: {:comments [merged] :conflicts [comment-ids] :remote_added [comments] :remote_deleted [ids]}"
  (let [prev-map (build-remote-comment-map previous-comments)
        remote-map (build-remote-comment-map remote-comments)
        local-map (build-remote-comment-map local-comments)
        merged []
        conflicts []
        remote-added []
        remote-deleted []]

    ;; Start with local comments
    (each [_ cmt (ipairs local-comments)]
      (if cmt.is_new
          ;; New local comment - keep it
          (table.insert merged cmt)
          ;; Existing comment - check for conflicts
          (when cmt.id
            (let [remote (. remote-map cmt.id)
                  prev (. prev-map cmt.id)]
              (if (not remote)
                  ;; Deleted remotely
                  (if prev
                      ;; Was in previous sync, now gone - remote deleted
                      (table.insert remote-deleted cmt.id)
                      ;; Never synced, keep local
                      (table.insert merged cmt))
                  ;; Check for conflict (both changed since last sync)
                  (let [local-changed (and prev (comments-md.comment-changed? cmt prev))
                        remote-changed (and prev (comments-md.comment-changed? remote prev))]
                    (if (and local-changed remote-changed)
                        ;; Conflict - keep local but flag it
                        (do
                          (table.insert conflicts cmt.id)
                          (table.insert merged cmt))
                        ;; No conflict - keep appropriate version
                        (table.insert merged cmt))))))))

    ;; Add comments that exist remotely but not locally (new remote comments)
    (each [_ remote-cmt (ipairs remote-comments)]
      (when (not (. local-map remote-cmt.id))
        ;; Check if it was previously synced
        (if (. prev-map remote-cmt.id)
            ;; Was synced before, now missing locally - local deletion
            nil
            ;; New remote comment - add it
            (do
              (table.insert remote-added remote-cmt)
              (table.insert merged {:id remote-cmt.id
                                    :author remote-cmt.author
                                    :timestamp remote-cmt.timestamp
                                    :text (or remote-cmt.text "")
                                    :is_new false})))))

    {:comments merged
     :conflicts conflicts
     :remote_added remote-added
     :remote_deleted remote-deleted}))

M
