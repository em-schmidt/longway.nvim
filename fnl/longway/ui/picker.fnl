;; Snacks picker integration for longway.nvim
;; Provides custom picker sources for stories, epics, presets, modified files, and comments.

(local config (require :longway.config))
(local notify (require :longway.ui.notify))

(local M {})

;; ---------------------------------------------------------------------------
;; Helpers
;; ---------------------------------------------------------------------------

(fn M.check-snacks []
  "Check if snacks.nvim is available. Shows error if not.
   Returns: bool"
  (let [(ok _) (pcall require :snacks)]
    (when (not ok)
      (notify.error "snacks.nvim is required for :LongwayPicker. Install folke/snacks.nvim"))
    ok))

(fn M.find-local-file [shortcut-id shortcut-type]
  "Search workspace for existing markdown file matching shortcut_id.
   Uses glob to find files like {id}-*.md in the appropriate directory.
   Returns: filepath or nil"
  (let [dir (if (= shortcut-type "epic")
                (config.get-epics-dir)
                (config.get-stories-dir))
        pattern (.. dir "/" (tostring shortcut-id) "-*.md")
        matches (vim.fn.glob pattern false true)]
    (when (> (length matches) 0)
      (. matches 1))))

(fn M.build-picker-layout []
  "Build layout config from user config.picker settings.
   Returns: snacks layout table"
  (let [cfg (config.get)
        picker-cfg (or cfg.picker {})]
    {:preset (or picker-cfg.layout "default")
     :preview (if (= picker-cfg.preview false) false true)}))

(fn M.truncate [s max-len]
  "Truncate a string to max-len, appending ... if needed"
  (if (or (not s) (<= (length s) max-len))
      (or s "")
      (.. (string.sub s 1 (- max-len 3)) "...")))

(fn M.first-line [s]
  "Get the first non-empty line of a string"
  (if (not s) ""
      (let [line (string.match s "^%s*(.-)%s*$")]
        (or (string.match line "^([^\n]+)") ""))))

(fn item-preview [ctx]
  "Preview handler that dispatches based on item.preview value.
   Delegates to Snacks built-in file previewer for items with file,
   or the built-in preview previewer for items with text preview data."
  (let [preview-mod (require :snacks.picker.preview)
        item ctx.item]
    (if (and item item.file)
        (preview-mod.file ctx)
        (preview-mod.preview ctx))))

;; ---------------------------------------------------------------------------
;; Source: Stories
;; ---------------------------------------------------------------------------

(fn M.pick-stories [opts]
  "Open a Snacks picker for stories.
   opts: {:query string :preset string}"
  (let [Snacks (require :snacks)
        search-api (require :longway.api.search)
        stories-api (require :longway.api.stories)
        opts (or opts {})
        ;; Determine query
        query (or opts.query
                  (when opts.preset
                    (let [preset (config.get-preset opts.preset)]
                      (when preset preset.query)))
                  (let [default (config.get-default-preset)]
                    (when default
                      (let [preset (config.get-preset default)]
                        (when preset preset.query)))))]
    (Snacks.picker {:source "longway_stories"
                    :title "Longway Stories"
                    :layout (M.build-picker-layout)
                    :preview item-preview
                    :finder (fn [finder-opts ctx]
                              (let [result (if query
                                              (search-api.search-stories-all query {:max_results 100})
                                              (stories-api.query {:archived false}))
                                    items []]
                                (when result.ok
                                  (each [i story (ipairs (or result.data []))]
                                    (let [file (M.find-local-file story.id "story")
                                          state (or story.workflow_state_name "")
                                          story-type (or story.story_type "")
                                          owner-names (let [names []]
                                                        (each [_ o (ipairs (or story.owners []))]
                                                          (when o.profile
                                                            (table.insert names (or o.profile.name o.profile.mention_name ""))))
                                                        (table.concat names ", "))
                                          label-names (let [names []]
                                                        (each [_ lbl (ipairs (or story.labels []))]
                                                          (table.insert names (or lbl.name "")))
                                                        (table.concat names ", "))
                                          preview-text (if story.description
                                                           story.description
                                                           (string.format
                                                             "# %s\n\n**State:** %s\n**Type:** %s%s%s%s"
                                                             (or story.name "")
                                                             state
                                                             story-type
                                                             (if (> (length owner-names) 0)
                                                                 (.. "\n**Owners:** " owner-names)
                                                                 "")
                                                             (if (and story.estimate (not= story.estimate vim.NIL))
                                                                 (.. "\n**Estimate:** " (tostring story.estimate))
                                                                 "")
                                                             (if (> (length label-names) 0)
                                                                 (.. "\n**Labels:** " label-names)
                                                                 "")))
                                          text (string.format "%s %s [%s] @%s"
                                                              (tostring story.id)
                                                              (or story.name "")
                                                              state
                                                              owner-names)]
                                      (table.insert items {:text text
                                                           :idx i
                                                           :id story.id
                                                           :name (or story.name "")
                                                           :state state
                                                           :story_type story-type
                                                           :owners owner-names
                                                           :estimate story.estimate
                                                           :file file
                                                           :preview (if file "file"
                                                                        {:text preview-text
                                                                         :ft "markdown"})}))))
                                items))
                    :format (fn [item picker]
                              (let [ret []]
                                (table.insert ret [(tostring (or item.id "")) "Number"])
                                (table.insert ret [" " {:virtual true}])
                                (table.insert ret [(or item.name "") "SnacksPickerLabel"])
                                (table.insert ret [(.. " [" (or item.state "") "]") "Type"])
                                (when (and item.owners (> (length item.owners) 0))
                                  (table.insert ret [(.. " @" item.owners) "Comment"]))
                                (when item.file
                                  (table.insert ret [" (local)" "Special"]))
                                ret))
                    :confirm (fn [picker item]
                               (picker:close)
                               (when item
                                 (if item.file
                                     (vim.cmd (.. "edit " (vim.fn.fnameescape item.file)))
                                     (let [pull (require :longway.sync.pull)]
                                       (pull.pull-story-to-buffer item.id)))))})))

;; ---------------------------------------------------------------------------
;; Source: Epics
;; ---------------------------------------------------------------------------

(fn M.pick-epics [opts]
  "Open a Snacks picker for epics."
  (let [Snacks (require :snacks)
        epics-api (require :longway.api.epics)]
    (Snacks.picker {:source "longway_epics"
                    :title "Longway Epics"
                    :layout (M.build-picker-layout)
                    :preview item-preview
                    :finder (fn [finder-opts ctx]
                              (let [result (epics-api.list)
                                    items []]
                                (when result.ok
                                  (each [i epic (ipairs (or result.data []))]
                                    (let [file (M.find-local-file epic.id "epic")
                                          state (or epic.state "")
                                          stats (or epic.stats {})
                                          done (or stats.num_stories_done 0)
                                          total-stories (or stats.num_stories 0)
                                          started (or stats.num_stories_started 0)
                                          unstarted (or stats.num_stories_unstarted 0)
                                          points-done (or stats.num_points_done 0)
                                          points-total (or stats.num_points 0)
                                          label-names (let [names []]
                                                        (each [_ lbl (ipairs (or epic.labels []))]
                                                          (table.insert names (or lbl.name "")))
                                                        (table.concat names ", "))
                                          preview-text (if epic.description
                                                           epic.description
                                                           (string.format
                                                             "# %s\n\n**State:** %s\n**Stories:** %d/%d done (%d started, %d unstarted)\n**Points:** %d/%d%s%s%s"
                                                             (or epic.name "")
                                                             state
                                                             done total-stories
                                                             started unstarted
                                                             points-done points-total
                                                             (if (and epic.planned_start_date (not= epic.planned_start_date vim.NIL))
                                                                 (.. "\n**Start:** " epic.planned_start_date)
                                                                 "")
                                                             (if (and epic.deadline (not= epic.deadline vim.NIL))
                                                                 (.. "\n**Deadline:** " epic.deadline)
                                                                 "")
                                                             (if (> (length label-names) 0)
                                                                 (.. "\n**Labels:** " label-names)
                                                                 "")))
                                          text (string.format "%s %s [%s] (%d/%d stories)"
                                                              (tostring epic.id)
                                                              (or epic.name "")
                                                              state
                                                              done total-stories)]
                                      (table.insert items {:text text
                                                           :idx i
                                                           :id epic.id
                                                           :name (or epic.name "")
                                                           :state state
                                                           :done done
                                                           :total_stories total-stories
                                                           :file file
                                                           :preview (if file "file"
                                                                        {:text preview-text
                                                                         :ft "markdown"})}))))
                                items))
                    :format (fn [item picker]
                              (let [ret []]
                                (table.insert ret [(tostring (or item.id "")) "Number"])
                                (table.insert ret [" " {:virtual true}])
                                (table.insert ret [(or item.name "") "SnacksPickerLabel"])
                                (table.insert ret [(.. " [" (or item.state "") "]") "Type"])
                                (table.insert ret [(string.format " (%d/%d stories)"
                                                                  (or item.done 0)
                                                                  (or item.total_stories 0))
                                                   "Comment"])
                                (when item.file
                                  (table.insert ret [" (local)" "Special"]))
                                ret))
                    :confirm (fn [picker item]
                               (picker:close)
                               (when item
                                 (if item.file
                                     (vim.cmd (.. "edit " (vim.fn.fnameescape item.file)))
                                     (let [pull (require :longway.sync.pull)]
                                       (pull.pull-epic-to-buffer item.id)))))})))

;; ---------------------------------------------------------------------------
;; Source: Presets
;; ---------------------------------------------------------------------------

(fn M.pick-presets []
  "Open a Snacks picker for configured presets."
  (let [Snacks (require :snacks)
        presets (config.get-presets)
        default-preset (config.get-default-preset)
        items []]
    ;; Build static items
    (var idx 0)
    (each [name preset (pairs presets)]
      (set idx (+ idx 1))
      (let [is-default (= name default-preset)
            desc (or preset.description preset.query "")
            text (.. name ": " desc (if is-default " (default)" ""))]
        (table.insert items {:text text
                             :idx idx
                             :name name
                             :query (or preset.query "")
                             :description desc
                             :is_default is-default
                             :preview {:text (string.format "Preset: %s\nQuery: %s\nDescription: %s%s"
                                                            name
                                                            (or preset.query "")
                                                            (or preset.description "")
                                                            (if is-default "\n(default preset)" ""))
                                       :ft "yaml"}})))
    (if (= (length items) 0)
        (notify.warn "No presets configured")
        (Snacks.picker {:source "longway_presets"
                    :title "Longway Presets"
                    :layout (M.build-picker-layout)
                    :preview item-preview
                    :items items
                    :format (fn [item picker]
                              (let [ret []]
                                (table.insert ret [(or item.name "") "SnacksPickerLabel"])
                                (table.insert ret [(.. " — " (or item.description "")) "Comment"])
                                (when item.is_default
                                  (table.insert ret [" (default)" "Special"]))
                                ret))
                    :confirm (fn [picker item]
                               (picker:close)
                               (when item
                                 (let [core (require :longway.core)]
                                   (core.sync item.name))))}))))

;; ---------------------------------------------------------------------------
;; Source: Modified
;; ---------------------------------------------------------------------------

(fn M.pick-modified [opts]
  "Open a Snacks picker for locally modified (pending push) files."
  (let [Snacks (require :snacks)
        parser (require :longway.markdown.parser)
        diff (require :longway.sync.diff)
        stories-dir (config.get-stories-dir)
        epics-dir (config.get-epics-dir)]
    (Snacks.picker {:source "longway_modified"
                    :title "Longway Modified Files"
                    :layout (M.build-picker-layout)
                    :preview item-preview
                    :finder (fn [finder-opts ctx]
                              (let [items []
                                    ;; Gather all markdown files
                                    story-files (vim.fn.glob (.. stories-dir "/*.md") false true)
                                    epic-files (vim.fn.glob (.. epics-dir "/*.md") false true)
                                    all-files (vim.list_extend (or story-files [])
                                                               (or epic-files []))]
                                (var idx 0)
                                (each [_ filepath (ipairs all-files)]
                                  (let [(ok content) (pcall #(let [f (io.open filepath "r")]
                                                               (when f
                                                                 (let [c (f:read "*a")]
                                                                   (f:close)
                                                                   c))))]
                                    (when (and ok content)
                                      (let [parsed (parser.parse content)
                                            fm parsed.frontmatter
                                            shortcut-id fm.shortcut_id]
                                        (when (and shortcut-id
                                                   (not ((. diff "first-sync?") fm))
                                                   ((. diff "any-local-change?") parsed))
                                          (let [changes ((. diff "detect-local-changes") parsed)
                                                sections []
                                                _ (do
                                                    (when changes.description (table.insert sections "description"))
                                                    (when changes.tasks (table.insert sections "tasks"))
                                                    (when changes.comments (table.insert sections "comments")))
                                                has-conflict (not= fm.conflict_sections nil)
                                                name (or fm.title (string.match content "# ([^\n]+)") (tostring shortcut-id))]
                                            (set idx (+ idx 1))
                                            (table.insert items {:text (string.format "%s %s (%s)"
                                                                                      (tostring shortcut-id)
                                                                                      name
                                                                                      (table.concat sections ", "))
                                                                 :idx idx
                                                                 :id shortcut-id
                                                                 :name name
                                                                 :file filepath
                                                                 :changed_sections sections
                                                                 :has_conflict has-conflict
                                                                 :preview "file"})))))))
                                items))
                    :format (fn [item picker]
                              (let [ret []]
                                (table.insert ret [(tostring (or item.id "")) "Number"])
                                (table.insert ret [" " {:virtual true}])
                                (table.insert ret [(or item.name "") "SnacksPickerLabel"])
                                (table.insert ret [(.. " (" (table.concat (or item.changed_sections []) ", ") ")")
                                                   "WarningMsg"])
                                (when item.has_conflict
                                  (table.insert ret [" CONFLICT" "ErrorMsg"]))
                                ret))
                    :win {:input {:keys {:<C-p> (let [keymap {:mode [:n :i]
                                                                    :desc "Push selected file"}]
                                                        (tset keymap 1
                                                              (fn [picker]
                                                                (let [item (picker:current)
                                                                      push-mod (require :longway.sync.push)]
                                                                  (when (and item item.file)
                                                                    (vim.cmd (.. "edit " (vim.fn.fnameescape item.file)))
                                                                    (push-mod.push-current-buffer)))))
                                                        keymap)}}}
                    :confirm (fn [picker item]
                               (picker:close)
                               (when (and item item.file)
                                 (vim.cmd (.. "edit " (vim.fn.fnameescape item.file)))))})))

;; ---------------------------------------------------------------------------
;; Source: Comments
;; ---------------------------------------------------------------------------

(fn M.pick-comments [opts]
  "Open a Snacks picker for comments on the current story.
   opts: {:bufnr number}"
  (let [Snacks (require :snacks)
        comments-api (require :longway.api.comments)
        members (require :longway.api.members)
        parser (require :longway.markdown.parser)
        opts (or opts {})
        bufnr (or opts.bufnr (vim.api.nvim_get_current_buf))
        lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        content (table.concat lines "\n")
        parsed (parser.parse content)
        shortcut-id (. parsed.frontmatter :shortcut_id)]
    (if (not shortcut-id)
        (notify.error "Not a longway-managed file")
        (Snacks.picker {:source "longway_comments"
                        :title (string.format "Comments — Story %s" (tostring shortcut-id))
                        :layout (M.build-picker-layout)
                        :preview item-preview
                        :finder (fn [finder-opts ctx]
                                  (let [result (comments-api.list shortcut-id)
                                        items []]
                                    (when result.ok
                                      (each [i cmt (ipairs (or result.data []))]
                                        (let [author-name (or (members.resolve-name cmt.author_id) "Unknown")
                                              timestamp (or cmt.created_at "")
                                              body (or cmt.text "")
                                              fl (M.first-line body)
                                              text (string.format "%s — %s" author-name (M.truncate fl 60))]
                                          (table.insert items {:text text
                                                               :idx i
                                                               :id cmt.id
                                                               :author author-name
                                                               :created_at timestamp
                                                               :body body
                                                               :preview {:text (string.format "**%s** · %s\n\n%s"
                                                                                              author-name
                                                                                              timestamp
                                                                                              body)
                                                                         :ft "markdown"}}))))
                                    items))
                        :format (fn [item picker]
                                  (let [ret []]
                                    (table.insert ret [(or item.author "") "SnacksPickerLabel"])
                                    (table.insert ret [(.. " · " (M.truncate (or item.created_at "") 16)) "Comment"])
                                    (table.insert ret [(.. " — " (M.truncate (M.first-line (or item.body "")) 50)) "Normal"])
                                    ret))
                        :confirm (fn [picker item]
                                   (picker:close)
                                   (when item
                                     ;; Search for comment marker in buffer
                                     (let [marker (.. "comment:" (tostring item.id))
                                           lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)]
                                       (var found false)
                                       (each [i line (ipairs lines) &until found]
                                         (when (string.find line marker 1 true)
                                           (set found true)
                                           (vim.api.nvim_win_set_cursor 0 [i 0]))))))}))))

M
