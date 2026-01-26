;; Stories API module for longway.nvim

(local client (require :longway.api.client))

(local M {})

(fn M.get [story-id]
  "Get a story by ID
   Returns: {:ok bool :data story-data :error string}"
  (client.get (string.format "/stories/%s" (tostring story-id))))

(fn M.update [story-id data]
  "Update a story
   data: table with fields to update (e.g., {:description 'new desc'})
   Returns: {:ok bool :data story-data :error string}"
  (client.put (string.format "/stories/%s" (tostring story-id))
              {:body data}))

(fn M.search [query opts]
  "Search for stories
   query: search query string
   opts: {:page_size number :next string}
   Returns: {:ok bool :data {:data [stories] :next cursor} :error string}"
  (let [params {:query query}]
    (when opts
      (when opts.page_size
        (set params.page_size opts.page_size))
      (when opts.next
        (set params.next opts.next)))
    (client.get "/search/stories" {:query params})))

(fn M.list-for-epic [epic-id]
  "List all stories in an epic
   Returns: {:ok bool :data [stories] :error string}"
  (client.get (string.format "/epics/%s/stories" (tostring epic-id))))

;; Comment-related functions (for Phase 4, but included here for completeness)

(fn M.list-comments [story-id]
  "List comments on a story
   Returns: {:ok bool :data [comments] :error string}"
  (client.get (string.format "/stories/%s/comments" (tostring story-id))))

(fn M.create-comment [story-id text]
  "Create a comment on a story
   Returns: {:ok bool :data comment :error string}"
  (client.post (string.format "/stories/%s/comments" (tostring story-id))
               {:body {:text text}}))

(fn M.delete-comment [story-id comment-id]
  "Delete a comment from a story
   Returns: {:ok bool :error string}"
  (client.delete (string.format "/stories/%s/comments/%s" (tostring story-id) (tostring comment-id))))

M
