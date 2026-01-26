;; Markdown renderer for longway.nvim
;; Converts Shortcut stories/epics to markdown format

(local config (require :longway.config))
(local frontmatter (require :longway.markdown.frontmatter))
(local hash (require :longway.util.hash))
(local slug (require :longway.util.slug))
(local tasks-md (require :longway.markdown.tasks))
(local comments-md (require :longway.markdown.comments))

(local M {})

(fn generate-story-filename [story]
  "Generate the filename for a story markdown file"
  (slug.make-filename story.id story.name "story"))

(fn build-story-frontmatter [story]
  "Build frontmatter data for a story"
  (let [fm {:shortcut_id story.id
            :shortcut_type "story"
            :shortcut_url story.app_url
            :story_type story.story_type
            :state story.workflow_state_name
            :created_at story.created_at
            :updated_at story.updated_at}]
    ;; Optional fields
    (when story.epic_id
      (set fm.epic_id story.epic_id))
    (when story.iteration_id
      (set fm.iteration_id story.iteration_id))
    (when story.group_id
      (set fm.team_id story.group_id))
    (when story.estimate
      (set fm.estimate story.estimate))

    ;; Owners
    (when (and story.owners (> (length story.owners) 0))
      (set fm.owners [])
      (each [_ owner (ipairs story.owners)]
        (table.insert fm.owners {:name owner.profile.name :id owner.id})))

    ;; Labels
    (when (and story.labels (> (length story.labels) 0))
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

(fn render-local-notes []
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
    (table.insert sections (render-local-notes))

    ;; Build full content
    (let [body (table.concat sections "\n")
          full-content (.. (frontmatter.generate fm-data) "\n\n" body)]
      ;; Compute sync hashes
      (set fm-data.sync_hash (hash.content-hash (or story.description "")))
      (set fm-data.tasks_hash (hash.tasks-hash (or story.tasks [])))
      (set fm-data.comments_hash (hash.comments-hash (or story.comments [])))
      ;; Return with updated frontmatter
      (.. (frontmatter.generate fm-data) "\n\n" body))))

(fn build-epic-frontmatter [epic]
  "Build frontmatter data for an epic"
  {:shortcut_id epic.id
   :shortcut_type "epic"
   :shortcut_url epic.app_url
   :state epic.state
   :planned_start_date epic.planned_start_date
   :deadline epic.deadline
   :created_at epic.created_at
   :updated_at epic.updated_at
   :sync_hash ""
   :local_updated_at (os.date "!%Y-%m-%dT%H:%M:%SZ")
   :stats (or epic.stats {})})

(fn render-story-link [story]
  "Render a link to a story's markdown file"
  (let [filename (generate-story-filename story)]
    (string.format "[%s](../stories/%s)" story.name filename)))

(fn render-story-state-badge [story]
  "Render a state indicator for a story"
  (let [state (or story.workflow_state_name "Unknown")]
    ;; Use emoji or text based on state type
    (if (string.find (string.lower state) "done")
        (.. "✓ " state)
        (string.find (string.lower state) "progress")
        (.. "→ " state)
        state)))

(fn render-epic-stats [epic]
  "Render epic statistics summary"
  (let [stats (or epic.stats {})]
    (string.format "**Progress:** %d/%d stories done (%d%%)"
                   (or stats.num_stories_done 0)
                   (or stats.num_stories 0)
                   (if (and stats.num_stories (> stats.num_stories 0))
                       (math.floor (* (/ (or stats.num_stories_done 0) stats.num_stories) 100))
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
        (let [owner-name (if (and story.owners (> (length story.owners) 0))
                             (. story.owners 1 :profile :name)
                             "-")
              points (or story.estimate "-")
              status-icon (if story.completed "✓"
                              story.started "→"
                              "○")
              story-link (render-story-link story)]
          (table.insert sections
                        (string.format "| %s | %s | %s | %s | %s |"
                                       status-icon
                                       story-link
                                       (or story.workflow_state_name "-")
                                       owner-name
                                       points)))))

    ;; Milestones section (if epic has milestone)
    (when epic.milestone_id
      (table.insert sections "")
      (table.insert sections (string.format "**Milestone:** %s" (or epic.milestone_id "-"))))

    ;; Local notes
    (table.insert sections "")
    (table.insert sections (render-local-notes))

    ;; Build full content
    (let [body (table.concat sections "\n")]
      (set fm-data.sync_hash (hash.content-hash (or epic.description "")))
      (.. (frontmatter.generate fm-data) "\n\n" body))))

M
