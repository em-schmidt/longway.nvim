;; Markdown parser for longway.nvim
;; Parses markdown files to extract synced content

(local config (require :longway.config))
(local frontmatter (require :longway.markdown.frontmatter))

(local M {})

(fn get-sync-markers [section-name]
  "Get the start and end markers for a sync section"
  (let [cfg (config.get)
        start-marker (string.gsub cfg.sync_start_marker "{section}" section-name)
        end-marker (string.gsub cfg.sync_end_marker "{section}" section-name)]
    [start-marker end-marker]))

(fn extract-sync-section [content section-name]
  "Extract content between sync markers for a given section"
  (let [[start-marker end-marker] (get-sync-markers section-name)
        ;; Escape special pattern characters
        start-escaped (string.gsub start-marker "[%-%.%+%[%]%(%)%$%^%%%?%*]" "%%%1")
        end-escaped (string.gsub end-marker "[%-%.%+%[%]%(%)%$%^%%%?%*]" "%%%1")
        pattern (.. start-escaped "\n(.-)\n" end-escaped)
        match (string.match content pattern)]
    match))

(fn M.extract-description [content]
  "Extract the description from sync markers"
  (extract-sync-section content "description"))

(fn parse-task-line [line]
  "Parse a task line into structured data"
  ;; Format: - [x] Task description <!-- task:123 @owner complete:true -->
  (let [checkbox-pattern "^%s*%-%s*%[([x ])%]%s*(.+)$"
        (checkbox rest) (string.match line checkbox-pattern)]
    (when checkbox
      (let [complete (= checkbox "x")
            ;; Extract metadata comment
            metadata-pattern "(.-)%s*<!%-%-%s*task:(%S+)%s*(.-)%s*complete:(%S+)%s*%-%->"
            (description id extras complete-str) (string.match rest metadata-pattern)]
        (if description
            {:description (string.gsub description "%s+$" "")
             :id (if (= id "new") nil (tonumber id))
             :complete complete
             :is_new (= id "new")
             :owner_mention (string.match extras "@(%S+)")}
            ;; No metadata - might be a new task without proper format
            {:description (string.gsub rest "%s+$" "")
             :id nil
             :complete complete
             :is_new true
             :owner_mention nil})))))

(fn M.extract-tasks [content]
  "Extract tasks from the tasks sync section"
  (let [tasks-content (extract-sync-section content "tasks")]
    (if (not tasks-content)
        []
        (let [tasks []]
          (each [line (string.gmatch tasks-content "[^\n]+")]
            (let [task (parse-task-line line)]
              (when task
                (table.insert tasks task))))
          tasks))))

(fn parse-comment-block [block]
  "Parse a comment block into structured data"
  ;; Format:
  ;; ---
  ;; **Author Name** · 2026-01-18 10:30 <!-- comment:123 -->
  ;;
  ;; Comment text here
  (let [header-pattern "%*%*(.-)%*%*%s*·%s*([%d%-]+%s*[%d:]+)%s*<!%-%-%s*comment:(%S+)%s*%-%->"
        lines []
        header-line nil]
    (var found-header false)
    (each [line (string.gmatch (.. block "\n") "([^\n]*)\n")]
      (if (not found-header)
          (let [(author timestamp id) (string.match line header-pattern)]
            (when author
              (set found-header true)
              (set header-line {:author author
                                :timestamp timestamp
                                :id (if (= id "new") nil (tonumber id))
                                :is_new (= id "new")})))
          ;; Collect body lines (skip empty lines at start)
          (when (or (> (length lines) 0) (not (string.match line "^%s*$")))
            (table.insert lines line))))
    (when header-line
      (set header-line.text (table.concat lines "\n"))
      header-line)))

(fn M.extract-comments [content]
  "Extract comments from the comments sync section"
  (let [comments-content (extract-sync-section content "comments")]
    (if (not comments-content)
        []
        (let [comments []
              ;; Split by --- separator
              blocks (vim.split comments-content "\n%-%-%-\n" {:plain false :trimempty true})]
          (each [_ block (ipairs blocks)]
            (let [comment (parse-comment-block block)]
              (when comment
                (table.insert comments comment))))
          comments))))

(fn M.parse [content]
  "Parse a complete markdown file
   Returns: {:frontmatter table :description string :tasks [tasks] :comments [comments] :body string}"
  (let [parsed-fm (frontmatter.parse content)
        description (M.extract-description content)
        tasks (M.extract-tasks content)
        comments (M.extract-comments content)]
    {:frontmatter parsed-fm.frontmatter
     :description description
     :tasks tasks
     :comments comments
     :body parsed-fm.body
     :raw_frontmatter parsed-fm.raw_frontmatter}))

(fn M.get-shortcut-id [content]
  "Extract the Shortcut ID from frontmatter"
  (let [parsed (frontmatter.parse content)]
    (. parsed.frontmatter :shortcut_id)))

(fn M.get-shortcut-type [content]
  "Extract the Shortcut type (story/epic) from frontmatter"
  (let [parsed (frontmatter.parse content)]
    (or (. parsed.frontmatter :shortcut_type) "story")))

(fn M.is-longway-file [content]
  "Check if a file is a longway-managed file"
  (let [parsed (frontmatter.parse content)]
    (not (not (. parsed.frontmatter :shortcut_id)))))

M
