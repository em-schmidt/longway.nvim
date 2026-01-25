;; Iterations API module for longway.nvim
;; Handles iterations/sprints

(local client (require :longway.api.client))
(local cache (require :longway.cache.store))

(local M {})

(fn M.list []
  "List all iterations in the workspace
   Returns: {:ok bool :data [iterations] :error string}"
  (client.get "/iterations"))

(fn M.get [iteration-id]
  "Get a specific iteration by ID
   Returns: {:ok bool :data iteration :error string}"
  (client.get (string.format "/iterations/%s" iteration-id)))

(fn M.list-cached []
  "Get iterations from cache or fetch if needed
   Returns: {:ok bool :data [iterations] :error string :from-cache bool}"
  (cache.get-or-fetch :iterations M.list))

(fn M.refresh-cache []
  "Force refresh the iterations cache
   Returns: {:ok bool :data [iterations] :error string}"
  (cache.refresh :iterations M.list))

(fn M.find-by-name [name iterations]
  "Find an iteration by name (case-insensitive partial match)
   iterations: list of iterations (if nil, uses cached)
   Returns: iteration or nil"
  (let [iterations (or iterations (let [result (M.list-cached)]
                                    (when result.ok result.data)))
        lower-name (string.lower name)]
    (when iterations
      (var found nil)
      (each [_ iteration (ipairs iterations) &until found]
        (let [lower-iter-name (string.lower (or iteration.name ""))]
          (when (string.find lower-iter-name lower-name 1 true)
            (set found iteration))))
      found)))

(fn M.find-by-id [id iterations]
  "Find an iteration by ID
   iterations: list of iterations (if nil, uses cached)
   Returns: iteration or nil"
  (let [iterations (or iterations (let [result (M.list-cached)]
                                    (when result.ok result.data)))]
    (when iterations
      (var found nil)
      (each [_ iteration (ipairs iterations) &until found]
        (when (= iteration.id id)
          (set found iteration)))
      found)))

(fn M.get-current []
  "Get the current active iteration (based on dates)
   Returns: iteration or nil"
  (let [result (M.list-cached)
        now (os.time)]
    (when result.ok
      (var current nil)
      (each [_ iteration (ipairs result.data) &until current]
        (let [start-date iteration.start_date
              end-date iteration.end_date]
          ;; Check if current time is within iteration dates
          ;; Note: Shortcut uses date strings like "2024-01-15"
          (when (and start-date end-date
                     iteration.status
                     (= iteration.status "started"))
            (set current iteration))))
      current)))

(fn M.get-upcoming []
  "Get upcoming iterations (not yet started)
   Returns: [iterations]"
  (let [result (M.list-cached)
        upcoming []]
    (when result.ok
      (each [_ iteration (ipairs result.data)]
        (when (= iteration.status "unstarted")
          (table.insert upcoming iteration))))
    upcoming))

(fn M.resolve-name [iteration-id]
  "Resolve an iteration ID to name using cache
   Returns: string"
  (let [iteration (M.find-by-id iteration-id)]
    (if iteration
        iteration.name
        (tostring iteration-id))))

M
