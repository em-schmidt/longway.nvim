;; Comment markdown handling for longway.nvim
;; Parse and render comment sections with metadata

(local config (require :longway.config))
(local members (require :longway.api.members))

(local M {})

;;; ============================================================================
;;; Comment Parsing
;;; ============================================================================

(fn parse-comment-metadata [header-line]
  "Parse the header line of a comment block
   Format: **Author Name** · 2026-01-18 10:30 <!-- comment:123 -->
   Returns: {:author string :timestamp string :id number|nil :is_new bool} or nil"
  (let [pattern "%*%*(.-)%*%*%s*·%s*([%d%-]+%s*[%d:]+)%s*<!%-%-[%s]*comment:(%S+)%s*%-%->"
        (author timestamp id) (string.match header-line pattern)]
    (when author
      {:author author
       :timestamp timestamp
       :id (if (= id "new") nil (tonumber id))
       :is_new (= id "new")})))

(fn M.parse-block [block]
  "Parse a comment block into structured data
   Format:
   ---
   **Author Name** · 2026-01-18 10:30 <!-- comment:123 -->

   Comment text here
   Returns: {:id number|nil :author string :timestamp string :text string :is_new bool} or nil"
  (let [lines []]
    (var found-header false)
    (var header-data nil)
    (each [line (string.gmatch (.. block "\n") "([^\n]*)\n")]
      (if (not found-header)
          (let [parsed (parse-comment-metadata line)]
            (when parsed
              (set found-header true)
              (set header-data parsed)))
          ;; Collect body lines (skip empty lines at start)
          (when (or (> (length lines) 0) (not (string.match line "^%s*$")))
            (table.insert lines line))))
    (when header-data
      (set header-data.text (table.concat lines "\n"))
      header-data)))

(fn M.parse-section [content]
  "Parse comments from a comments section content (between sync markers)
   Returns: [comment, ...]"
  (let [comments []
        ;; Split by --- separator
        blocks (vim.split content "\n%-%-%-\n" {:plain false :trimempty true})]
    (each [_ block (ipairs blocks)]
      (let [cmt (M.parse-block block)]
        (when cmt
          (table.insert comments cmt))))
    comments))

;;; ============================================================================
;;; Author Resolution
;;; ============================================================================

(fn M.resolve-author-name [author-id]
  "Resolve an author UUID to display name using members cache
   Returns: string (display name or the raw ID as fallback)"
  (if (not author-id)
      "Unknown"
      (members.resolve-name author-id)))

(fn M.resolve-author-id [name]
  "Resolve a display name to member UUID
   Returns: member-id (string) or nil"
  (when name
    (let [member (members.find-by-name name)]
      (when member
        member.id))))

(fn M.get-current-user []
  "Get the current authenticated user info
   Returns: {:id string :name string} or nil"
  (let [result (members.get-current)]
    (when result.ok
      {:id result.data.id
       :name (members.get-display-name result.data)})))

;;; ============================================================================
;;; Comment Rendering
;;; ============================================================================

(fn M.format-timestamp [created-at]
  "Format an API timestamp for display using config.comments.timestamp_format
   Parses ISO 8601 timestamps and formats via os.date with the configured format string.
   Returns: formatted timestamp string"
  (let [cfg (config.get)]
    (if (not created-at)
        ""
        ;; Parse ISO 8601: YYYY-MM-DDTHH:MM:SS
        (let [(year month day hour min sec)
              (string.match created-at "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")]
          (if (not year)
              ;; Fallback for non-ISO strings: return as-is
              created-at
              (let [time (os.time {:year (tonumber year)
                                   :month (tonumber month)
                                   :day (tonumber day)
                                   :hour (tonumber hour)
                                   :min (tonumber min)
                                   :sec (tonumber sec)})
                    format-str (or (and cfg.comments cfg.comments.timestamp_format)
                                   "%Y-%m-%d %H:%M")]
                (os.date format-str time)))))))

(fn M.render-comment [cmt]
  "Render a single comment as markdown
   cmt: {:id number :author string :timestamp string :text string :is_new bool}
   Returns: string"
  (let [author-name (or cmt.author "Unknown")
        timestamp (or cmt.timestamp "")
        id-part (if cmt.id (tostring cmt.id) "new")
        metadata (string.format "<!-- comment:%s -->" id-part)]
    (table.concat ["---"
                   (string.format "**%s** · %s %s" author-name timestamp metadata)
                   ""
                   (or cmt.text "")]
                  "\n")))

(fn M.render-comments [comments]
  "Render a list of comments as markdown
   Returns: string with separator-delimited comment blocks"
  (if (or (not comments) (= (length comments) 0))
      ""
      (let [rendered []]
        (each [_ cmt (ipairs comments)]
          (table.insert rendered (M.render-comment cmt)))
        (table.concat rendered "\n\n"))))

(fn M.render-section [comments]
  "Render comments as a complete sync section with markers
   Returns: string with sync markers wrapping the comments"
  (let [cfg (config.get)
        start-marker (string.gsub cfg.sync_start_marker "{section}" "comments")
        end-marker (string.gsub cfg.sync_end_marker "{section}" "comments")
        content (M.render-comments comments)]
    (.. start-marker "\n" content "\n" end-marker)))

;;; ============================================================================
;;; API Comment Formatting
;;; ============================================================================

(fn M.format-api-comments [raw-comments]
  "Convert raw API comments to rendering-ready format with author resolution
   raw-comments: [{:id :text :author_id :created_at}]
   Returns: [{:id :author :timestamp :text :is_new}]"
  (let [formatted []]
    (each [_ cmt (ipairs (or raw-comments []))]
      (let [author-name (M.resolve-author-name cmt.author_id)
            timestamp (M.format-timestamp cmt.created_at)]
        (table.insert formatted
                      {:id cmt.id
                       :author author-name
                       :timestamp timestamp
                       :text (or cmt.text "")
                       :is_new false})))
    formatted))

;;; ============================================================================
;;; Comment Comparison Utilities
;;; ============================================================================

(fn M.comment-changed? [local-comment remote-comment]
  "Check if a local comment has text changes compared to remote
   Note: Shortcut API does not support editing comments, so edits trigger warnings.
   Returns: bool"
  (let [local-text (string.gsub (or local-comment.text "") "^%s*(.-)%s*$" "%1")
        remote-text (string.gsub (or remote-comment.text "") "^%s*(.-)%s*$" "%1")]
    (not= local-text remote-text)))

(fn M.find-comment-by-id [comments id]
  "Find a comment in a list by its ID
   Returns: comment or nil"
  (var found nil)
  (each [_ cmt (ipairs comments) &until found]
    (when (= cmt.id id)
      (set found cmt)))
  found)

(fn M.comments-equal? [a b]
  "Check if two comment lists are semantically equal
   Returns: bool"
  (if (not= (length a) (length b))
      false
      (do
        (var equal true)
        (each [i cmt-a (ipairs a) &until (not equal)]
          (let [cmt-b (. b i)]
            (when (or (not cmt-b)
                      (not= cmt-a.id cmt-b.id)
                      (not= cmt-a.text cmt-b.text))
              (set equal false))))
        equal)))

M
