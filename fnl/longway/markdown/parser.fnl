;; Markdown parser for longway.nvim
;; Parses markdown files to extract synced content

(local config (require :longway.config))
(local frontmatter (require :longway.markdown.frontmatter))
(local tasks-md (require :longway.markdown.tasks))
(local comments-md (require :longway.markdown.comments))

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

(fn M.extract-comments [content]
  "Extract comments from the comments sync section.
   Delegates to comments-md.parse-section (single source of truth)."
  (let [comments-content (extract-sync-section content "comments")]
    (if (not comments-content)
        []
        (comments-md.parse-section comments-content))))

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
