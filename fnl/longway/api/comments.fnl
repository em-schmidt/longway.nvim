;; Comments API module for longway.nvim
;; Dedicated module for Shortcut comment operations

(local client (require :longway.api.client))

(local M {})

(fn M.list [story-id]
  "List all comments on a story
   story-id: The story ID
   Returns: {:ok bool :data [comments] :error string}"
  (client.get (string.format "/stories/%s/comments" (tostring story-id))))

(fn M.get [story-id comment-id]
  "Get a specific comment on a story
   story-id: The story ID
   comment-id: The comment ID
   Returns: {:ok bool :data comment :error string}"
  (client.get (string.format "/stories/%s/comments/%s"
                             (tostring story-id)
                             (tostring comment-id))))

(fn M.create [story-id data]
  "Create a comment on a story
   story-id: The story ID
   data: {:text string}
   Returns: {:ok bool :data comment :error string}"
  (client.post (string.format "/stories/%s/comments" (tostring story-id))
               {:body data}))

(fn M.update [story-id comment-id data]
  "Update a comment on a story
   story-id: The story ID
   comment-id: The comment ID
   data: {:text string}
   Returns: {:ok bool :data comment :error string}"
  (client.put (string.format "/stories/%s/comments/%s"
                             (tostring story-id)
                             (tostring comment-id))
              {:body data}))

(fn M.delete [story-id comment-id]
  "Delete a comment from a story
   story-id: The story ID
   comment-id: The comment ID
   Returns: {:ok bool :error string}"
  (client.delete (string.format "/stories/%s/comments/%s"
                                (tostring story-id)
                                (tostring comment-id))))

(fn M.batch-create [story-id comments]
  "Create multiple comments on a story
   story-id: The story ID
   comments: [{:text string}]
   Returns: {:ok bool :created [comments] :errors [string]}"
  (let [created []
        errors []]
    (each [i cmt (ipairs comments)]
      (let [result (M.create story-id cmt)]
        (if result.ok
            (table.insert created result.data)
            (table.insert errors (string.format "Comment %d: %s" i (or result.error "unknown error"))))))
    {:ok (= (length errors) 0)
     :created created
     :errors errors}))

(fn M.batch-update [story-id comments]
  "Update multiple comments on a story
   story-id: The story ID
   comments: [{:id number :text string}]
   Returns: {:ok bool :updated [comments] :errors [string]}"
  (let [updated []
        errors []]
    (each [_ cmt (ipairs comments)]
      (let [result (M.update story-id cmt.id {:text cmt.text})]
        (if result.ok
            (table.insert updated result.data)
            (table.insert errors (string.format "Comment %s: %s"
                                                (tostring cmt.id)
                                                (or result.error "unknown error"))))))
    {:ok (= (length errors) 0)
     :updated updated
     :errors errors}))

(fn M.batch-delete [story-id comment-ids]
  "Delete multiple comments from a story
   story-id: The story ID
   comment-ids: [number] list of comment IDs to delete
   Returns: {:ok bool :deleted [number] :errors [string]}"
  (let [deleted []
        errors []]
    (each [_ comment-id (ipairs comment-ids)]
      (let [result (M.delete story-id comment-id)]
        (if result.ok
            (table.insert deleted comment-id)
            (table.insert errors (string.format "Comment %s: %s"
                                                (tostring comment-id)
                                                (or result.error "unknown error"))))))
    {:ok (= (length errors) 0)
     :deleted deleted
     :errors errors}))

M
