;; Search API module for longway.nvim
;; Handles story and epic search with query parsing

(local client (require :longway.api.client))

(local M {})

;; Query field mappings from user-friendly names to API parameters
(local QUERY_FIELDS
  {:owner "owner_id"
   :owner_id "owner_id"
   :state "workflow_state_id"
   :state_id "workflow_state_id"
   :workflow_state "workflow_state_id"
   :iteration "iteration_id"
   :iteration_id "iteration_id"
   :sprint "iteration_id"
   :team "group_id"
   :team_id "group_id"
   :group "group_id"
   :group_id "group_id"
   :epic "epic_id"
   :epic_id "epic_id"
   :type "story_type"
   :story_type "story_type"
   :label "label_id"
   :label_id "label_id"
   :project "project_id"
   :project_id "project_id"
   :archived "archived"
   :completed "completed"
   :started "started"})

;; Special values that need resolution
(local SPECIAL_VALUES
  {:me :current-member
   :current :current-iteration
   :backlog :backlog-iteration})

(fn extract-next-token [next-value]
  "Extract the pagination token from a next cursor.
   Shortcut returns full URL paths like '/api/v3/search/stories?...&next=TOKEN'
   but the API expects just the token value.
   Returns: token string or nil"
  (when next-value
    ;; If it looks like a URL path, extract the next= parameter
    (if (string.find next-value "^/api/")
        (or (string.match next-value "[?&]next=([^&]+)") next-value)
        ;; Otherwise assume it's already just the token
        next-value)))

(fn parse-query-string [query-str]
  "Parse a query string like 'owner:me state:started' into a table
   Returns: table of field -> value pairs"
  (let [params {}]
    (when (and query-str (> (length query-str) 0))
      ;; Match key:value pairs
      (each [key value (string.gmatch query-str "(%w+):([^%s]+)")]
        (let [api-field (. QUERY_FIELDS key)]
          (if api-field
              (tset params api-field value)
              ;; Keep unknown fields as-is (might be valid API params)
              (tset params key value)))))
    params))

(fn M.search-stories [query opts]
  "Search for stories using Shortcut search API
   query: search query string (free-form text search)
   opts: {:page_size number :next string :params table}
         - params: additional API parameters
   Returns: {:ok bool :data {:data [stories] :next cursor :total number} :error string}"
  (let [search-params {:query (or query "")}
        opts (or opts {})]
    ;; Add pagination options
    (when opts.page_size
      (tset search-params :page_size opts.page_size))
    (when opts.next
      (tset search-params :next opts.next))
    ;; Add any additional params
    (when opts.params
      (each [k v (pairs opts.params)]
        (tset search-params k v)))
    (client.get "/search/stories" {:query search-params})))

(fn M.search-stories-all [query opts]
  "Search for stories and automatically paginate through all results
   WARNING: Can be slow for large result sets
   query: search query string
   opts: {:max_results number :params table}
   Returns: {:ok bool :data [stories] :error string}"
  (let [opts (or opts {})
        max-results (or opts.max_results 500)
        all-stories []
        page-size 25]
    (var cursor nil)
    (var done false)
    (var error nil)

    (while (and (not done) (not error) (< (length all-stories) max-results))
      (let [result (M.search-stories query {:page_size page-size
                                            :next cursor
                                            :params opts.params})]
        (if (not result.ok)
            (set error result.error)
            (let [data result.data
                  stories (or data.data [])]
              ;; Add stories to collection
              (each [_ story (ipairs stories)]
                (when (< (length all-stories) max-results)
                  (table.insert all-stories story)))
              ;; Check for more pages
              (if (and data.next (> (length stories) 0))
                  (set cursor (extract-next-token data.next))
                  (set done true))))))

    (if error
        {:ok false :error error}
        {:ok true :data all-stories})))

(fn M.search-epics [query opts]
  "Search for epics using Shortcut search API
   query: search query string
   opts: {:page_size number :next string}
   Returns: {:ok bool :data {:data [epics] :next cursor} :error string}"
  (let [search-params {:query (or query "")}
        opts (or opts {})]
    (when opts.page_size
      (tset search-params :page_size opts.page_size))
    (when opts.next
      (tset search-params :next opts.next))
    (client.get "/search/epics" {:query search-params})))

(fn M.build-query [filters]
  "Build a Shortcut search query string from a filters table
   filters: {:owner 'name' :state 'In Progress' :type 'feature' ...}
   Returns: string"
  (let [parts []]
    (each [field value (pairs filters)]
      (when (and value (not= value ""))
        ;; Handle special boolean fields
        (if (or (= field :archived) (= field :completed) (= field :started))
            (when value
              (table.insert parts (.. field ":" (if value "true" "false"))))
            ;; Handle fields with spaces by quoting
            (if (string.find value " ")
                (table.insert parts (.. field ":\"" value "\""))
                (table.insert parts (.. field ":" value))))))
    (table.concat parts " ")))

(fn M.parse-query [query-str]
  "Parse a query string into structured parameters
   Returns: {:query string :params table}"
  (let [params (parse-query-string query-str)
        ;; Extract remaining text that isn't a key:value pair
        remaining-text (string.gsub query-str "%w+:[^%s]+" "")
        trimmed-text (string.gsub (string.gsub remaining-text "^%s+" "") "%s+$" "")]
    {:query trimmed-text
     :params params}))

M
