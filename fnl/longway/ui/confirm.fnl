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
  "Show a confirmation prompt with sync-style messaging
   Wraps vim.fn.confirm for synchronous confirmation"
  (let [result (vim.fn.confirm message "Yes\nNo" 2)]
    (callback (= result 1))))

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

M
