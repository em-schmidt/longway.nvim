;; Markdown parser for longway.nvim
;; Parses markdown files to extract synced content

(local config (require :longway.config))
(local frontmatter (require :longway.markdown.frontmatter))
(local tasks-md (require :longway.markdown.tasks))

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
        result (string.match content pattern)]
    result))

(fn M.extract-description [content]
  "Extract the description from sync markers"
  (extract-sync-section content "description"))

(fn M.extract-tasks [content]
  "Extract tasks from the tasks sync section"
  (let [tasks-content (extract-sync-section content "tasks")]
    (if (not tasks-content)
        []
        (tasks-md.parse-section tasks-content))))

(fn parse-comment-block [block]
  "Parse a comment block into structured data"
  ;; Format:
  ;; ---
  ;; **Author Name** · 2026-01-18 10:30 <!-- comment:123 -->
  ;;
  ;; Comment text here
  (let [header-pattern "%*%*(.-)%*%*%s*·%s*([%d%-]+%s*[%d:]+)%s*<!%-%-%s*comment:(%S+)%s*%-%->"
        lines []]
    (var found-header false)
    (var header-line nil)
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
            (let [cmt (parse-comment-block block)]
              (when cmt
                (table.insert comments cmt))))
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
