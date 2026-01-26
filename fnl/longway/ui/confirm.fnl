;; Confirmation UI for longway.nvim
;; Provides confirmation dialogs for destructive operations

(local M {})

(fn M.confirm [message callback]
  "Show a confirmation prompt
   message: The confirmation message to display
   callback: Function called with true/false based on user response"
  (vim.ui.select
    ["Yes" "No"]
    {:prompt message}
    (fn [choice]
      (callback (= choice "Yes")))))

(fn M.confirm-sync [message callback]
  "Show a synchronous confirmation prompt
   Wraps vim.fn.confirm. If callback is provided, calls it with the result.
   Always returns true/false directly."
  (let [result (vim.fn.confirm message "&Yes\n&No" 2)
        confirmed (= result 1)]
    (when callback
      (callback confirmed))
    confirmed))

(fn format-task-list [tasks]
  "Format a list of tasks for display"
  (let [lines []]
    (each [i task (ipairs tasks)]
      (when (<= i 5)  ;; Show max 5 tasks
        (let [desc (if (> (length (or task.description "")) 40)
                       (.. (string.sub task.description 1 37) "...")
                       (or task.description "(no description)"))]
          (table.insert lines (string.format "  • %s" desc)))))
    (when (> (length tasks) 5)
      (table.insert lines (string.format "  ... and %d more" (- (length tasks) 5))))
    (table.concat lines "\n")))

(fn M.confirm-delete-tasks [tasks callback]
  "Confirm deletion of tasks
   tasks: List of tasks to delete (with descriptions)
   callback: Function called with true/false"
  (let [count (length tasks)
        task-list (format-task-list tasks)
        message (string.format "Delete %d task(s)?\n\n%s\n\nThis cannot be undone."
                               count task-list)]
    (M.confirm message callback)))

(fn M.confirm-delete-task-ids [task-ids remote-tasks callback]
  "Confirm deletion of tasks by ID, looking up descriptions from remote
   task-ids: List of task IDs to delete
   remote-tasks: Remote task list for looking up descriptions
   callback: Function called with true/false"
  (let [tasks-to-delete []]
    ;; Find task descriptions
    (each [_ id (ipairs task-ids)]
      (var found nil)
      (each [_ task (ipairs (or remote-tasks [])) &until found]
        (when (= task.id id)
          (set found task)))
      (table.insert tasks-to-delete (or found {:id id :description (string.format "Task #%s" id)})))
    (M.confirm-delete-tasks tasks-to-delete callback)))

(fn M.confirm-overwrite [item-type direction callback]
  "Confirm overwriting local or remote content
   item-type: 'story', 'epic', 'tasks', etc.
   direction: 'local' or 'remote'
   callback: Function called with true/false"
  (let [message (if (= direction "local")
                    (string.format "Overwrite local %s with remote version?" item-type)
                    (string.format "Overwrite remote %s with local version?" item-type))]
    (M.confirm message callback)))

(fn M.prompt-delete-or-skip [tasks callback]
  "Prompt user to delete tasks or skip deletion
   tasks: List of tasks that would be deleted
   callback: Function called with 'delete', 'skip', or nil (cancelled)"
  (let [count (length tasks)
        task-list (format-task-list tasks)]
    (vim.ui.select
      ["Delete from Shortcut" "Keep in Shortcut (skip delete)" "Cancel"]
      {:prompt (string.format "%d task(s) removed locally:\n\n%s\n\nWhat should happen on Shortcut?"
                              count task-list)}
      (fn [choice]
        (if (= choice "Delete from Shortcut")
            (callback "delete")
            (= choice "Keep in Shortcut (skip delete)")
            (callback "skip")
            (callback nil))))))

(fn format-comment-list [comments]
  "Format a list of comments for display"
  (let [lines []]
    (each [i cmt (ipairs comments)]
      (when (<= i 5)  ;; Show max 5 comments
        (let [text (or cmt.text "")
              preview (if (> (length text) 40)
                         (.. (string.sub text 1 37) "...")
                         (if (= (length text) 0) "(empty comment)" text))
              author (or cmt.author "Unknown")]
          (table.insert lines (string.format "  • %s: %s" author preview)))))
    (when (> (length comments) 5)
      (table.insert lines (string.format "  ... and %d more" (- (length comments) 5))))
    (table.concat lines "\n")))

(fn M.confirm-delete-comments [comments callback]
  "Confirm deletion of comments
   comments: List of comments to delete (with text and author)
   callback: Function called with true/false"
  (let [count (length comments)
        comment-list (format-comment-list comments)
        message (string.format "Delete %d comment(s)?\n\n%s\n\nThis cannot be undone."
                               count comment-list)]
    (M.confirm message callback)))

(fn M.confirm-delete-comment-ids [comment-ids remote-comments callback]
  "Confirm deletion of comments by ID, looking up text from remote
   comment-ids: List of comment IDs to delete
   remote-comments: Remote comment list for looking up text
   callback: Function called with true/false"
  (let [comments-to-delete []]
    ;; Find comment text
    (each [_ id (ipairs comment-ids)]
      (var found nil)
      (each [_ cmt (ipairs (or remote-comments [])) &until found]
        (when (= cmt.id id)
          (set found cmt)))
      (table.insert comments-to-delete (or found {:id id :text (string.format "Comment #%s" id) :author "Unknown"})))
    (M.confirm-delete-comments comments-to-delete callback)))

M
