;; Epics API module for longway.nvim
;; Handles epic CRUD operations

(local client (require :longway.api.client))

(local M {})

(fn M.get [epic-id]
  "Get an epic by ID
   Returns: {:ok bool :data epic :error string}"
  (client.get (string.format "/epics/%s" (tostring epic-id))))

(fn M.list []
  "List all epics in the workspace
   Returns: {:ok bool :data [epics] :error string}"
  (client.get "/epics"))

(fn M.update [epic-id data]
  "Update an epic
   data: table with fields to update (e.g., {:description 'new desc' :name 'New Name'})
   Returns: {:ok bool :data epic :error string}"
  (client.put (string.format "/epics/%s" (tostring epic-id))
              {:body data}))

(fn M.create [data]
  "Create a new epic
   data: {:name string :description string ...}
   Returns: {:ok bool :data epic :error string}"
  (client.post "/epics" {:body data}))

(fn M.delete [epic-id]
  "Delete an epic
   Returns: {:ok bool :error string}"
  (client.delete (string.format "/epics/%s" (tostring epic-id))))

(fn M.list-stories [epic-id opts]
  "List all stories in an epic
   opts: {:includes_description bool}
   Returns: {:ok bool :data [stories] :error string}"
  (let [query-params (when (and opts opts.includes_description)
                       {:includes_description "true"})]
    (client.get (string.format "/epics/%s/stories" (tostring epic-id))
                (when query-params {:query query-params}))))

(fn M.get-with-stories [epic-id]
  "Get an epic along with its stories
   Returns: {:ok bool :data {:epic epic :stories [stories]} :error string}"
  (let [epic-result (M.get epic-id)]
    (if (not epic-result.ok)
        epic-result
        (let [stories-result (M.list-stories epic-id)]
          (if (not stories-result.ok)
              {:ok true :data {:epic epic-result.data :stories []}}
              {:ok true :data {:epic epic-result.data
                               :stories stories-result.data}})))))

(fn M.get-stats [epic]
  "Calculate statistics for an epic
   epic: epic data with stats field
   Returns: {:total number :started number :done number :unstarted number}"
  (let [stats (or epic.stats {})]
    {:total (or stats.num_stories 0)
     :started (or stats.num_stories_started 0)
     :done (or stats.num_stories_done 0)
     :unstarted (or stats.num_stories_unstarted 0)
     :points_total (or stats.num_points 0)
     :points_done (or stats.num_points_done 0)}))

(fn M.get-progress [epic]
  "Calculate progress percentage for an epic
   Returns: number (0-100)"
  (let [stats (M.get-stats epic)
        total stats.total]
    (if (> total 0)
        (math.floor (* (/ stats.done total) 100))
        0)))

M
