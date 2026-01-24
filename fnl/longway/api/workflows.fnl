;; Workflows API module for longway.nvim
;; Handles workflow states (e.g., "In Progress", "Done", etc.)

(local client (require :longway.api.client))
(local cache (require :longway.cache.store))

(local M {})

(fn M.list []
  "List all workflows in the workspace
   Returns: {:ok bool :data [workflows] :error string}"
  (client.get "/workflows"))

(fn M.list-cached []
  "Get workflows from cache or fetch if needed
   Returns: {:ok bool :data [workflows] :error string :from-cache bool}"
  (cache.get-or-fetch :workflows M.list))

(fn M.refresh-cache []
  "Force refresh the workflows cache
   Returns: {:ok bool :data [workflows] :error string}"
  (cache.refresh :workflows M.list))

(fn M.get-states [workflow]
  "Get all states from a workflow
   Returns: [states]"
  (or workflow.states []))

(fn M.get-all-states []
  "Get all workflow states across all workflows (cached)
   Returns: {:ok bool :data [states] :error string}"
  (let [result (M.list-cached)]
    (if (not result.ok)
        result
        (let [all-states []]
          (each [_ workflow (ipairs result.data)]
            (each [_ state (ipairs (M.get-states workflow))]
              (table.insert all-states state)))
          {:ok true :data all-states}))))

(fn M.find-state-by-name [name workflows]
  "Find a workflow state by name (case-insensitive partial match)
   workflows: list of workflows (if nil, uses cached)
   Returns: state or nil"
  (let [workflows (or workflows (let [result (M.list-cached)]
                                  (when result.ok result.data)))
        lower-name (string.lower name)]
    (when workflows
      (var found nil)
      (each [_ workflow (ipairs workflows) &until found]
        (each [_ state (ipairs (M.get-states workflow)) &until found]
          (let [lower-state (string.lower (or state.name ""))]
            (when (string.find lower-state lower-name 1 true)
              (set found state)))))
      found)))

(fn M.find-state-by-id [id workflows]
  "Find a workflow state by ID
   workflows: list of workflows (if nil, uses cached)
   Returns: state or nil"
  (let [workflows (or workflows (let [result (M.list-cached)]
                                  (when result.ok result.data)))]
    (when workflows
      (var found nil)
      (each [_ workflow (ipairs workflows) &until found]
        (each [_ state (ipairs (M.get-states workflow)) &until found]
          (when (= state.id id)
            (set found state))))
      found)))

(fn M.get-state-type [state]
  "Get the type of a state (unstarted, started, done)
   Returns: string"
  (or state.type "unstarted"))

(fn M.is-done-state [state]
  "Check if a state is a 'done' type
   Returns: bool"
  (= (M.get-state-type state) "done"))

(fn M.is-started-state [state]
  "Check if a state is a 'started' type
   Returns: bool"
  (= (M.get-state-type state) "started"))

(fn M.resolve-state-name [state-id]
  "Resolve a state ID to name using cache
   Returns: string"
  (let [state (M.find-state-by-id state-id)]
    (if state
        state.name
        state-id)))

M
