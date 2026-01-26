;; Task synchronization logic for longway.nvim
;; Handles diffing and syncing tasks between local markdown and Shortcut

(local tasks-api (require :longway.api.tasks))
(local tasks-md (require :longway.markdown.tasks))
(local config (require :longway.config))
(local notify (require :longway.ui.notify))

(local M {})

;;; ============================================================================
;;; Task Diffing
;;; ============================================================================

(fn build-remote-task-map [remote-tasks]
  "Build a map of task ID -> task for quick lookup
   Returns: {id: task, ...}"
  (let [task-map {}]
    (each [_ task (ipairs (or remote-tasks []))]
      (when task.id
        (tset task-map task.id task)))
    task-map))

(fn M.diff [local-tasks remote-tasks]
  "Compute the diff between local and remote tasks
   Returns: {:created [tasks] :updated [tasks] :deleted [task-ids] :unchanged [tasks]}"
  (let [remote-map (build-remote-task-map remote-tasks)
        seen-ids {}
        created []
        updated []
        deleted []
        unchanged []]

    ;; Process local tasks
    (each [_ local-task (ipairs (or local-tasks []))]
      (if local-task.is_new
          ;; New task (no ID or marked as new)
          (table.insert created local-task)
          ;; Existing task - check for changes
          (when local-task.id
            (tset seen-ids local-task.id true)
            (let [remote-task (. remote-map local-task.id)]
              (if (not remote-task)
                  ;; Task was deleted remotely - treat as new since it's still local
                  (do
                    (set local-task.is_new true)
                    (set local-task.id nil)
                    (table.insert created local-task))
                  ;; Check if changed
                  (if (tasks-md.task-changed? local-task remote-task)
                      (table.insert updated local-task)
                      (table.insert unchanged local-task)))))))

    ;; Find deleted tasks (in remote but not in local)
    (each [_ remote-task (ipairs (or remote-tasks []))]
      (when (and remote-task.id (not (. seen-ids remote-task.id)))
        (table.insert deleted remote-task.id)))

    {:created created
     :updated updated
     :deleted deleted
     :unchanged unchanged}))

(fn M.has-changes? [diff]
  "Check if a diff contains any changes
   Returns: bool"
  (or (> (length diff.created) 0)
      (> (length diff.updated) 0)
      (> (length diff.deleted) 0)))

;;; ============================================================================
;;; Push Operations
;;; ============================================================================

(fn push-created-tasks [story-id tasks]
  "Create new tasks via API
   Returns: {:ok bool :tasks [tasks with IDs] :errors [string]}"
  (let [result-tasks []
        errors []]
    (each [_ task (ipairs tasks)]
      ;; Resolve owner mention to ID if needed
      (tasks-md.resolve-task-owners task)

      (let [task-data {:description task.description
                       :complete task.complete}]
        ;; Add owner_ids if present
        (when (and task.owner_ids (> (length task.owner_ids) 0))
          (set task-data.owner_ids task.owner_ids))

        (let [result (tasks-api.create story-id task-data)]
          (if result.ok
              ;; Update local task with assigned ID
              (do
                (set task.id result.data.id)
                (set task.is_new false)
                (table.insert result-tasks task))
              (table.insert errors (string.format "Create '%s': %s"
                                                  task.description
                                                  (or result.error "unknown error")))))))
    {:ok (= (length errors) 0)
     :tasks result-tasks
     :errors errors}))

(fn push-updated-tasks [story-id tasks]
  "Update modified tasks via API
   Returns: {:ok bool :tasks [tasks] :errors [string]}"
  (let [result-tasks []
        errors []]
    (each [_ task (ipairs tasks)]
      (let [task-data {:description task.description
                       :complete task.complete}]
        (let [result (tasks-api.update story-id task.id task-data)]
          (if result.ok
              (table.insert result-tasks task)
              (table.insert errors (string.format "Update task %s: %s"
                                                  (tostring task.id)
                                                  (or result.error "unknown error")))))))
    {:ok (= (length errors) 0)
     :tasks result-tasks
     :errors errors}))

(fn push-deleted-tasks [story-id task-ids]
  "Delete tasks via API
   Returns: {:ok bool :deleted [ids] :errors [string]}"
  (let [deleted []
        errors []]
    (each [_ task-id (ipairs task-ids)]
      (let [result (tasks-api.delete story-id task-id)]
        (if result.ok
            (table.insert deleted task-id)
            (table.insert errors (string.format "Delete task %s: %s"
                                                (tostring task-id)
                                                (or result.error "unknown error"))))))
    {:ok (= (length errors) 0)
     :deleted deleted
     :errors errors}))

(fn M.push [story-id local-tasks remote-tasks opts]
  "Push local task changes to Shortcut
   story-id: The story ID
   local-tasks: Tasks parsed from local markdown
   remote-tasks: Tasks from Shortcut API
   opts: {:confirm_delete bool :skip_delete bool}
   Returns: {:ok bool :created n :updated n :deleted n :errors [] :tasks [updated task list]}"
  (let [opts (or opts {})
        diff (M.diff local-tasks remote-tasks)
        all-errors []
        result-tasks []]

    ;; If no changes, return early
    (when (not (M.has-changes? diff))
      (lua "return {ok = true, created = 0, updated = 0, deleted = 0, errors = {}, tasks = local_tasks}"))

    ;; Create new tasks
    (when (> (length diff.created) 0)
      (notify.info (string.format "Creating %d new task(s)..." (length diff.created)))
      (let [create-result (push-created-tasks story-id diff.created)]
        (each [_ task (ipairs create-result.tasks)]
          (table.insert result-tasks task))
        (each [_ err (ipairs create-result.errors)]
          (table.insert all-errors err))))

    ;; Update modified tasks
    (when (> (length diff.updated) 0)
      (notify.info (string.format "Updating %d task(s)..." (length diff.updated)))
      (let [update-result (push-updated-tasks story-id diff.updated)]
        (each [_ task (ipairs update-result.tasks)]
          (table.insert result-tasks task))
        (each [_ err (ipairs update-result.errors)]
          (table.insert all-errors err))))

    ;; Handle unchanged tasks
    (each [_ task (ipairs diff.unchanged)]
      (table.insert result-tasks task))

    ;; Delete removed tasks (if not skipped)
    (var deleted-count 0)
    (when (and (> (length diff.deleted) 0) (not opts.skip_delete))
      (notify.info (string.format "Deleting %d task(s)..." (length diff.deleted)))
      (let [delete-result (push-deleted-tasks story-id diff.deleted)]
        (set deleted-count (length delete-result.deleted))
        (each [_ err (ipairs delete-result.errors)]
          (table.insert all-errors err))))

    ;; Report results
    (let [created-count (length diff.created)
          updated-count (length diff.updated)]
      (if (= (length all-errors) 0)
          (notify.info (string.format "Tasks synced: %d created, %d updated, %d deleted"
                                      created-count updated-count deleted-count))
          (notify.warn (string.format "Task sync completed with %d error(s)" (length all-errors))))

      {:ok (= (length all-errors) 0)
       :created created-count
       :updated updated-count
       :deleted deleted-count
       :errors all-errors
       :tasks result-tasks})))

;;; ============================================================================
;;; Pull Operations
;;; ============================================================================

(fn M.pull [story]
  "Extract and format tasks from a story response
   story: Story data from API (includes .tasks array)
   Returns: {:ok bool :tasks [formatted tasks]}"
  (let [raw-tasks (or story.tasks [])
        formatted []]
    (each [i task (ipairs raw-tasks)]
      ;; Build formatted task with resolved owner names
      (let [owner-mention (when (and task.owner_ids (> (length task.owner_ids) 0))
                            (let [owner-name (tasks-md.resolve-owner-id (. task.owner_ids 1))]
                              (when owner-name
                                (string.gsub owner-name " " "_"))))]
        (table.insert formatted
                      {:id task.id
                       :description task.description
                       :complete task.complete
                       :is_new false
                       :owner_ids (or task.owner_ids [])
                       :owner_mention owner-mention
                       :position (or task.position i)})))
    {:ok true :tasks formatted}))

;;; ============================================================================
;;; Merge Operations (for bidirectional sync with conflict detection)
;;; ============================================================================

(fn M.merge [local-tasks remote-tasks previous-tasks]
  "Merge local and remote tasks, detecting conflicts
   local-tasks: Current local tasks
   remote-tasks: Current remote tasks
   previous-tasks: Tasks from last sync (for conflict detection)
   Returns: {:tasks [merged] :conflicts [task-id] :remote_added [tasks] :remote_deleted [ids]}"
  (let [prev-map (build-remote-task-map previous-tasks)
        remote-map (build-remote-task-map remote-tasks)
        local-map (build-remote-task-map local-tasks)
        merged []
        conflicts []
        remote-added []
        remote-deleted []]

    ;; Start with local tasks
    (each [_ task (ipairs local-tasks)]
      (if task.is_new
          ;; New local task - keep it
          (table.insert merged task)
          ;; Existing task - check for conflicts
          (when task.id
            (let [remote (. remote-map task.id)
                  prev (. prev-map task.id)]
              (if (not remote)
                  ;; Deleted remotely
                  (if prev
                      ;; Was in previous sync, now gone - remote deleted
                      (table.insert remote-deleted task.id)
                      ;; Never synced, keep local
                      (table.insert merged task))
                  ;; Check for conflict (both changed since last sync)
                  (let [local-changed (and prev (tasks-md.task-changed? task prev))
                        remote-changed (and prev (tasks-md.task-changed? remote prev))]
                    (if (and local-changed remote-changed)
                        ;; Conflict - keep local but flag it
                        (do
                          (table.insert conflicts task.id)
                          (table.insert merged task))
                        ;; No conflict - keep appropriate version
                        (table.insert merged task))))))))

    ;; Add tasks that exist remotely but not locally (new remote tasks)
    (each [_ remote-task (ipairs remote-tasks)]
      (when (not (. local-map remote-task.id))
        ;; Check if it was previously synced
        (if (. prev-map remote-task.id)
            ;; Was synced before, now missing locally - local deletion
            nil
            ;; New remote task - add it
            (do
              (table.insert remote-added remote-task)
              (table.insert merged {:id remote-task.id
                                    :description remote-task.description
                                    :complete remote-task.complete
                                    :is_new false
                                    :owner_ids (or remote-task.owner_ids [])
                                    :position remote-task.position})))))

    {:tasks merged
     :conflicts conflicts
     :remote_added remote-added
     :remote_deleted remote-deleted}))

M
