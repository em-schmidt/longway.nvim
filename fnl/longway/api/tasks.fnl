;; Tasks API module for longway.nvim
;; Dedicated module for Shortcut task operations

(local client (require :longway.api.client))

(local M {})

(fn M.create [story-id task-data]
  "Create a task on a story
   story-id: The story ID to add the task to
   task-data: {:description string :complete bool :owner_ids [uuids]}
   Returns: {:ok bool :data task :error string}"
  (client.post (string.format "/stories/%s/tasks" (tostring story-id))
               {:body task-data}))

(fn M.update [story-id task-id data]
  "Update a task on a story
   story-id: The story ID
   task-id: The task ID to update
   data: {:complete bool :description string :owner_ids [uuids]}
   Returns: {:ok bool :data task :error string}"
  (client.put (string.format "/stories/%s/tasks/%s"
                             (tostring story-id)
                             (tostring task-id))
              {:body data}))

(fn M.delete [story-id task-id]
  "Delete a task from a story
   story-id: The story ID
   task-id: The task ID to delete
   Returns: {:ok bool :error string}"
  (client.delete (string.format "/stories/%s/tasks/%s"
                                (tostring story-id)
                                (tostring task-id))))

(fn M.get [story-id task-id]
  "Get a specific task from a story
   story-id: The story ID
   task-id: The task ID
   Returns: {:ok bool :data task :error string}"
  (client.get (string.format "/stories/%s/tasks/%s"
                             (tostring story-id)
                             (tostring task-id))))

(fn M.batch-create [story-id tasks]
  "Create multiple tasks on a story
   story-id: The story ID
   tasks: [{:description string :complete bool :owner_ids [uuids]}]
   Returns: {:ok bool :created [tasks] :errors [string]}"
  (let [created []
        errors []]
    (each [i task (ipairs tasks)]
      (let [result (M.create story-id task)]
        (if result.ok
            (table.insert created result.data)
            (table.insert errors (string.format "Task %d: %s" i (or result.error "unknown error"))))))
    {:ok (= (length errors) 0)
     :created created
     :errors errors}))

(fn M.batch-update [story-id updates]
  "Update multiple tasks on a story
   story-id: The story ID
   updates: [{:id number :data {:complete bool :description string}}]
   Returns: {:ok bool :updated [tasks] :errors [string]}"
  (let [updated []
        errors []]
    (each [_ update (ipairs updates)]
      (let [result (M.update story-id update.id update.data)]
        (if result.ok
            (table.insert updated result.data)
            (table.insert errors (string.format "Task %s: %s"
                                                (tostring update.id)
                                                (or result.error "unknown error"))))))
    {:ok (= (length errors) 0)
     :updated updated
     :errors errors}))

(fn M.batch-delete [story-id task-ids]
  "Delete multiple tasks from a story
   story-id: The story ID
   task-ids: [number] list of task IDs to delete
   Returns: {:ok bool :deleted [number] :errors [string]}"
  (let [deleted []
        errors []]
    (each [_ task-id (ipairs task-ids)]
      (let [result (M.delete story-id task-id)]
        (if result.ok
            (table.insert deleted task-id)
            (table.insert errors (string.format "Task %s: %s"
                                                (tostring task-id)
                                                (or result.error "unknown error"))))))
    {:ok (= (length errors) 0)
     :deleted deleted
     :errors errors}))

M
