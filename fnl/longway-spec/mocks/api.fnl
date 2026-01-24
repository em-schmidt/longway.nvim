;; Mock for Shortcut API responses
;; Provides pre-configured API response data for testing

(local M {})

;; State
(var stories {})
(var epics {})
(var call-log [])

(fn M.reset []
  "Reset mock state"
  (set stories {})
  (set epics {})
  (set call-log []))

(fn M.setup-story [story]
  "Add a story to the mock"
  (tset stories story.id story))

(fn M.setup-epic [epic]
  "Add an epic to the mock"
  (tset epics epic.id epic))

(fn M.get-story [id]
  "Get a story by ID"
  (table.insert call-log {:method "get-story" :id id})
  (. stories id))

(fn M.get-epic [id]
  "Get an epic by ID"
  (table.insert call-log {:method "get-epic" :id id})
  (. epics id))

(fn M.search-stories [query]
  "Search stories"
  (table.insert call-log {:method "search-stories" :query query})
  (let [results []]
    (each [_ story (pairs stories)]
      (table.insert results story))
    results))

(fn M.list-stories []
  "List all stories"
  (table.insert call-log {:method "list-stories"})
  (let [results []]
    (each [_ story (pairs stories)]
      (table.insert results story))
    results))

(fn M.last-call []
  "Get the most recent API call"
  (. call-log (length call-log)))

(fn M.call-count []
  "Get total number of API calls"
  (length call-log))

(fn M.get-calls []
  "Get all recorded API calls"
  call-log)

;; Sample data generators
(fn M.make-story-response [id name]
  "Create a realistic story API response"
  {:id id
   :name name
   :description ""
   :story_type "feature"
   :workflow_state_id 500000001
   :workflow_state_name "Unstarted"
   :app_url (.. "https://app.shortcut.com/test/story/" id)
   :created_at "2026-01-01T00:00:00Z"
   :updated_at "2026-01-15T12:00:00Z"
   :tasks []
   :comments []
   :owners []
   :labels []
   :epic_id nil
   :iteration_id nil
   :group_id nil
   :estimate nil})

(fn M.make-epic-response [id name]
  "Create a realistic epic API response"
  {:id id
   :name name
   :description ""
   :state "to do"
   :app_url (.. "https://app.shortcut.com/test/epic/" id)
   :created_at "2026-01-01T00:00:00Z"
   :updated_at "2026-01-15T12:00:00Z"
   :planned_start_date nil
   :deadline nil
   :stats {:num_stories_total 0
           :num_stories_done 0}})

M
