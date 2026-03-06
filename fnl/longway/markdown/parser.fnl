;; Markdown parser for longway.nvim
;; Parses markdown files to extract synced content

(local frontmatter (require :longway.markdown.frontmatter))
(local tasks-md (require :longway.markdown.tasks))
(local comments-md (require :longway.markdown.comments))

(local M {})

;; Known section headers (in expected document order)
(local known-headers ["Description" "Tasks" "Comments" "Local Notes" "Stories"])

(fn extract-header-section [content header-name]
  "Extract content between a ## header and the next ## header (or EOF).
   Returns the content between the header and the next section, with
   leading/trailing blank lines trimmed. Returns nil if header not found."
  (let [;; Try finding header preceded by newline first, then at start of content
        header-with-nl (.. "\n## " header-name "\n")
        header-at-start (.. "## " header-name "\n")
        pos (string.find content header-with-nl 1 true)
        ;; If not found with leading newline, check if it's at the very start
        (pos header-len) (if pos
                             (values pos (length header-with-nl))
                             (let [start-pos (string.find content header-at-start 1 true)]
                               (if (= start-pos 1)
                                   (values 1 (length header-at-start))
                                   (values nil 0))))]
    (when pos
      ;; Skip past the header line itself
      (let [content-start (+ pos header-len)
            ;; Find the next ## header or EOF
            next-header-pos (string.find content "\n## " content-start true)
            raw (if next-header-pos
                    (string.sub content content-start next-header-pos)
                    (string.sub content content-start))]
        ;; Trim leading and trailing blank lines
        (let [trimmed (-> raw
                          (string.gsub "^[\n]+" "")
                          (string.gsub "[\n%s]+$" ""))]
          (if (= trimmed "")
              ""
              trimmed))))))

(fn has-legacy-sync-markers [content]
  "Check if content contains legacy sync markers (for backward compatibility)"
  (not= nil (string.find content "<!-- BEGIN SHORTCUT SYNC:" 1 true)))

(fn extract-legacy-sync-section [content section-name]
  "Extract content between legacy sync markers (backward compatibility).
   Emits a deprecation warning."
  (let [start-marker (.. "<!-- BEGIN SHORTCUT SYNC:" section-name " -->")
        end-marker (.. "<!-- END SHORTCUT SYNC:" section-name " -->")
        start-escaped (string.gsub start-marker "[%-%.%+%[%]%(%)%$%^%%%?%*]" "%%%1")
        end-escaped (string.gsub end-marker "[%-%.%+%[%]%(%)%$%^%%%?%*]" "%%%1")
        pattern (.. start-escaped "\n(.-)\n" end-escaped)
        result (string.match content pattern)]
    (when result
      (let [notify (require :longway.ui.notify)]
        (notify.warn "File uses legacy sync markers. Run :LongwayRefresh to migrate to header-based format."))
      result)))

(fn extract-section [content section-name]
  "Extract a section, trying header-based first, falling back to legacy markers."
  (let [result (extract-header-section content section-name)]
    (if (not= result nil)
        result
        ;; Fallback to legacy sync markers (which used lowercase section names)
        (when (has-legacy-sync-markers content)
          (extract-legacy-sync-section content (string.lower section-name))))))

(fn M.extract-description [content]
  "Extract the description section"
  (extract-section content "Description"))

(fn M.extract-tasks [content]
  "Extract tasks from the tasks section"
  (let [tasks-content (extract-section content "Tasks")]
    (if (or (not tasks-content) (= tasks-content ""))
        []
        (tasks-md.parse-section tasks-content))))

(fn M.extract-comments [content]
  "Extract comments from the comments section.
   Delegates to comments-md.parse-section (single source of truth)."
  (let [comments-content (extract-section content "Comments")]
    (if (or (not comments-content) (= comments-content ""))
        []
        (comments-md.parse-section comments-content))))

(fn M.extract-local-notes [content]
  "Extract the Local Notes section from markdown content.
   Returns the full text from '## Local Notes' to end of content, or nil if not found."
  (let [pattern "\n## Local Notes\n"
        pos (string.find content pattern 1 true)]
    (when pos
      (string.sub content (+ pos 1)))))

(fn M.parse [content]
  "Parse a complete markdown file
   Returns: {:frontmatter table :description string :tasks [tasks] :comments [comments] :local_notes string :body string}"
  (let [parsed-fm (frontmatter.parse content)
        description (M.extract-description content)
        tasks (M.extract-tasks content)
        comments (M.extract-comments content)
        local-notes (M.extract-local-notes content)]
    {:frontmatter parsed-fm.frontmatter
     :description description
     :tasks tasks
     :comments comments
     :local_notes local-notes
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
