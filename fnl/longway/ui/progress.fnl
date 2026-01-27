;; Progress tracking for longway.nvim
;; Provides in-place notification updates for bulk operations.
;; Uses Snacks.notify when available, falls back to vim.notify.

(local config (require :longway.config))

(local M {})

;; Track active progress notifications
(var active-progress {})

(fn snacks-available? []
  "Check if Snacks.notify is available"
  (let [(ok snacks) (pcall require :snacks)]
    (and ok (not= snacks nil) (not= snacks.notify nil))))

(fn M.is-available []
  "Returns true if Snacks.notify is available for in-place progress"
  (snacks-available?))

(fn M.start [operation total]
  "Initialize a progress notification.
   operation: string like 'Syncing' or 'Pushing'
   total: number of items
   Returns: progress-id (string) for subsequent update/finish calls"
  (let [progress-id (.. "longway_progress_" operation)
        msg (string.format "%s: 0/%d..." operation total)
        cfg (config.get)]
    ;; Store state
    (tset active-progress progress-id {:operation operation
                                        :total total
                                        :current 0})
    (when cfg.notify
      (if (snacks-available?)
          (let [Snacks (require :snacks)]
            (Snacks.notify (.. "[longway] " msg)
                           {:id progress-id
                            :title "longway"
                            :level vim.log.levels.INFO}))
          (vim.notify (.. "[longway] " msg) vim.log.levels.INFO)))
    progress-id))

(fn M.update [progress-id current total item-name]
  "Update the progress notification in-place.
   progress-id: returned from start()
   current: current item number (1-indexed)
   total: total items
   item-name: optional name of current item"
  (let [cfg (config.get)]
    (when (and cfg.notify cfg.progress)
      (let [state (. active-progress progress-id)
            operation (if state state.operation "Working")
            msg (if item-name
                    (string.format "%s: %d/%d — %s" operation current total item-name)
                    (string.format "%s: %d/%d..." operation current total))]
        ;; Update stored state
        (when state
          (tset state :current current))
        (if (snacks-available?)
            (let [Snacks (require :snacks)]
              (Snacks.notify (.. "[longway] " msg)
                             {:id progress-id
                              :title "longway"
                              :level vim.log.levels.INFO}))
            ;; Fallback: only log every 5th item to avoid notification spam
            (when (or (= current 1)
                      (= current total)
                      (= (% current 5) 0))
              (vim.notify (.. "[longway] " msg) vim.log.levels.INFO)))))))

(fn M.finish [progress-id synced failed]
  "Complete the progress notification.
   Replaces the in-place notification with final summary."
  (let [cfg (config.get)
        state (. active-progress progress-id)
        operation (if state state.operation "Operation")
        msg (if (and failed (> failed 0))
                (string.format "%s complete: %d synced, %d failed" operation synced failed)
                (string.format "%s complete: %d synced" operation synced))]
    ;; Clean up state
    (tset active-progress progress-id nil)
    (when cfg.notify
      (if (snacks-available?)
          (let [Snacks (require :snacks)]
            (Snacks.notify (.. "[longway] " msg)
                           {:id progress-id
                            :title "longway"
                            :level vim.log.levels.INFO
                            :timeout 3000}))
          (vim.notify (.. "[longway] " msg) vim.log.levels.INFO)))))

M
