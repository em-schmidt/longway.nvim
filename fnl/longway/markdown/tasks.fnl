;; Task markdown handling for longway.nvim
;; Parse and render task checkboxes with metadata

(local config (require :longway.config))
(local members (require :longway.api.members))

(local M {})

(fn nil-safe [value fallback]
  "Return fallback if value is nil or vim.NIL (userdata from JSON null).
   Defaults fallback to nil."
  (if (or (= value nil)
          (and (= (type value) :userdata) (= value vim.NIL)))
      fallback
      value))

;;; ============================================================================
;;; Task Parsing
;;; ============================================================================

(fn parse-task-metadata [metadata-str]
  "Parse the metadata comment: task:123 @owner complete:true
   Returns: {:id number|nil :owner_mention string|nil :complete bool :is_new bool}"
  (let [result {:id nil :owner_mention nil :complete false :is_new false}]
    ;; Extract task ID
    (let [id-match (string.match metadata-str "task:(%S+)")]
      (if (= id-match "new")
          (set result.is_new true)
          (set result.id (tonumber id-match))))

    ;; Extract owner mention
    (let [owner-match (string.match metadata-str "@(%S+)")]
      (when owner-match
        (set result.owner_mention owner-match)))

    ;; Extract completion state
    (let [complete-match (string.match metadata-str "complete:(%S+)")]
      (set result.complete (= complete-match "true")))

    result))

(fn M.parse-line [line]
  "Parse a single task line into structured data
   Format: - [x] Task description <!-- task:123 @owner complete:true -->
   Returns: task table or nil if not a valid task line"
  ;; Match checkbox pattern: - [x] or - [ ]
  (let [checkbox-pattern "^%s*%-%s*%[([x ])%]%s*(.+)$"
        (checkbox rest) (string.match line checkbox-pattern)]
    (when checkbox
      (let [checkbox-complete (= checkbox "x")
            ;; Try to extract metadata comment
            metadata-pattern "(.-)%s*<!%-%-(.-)%-%->%s*$"
            (description metadata-str) (string.match rest metadata-pattern)]
        (if metadata-str
            ;; Has metadata comment
            (let [meta (parse-task-metadata metadata-str)]
              {:description (string.gsub description "%s+$" "")
               :id meta.id
               :complete checkbox-complete
               :is_new meta.is_new
               :owner_mention meta.owner_mention
               :owner_ids []
               :raw_line line})
            ;; No metadata - treat as new task
            {:description (string.gsub rest "%s+$" "")
             :id nil
             :complete checkbox-complete
             :is_new true
             :owner_mention nil
             :owner_ids []
             :raw_line line})))))

(fn M.parse-section [content]
  "Parse tasks from a tasks section content (between sync markers)
   Returns: [task, task, ...]"
  (let [tasks []]
    (var position 0)
    (each [line (string.gmatch content "[^\n]+")]
      (let [task (M.parse-line line)]
        (when task
          (set position (+ position 1))
          (set task.position position)
          (table.insert tasks task))))
    tasks))

;;; ============================================================================
;;; Owner Resolution
;;; ============================================================================

(fn M.resolve-owner-mention [mention]
  "Resolve an @mention to a member UUID
   Returns: member-id (string) or nil"
  (when mention
    (let [member (members.find-by-name mention)]
      (when member
        member.id))))

(fn M.resolve-owner-id [member-id]
  "Resolve a member UUID to display name
   Returns: display name (string) or the original ID"
  (if member-id
      (members.resolve-name member-id)
      nil))

(fn M.resolve-task-owners [task]
  "Resolve owner mentions to IDs and vice versa for a task
   Mutates the task table to include resolved owner_ids
   Returns: the modified task"
  ;; If we have a mention but no owner_ids, resolve it
  (when (and task.owner_mention
             (or (not task.owner_ids) (= (length task.owner_ids) 0)))
    (let [owner-id (M.resolve-owner-mention task.owner_mention)]
      (when owner-id
        (set task.owner_ids [owner-id]))))
  task)

(fn M.get-current-user-id []
  "Get the current authenticated user's ID
   Returns: user ID or nil"
  (let [result (members.get-current)]
    (when result.ok
      result.data.id)))

;;; ============================================================================
;;; Task Rendering
;;; ============================================================================

(fn format-owner-mention [task]
  "Format the owner mention for a task
   Returns: ' @mention' or empty string"
  (let [cfg (config.get)]
    (if (not cfg.tasks.show_owners)
        ""
        ;; Try to get owner mention
        (if task.owner_mention
            (.. " @" task.owner_mention)
            ;; Try to resolve from owner_ids
            (let [owner-ids (nil-safe task.owner_ids)]
              (if (and owner-ids (> (length owner-ids) 0))
                  (let [first-owner (. owner-ids 1)
                        member (members.find-by-id first-owner)]
                    (if (and member member.profile
                             (nil-safe member.profile.mention_name))
                        (.. " @" member.profile.mention_name)
                        (if (and member member.profile
                                 (nil-safe member.profile.name))
                            (.. " @" (string.gsub member.profile.name " " "_"))
                            "")))
                  ""))))))

(fn M.render-task [task]
  "Render a single task as a markdown checkbox line
   Returns: string like '- [x] Task description <!-- task:123 @owner complete:true -->'"
  (let [checkbox (if task.complete "[x]" "[ ]")
        owner-part (format-owner-mention task)
        id-part (if task.id
                    (tostring task.id)
                    "new")
        complete-str (if task.complete "true" "false")
        metadata (string.format "<!-- task:%s%s complete:%s -->"
                                id-part
                                owner-part
                                complete-str)]
    (string.format "- %s %s %s" checkbox task.description metadata)))

(fn M.render-tasks [tasks]
  "Render a list of tasks as markdown lines
   Returns: string with newline-separated task lines"
  (if (or (not tasks) (= (length tasks) 0))
      ""
      (let [lines []]
        ;; Sort by position if available
        (table.sort tasks (fn [a b]
                            (< (or a.position 0) (or b.position 0))))
        (each [_ task (ipairs tasks)]
          (table.insert lines (M.render-task task)))
        (table.concat lines "\n"))))

(fn M.render-section [tasks]
  "Render tasks as a complete sync section with markers
   Returns: string with sync markers wrapping the tasks"
  (let [cfg (config.get)
        start-marker (string.gsub cfg.sync_start_marker "{section}" "tasks")
        end-marker (string.gsub cfg.sync_end_marker "{section}" "tasks")
        content (M.render-tasks tasks)]
    (.. start-marker "\n" content "\n" end-marker)))

;;; ============================================================================
;;; API Task Formatting
;;; ============================================================================

(fn M.format-api-tasks [raw-tasks]
  "Convert raw API tasks to rendering-ready format with owner resolution
   raw-tasks: [{:id :description :complete :owner_ids :position}]
   Returns: [{:id :description :complete :is_new :owner_ids :owner_mention :position}]"
  (let [formatted []]
    (each [i task (ipairs (or raw-tasks []))]
      (let [owner-ids (nil-safe task.owner_ids [])
            owner-mention (when (and owner-ids (> (length owner-ids) 0))
                            (let [owner-name (M.resolve-owner-id (. owner-ids 1))]
                              (when owner-name
                                (string.gsub owner-name " " "_"))))]
        (table.insert formatted
                      {:id task.id
                       :description (nil-safe task.description "")
                       :complete (nil-safe task.complete false)
                       :is_new false
                       :owner_ids owner-ids
                       :owner_mention owner-mention
                       :position (nil-safe task.position i)})))
    formatted))

;;; ============================================================================
;;; Task Comparison Utilities
;;; ============================================================================

(fn M.task-changed? [local-task remote-task]
  "Check if a local task has changes compared to remote
   Returns: bool"
  ;; Compare completion state
  (if (not= local-task.complete remote-task.complete)
      true
      ;; Compare description (trim whitespace)
      (let [local-desc (string.gsub (or local-task.description "") "^%s*(.-)%s*$" "%1")
            remote-desc (string.gsub (or remote-task.description "") "^%s*(.-)%s*$" "%1")]
        (not= local-desc remote-desc))))

(fn M.find-task-by-id [tasks id]
  "Find a task in a list by its ID
   Returns: task or nil"
  (var found nil)
  (each [_ task (ipairs tasks) &until found]
    (when (= task.id id)
      (set found task)))
  found)

(fn M.tasks-equal? [a b]
  "Check if two task lists are semantically equal
   Returns: bool"
  (if (not= (length a) (length b))
      false
      (do
        (var equal true)
        (each [i task-a (ipairs a) &until (not equal)]
          (let [task-b (. b i)]
            (when (or (not task-b)
                      (not= task-a.id task-b.id)
                      (not= task-a.complete task-b.complete)
                      (not= task-a.description task-b.description))
              (set equal false))))
        equal)))

M
