;; Markdown renderer for longway.nvim
;; Converts Shortcut stories/epics to markdown format

(local config (require :longway.config))
(local frontmatter (require :longway.markdown.frontmatter))
(local hash (require :longway.util.hash))
(local slug (require :longway.util.slug))
(local tasks-md (require :longway.markdown.tasks))
(local comments-md (require :longway.markdown.comments))

(local M {})

(local MAX_COL_WIDTH 35)

(fn nil-safe [value fallback]
  "Return fallback if value is nil or vim.NIL (userdata from JSON null).
   Defaults fallback to nil."
  (if (or (= value nil)
          (and (= (type value) :userdata) (= value vim.NIL)))
      fallback
      value))

(fn truncate [text max-len]
  "Truncate text to max-len characters, appending '...' if truncated."
  (if (or (not text) (<= (length text) max-len))
      text
      (.. (string.sub text 1 (- max-len 3)) "...")))

(fn generate-story-filename [story]
  "Generate the filename for a story markdown file"
  (slug.make-filename story.id story.name "story"))

(fn build-story-frontmatter [story]
  "Build frontmatter data for a story"
  (let [fm {:shortcut_id story.id
            :shortcut_type "story"
            :shortcut_url (nil-safe story.app_url)
            :story_type (nil-safe story.story_type)
            :state (nil-safe story.workflow_state_name)
            :created_at (nil-safe story.created_at)
            :updated_at (nil-safe story.updated_at)}]
    ;; Optional fields — use nil-safe to filter vim.NIL from API responses
    (let [epic-id (nil-safe story.epic_id)
          iteration-id (nil-safe story.iteration_id)
          group-id (nil-safe story.group_id)
          estimate (nil-safe story.estimate)]
      (when epic-id
        (set fm.epic_id epic-id))
      (when iteration-id
        (set fm.iteration_id iteration-id))
      (when group-id
        (set fm.team_id group-id))
      (when estimate
        (set fm.estimate estimate)))

    ;; Owners
    (when (and story.owners (not= (type story.owners) :userdata)
              (> (length story.owners) 0))
      (set fm.owners [])
      (each [_ owner (ipairs story.owners)]
        (table.insert fm.owners {:name (nil-safe owner.profile.name "Unknown")
                                 :id owner.id})))

    ;; Labels
    (when (and story.labels (not= (type story.labels) :userdata)
              (> (length story.labels) 0))
      (set fm.labels [])
      (each [_ label (ipairs story.labels)]
        (table.insert fm.labels label.name)))

    ;; Sync hashes (computed after rendering)
    (set fm.sync_hash "")
    (set fm.tasks_hash "")
    (set fm.comments_hash "")
    (set fm.local_updated_at (os.date "!%Y-%m-%dT%H:%M:%SZ"))

    fm))

(fn render-sync-section [section-name content]
  "Wrap content in sync markers"
  (let [cfg (config.get)
        start-marker (string.gsub cfg.sync_start_marker "{section}" section-name)
        end-marker (string.gsub cfg.sync_end_marker "{section}" section-name)]
    (.. start-marker "\n" content "\n" end-marker)))

(fn render-description [description]
  "Render description section"
  (let [desc (or description "")]
    (render-sync-section "description" desc)))

(fn render-tasks [tasks]
  "Render tasks section"
  (if (or (not tasks) (= (length tasks) 0))
      (render-sync-section "tasks" "")
      (let [formatted (tasks-md.format-api-tasks tasks)
            content (tasks-md.render-tasks formatted)]
        (render-sync-section "tasks" content))))

(fn render-comments [comments]
  "Render comments section
   Delegates to comments-md for rendering, matching the tasks pattern."
  (if (or (not comments) (= (length comments) 0))
      (render-sync-section "comments" "")
      (let [content (comments-md.render-comments comments)]
        (render-sync-section "comments" content))))

(fn M.render-local-notes []
  "Render the local notes section template"
  (table.concat ["## Local Notes"
                 ""
                 "<!-- This section is NOT synced to Shortcut -->"
                 ""]
                "\n"))

(fn M.render-story [story]
  "Render a complete story to markdown"
  (let [cfg (config.get)
        fm-data (build-story-frontmatter story)
        sections [(.. "# " story.name)
                  ""
                  "## Description"
                  ""
                  (render-description story.description)]]

    ;; Tasks section
    (when cfg.sync_sections.tasks
      (table.insert sections "")
      (table.insert sections "## Tasks")
      (table.insert sections "")
      (table.insert sections (render-tasks story.tasks)))

    ;; Comments section
    (when cfg.sync_sections.comments
      (table.insert sections "")
      (table.insert sections "## Comments")
      (table.insert sections "")
      (table.insert sections (render-comments story.comments)))

    ;; Local notes section
    (table.insert sections "")
    (table.insert sections (M.render-local-notes))

    ;; Build full content
    (let [body (table.concat sections "\n")
          full-content (.. (frontmatter.generate fm-data) "\n\n" body)
          ;; Re-parse rendered content so hashes match what future parses produce.
          ;; This handles any transformations in the render→parse round-trip
          ;; (e.g., leading blank line stripping in comments, whitespace normalization).
          parser (require :longway.markdown.parser)
          re-parsed (parser.parse full-content)]
      (set fm-data.sync_hash (hash.content-hash (or re-parsed.description "")))
      (set fm-data.tasks_hash (hash.tasks-hash (or re-parsed.tasks [])))
      (set fm-data.comments_hash (hash.comments-hash (or re-parsed.comments [])))
      ;; Return with updated frontmatter
      (.. (frontmatter.generate fm-data) "\n\n" body))))

(fn build-epic-frontmatter [epic]
  "Build frontmatter data for an epic"
  (let [stats (nil-safe epic.stats {})]
    {:shortcut_id epic.id
     :shortcut_type "epic"
     :shortcut_url (nil-safe epic.app_url)
     :state (nil-safe epic.state)
     :planned_start_date (nil-safe epic.planned_start_date)
     :deadline (nil-safe epic.deadline)
     :created_at (nil-safe epic.created_at)
     :updated_at (nil-safe epic.updated_at)
     :sync_hash ""
     :local_updated_at (os.date "!%Y-%m-%dT%H:%M:%SZ")
     :stats stats}))

(fn render-story-link [story]
  "Render a link to a story's markdown file.
   Truncates the display title to MAX_COL_WIDTH for table column readability."
  (let [filename (generate-story-filename story)
        display-name (truncate story.name MAX_COL_WIDTH)]
    (string.format "[%s](../stories/%s)" display-name filename)))

(fn render-story-state-badge [story]
  "Render a state indicator for a story"
  (let [state (nil-safe story.workflow_state_name "Unknown")]
    ;; Use emoji or text based on state type
    (if (string.find (string.lower state) "done")
        (.. "✓ " state)
        (string.find (string.lower state) "progress")
        (.. "→ " state)
        state)))

(fn render-epic-stats [epic]
  "Render epic statistics summary"
  (let [stats (nil-safe epic.stats {})
        num-done (nil-safe stats.num_stories_done 0)
        num-total (nil-safe stats.num_stories 0)]
    (string.format "**Progress:** %d/%d stories done (%d%%)"
                   num-done
                   num-total
                   (if (and num-total (> num-total 0))
                       (math.floor (* (/ num-done num-total) 100))
                       0))))

(fn M.render-epic [epic stories]
  "Render an epic to markdown, optionally with story list"
  (let [fm-data (build-epic-frontmatter epic)
        sections [(.. "# " epic.name)
                  ""
                  (render-epic-stats epic)
                  ""
                  "## Description"
                  ""
                  (render-sync-section "description" (or epic.description ""))]]

    ;; Stories table
    (when (and stories (> (length stories) 0))
      (table.insert sections "")
      (table.insert sections "## Stories")
      (table.insert sections "")
      (table.insert sections "| Status | Title | State | Owner | Points |")
      (table.insert sections "|:------:|-------|-------|-------|-------:|")
      (each [_ story (ipairs stories)]
        (let [owners (nil-safe story.owners)
              owner-name (if (and owners (> (length owners) 0))
                             (nil-safe (. owners 1 :profile :name) "-")
                             "-")
              points (nil-safe story.estimate "-")
              completed (nil-safe story.completed)
              started (nil-safe story.started)
              status-icon (if completed "✓"
                              started "→"
                              "○")
              story-link (render-story-link story)]
          (table.insert sections
                        (string.format "| %s | %s | %s | %s | %s |"
                                       status-icon
                                       story-link
                                       (truncate (nil-safe story.workflow_state_name "-") MAX_COL_WIDTH)
                                       (truncate owner-name MAX_COL_WIDTH)
                                       points)))))

    ;; Milestones section (if epic has milestone)
    (when (nil-safe epic.milestone_id)
      (table.insert sections "")
      (table.insert sections (string.format "**Milestone:** %s" (nil-safe epic.milestone_id "-"))))

    ;; Local notes
    (table.insert sections "")
    (table.insert sections (M.render-local-notes))

    ;; Build full content
    (let [body (table.concat sections "\n")
          full-content (.. (frontmatter.generate fm-data) "\n\n" body)
          ;; Re-parse rendered content so hash matches what future parses produce
          parser (require :longway.markdown.parser)
          re-parsed (parser.parse full-content)]
      (set fm-data.sync_hash (hash.content-hash (or re-parsed.description "")))
      (.. (frontmatter.generate fm-data) "\n\n" body))))

M
