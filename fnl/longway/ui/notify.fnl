;; Notification helpers for longway.nvim

(local config (require :longway.config))

(local M {})

;; Notification levels
(set M.levels {:debug vim.log.levels.DEBUG
               :info vim.log.levels.INFO
               :warn vim.log.levels.WARN
               :error vim.log.levels.ERROR})

(fn snacks-available? []
  "Check if Snacks.notify is available"
  (let [(ok snacks) (pcall require :snacks)]
    (and ok (not= snacks nil) (not= snacks.notify nil))))

(fn M.notify [msg level opts]
  "Send a notification if notifications are enabled.
   opts: {:id string :title string :timeout number} (optional, for snacks)"
  (let [cfg (config.get)
        level (or level vim.log.levels.INFO)]
    (when cfg.notify
      (when (>= level (or cfg.notify_level vim.log.levels.INFO))
        (if (and opts (snacks-available?))
            ;; Use Snacks.notify for rich features (in-place updates, titles)
            (let [Snacks (require :snacks)
                  snacks-opts (vim.tbl_extend :force
                                {:title "longway"} opts)]
              (Snacks.notify (.. "[longway] " msg) snacks-opts))
            ;; Fallback to vim.notify
            (vim.notify (.. "[longway] " msg) level))))))

(fn M.debug [msg]
  "Send a debug notification"
  (let [cfg (config.get)]
    (when cfg.debug
      (M.notify msg vim.log.levels.DEBUG))))

(fn M.info [msg]
  "Send an info notification"
  (M.notify msg vim.log.levels.INFO))

(fn M.warn [msg]
  "Send a warning notification"
  (M.notify msg vim.log.levels.WARN))

(fn M.error [msg]
  "Send an error notification"
  (M.notify msg vim.log.levels.ERROR))

(fn M.success [msg]
  "Send a success notification (info level with checkmark)"
  (M.info msg))

(fn M.sync-started [count]
  "Notify that sync has started"
  (if (= count 1)
      (M.info "Syncing 1 item...")
      (M.info (string.format "Syncing %d items..." count))))

(fn M.sync-completed [count]
  "Notify that sync has completed"
  (if (= count 1)
      (M.success "Synced 1 item")
      (M.success (string.format "Synced %d items" count))))

(fn M.push-started []
  "Notify that push has started"
  (M.info "Pushing changes to Shortcut..."))

(fn M.push-completed []
  "Notify that push has completed"
  (M.success "Changes pushed to Shortcut"))

(fn M.pull-started [id]
  "Notify that pull has started"
  (M.info (string.format "Pulling story %s from Shortcut..." (tostring id))))

(fn M.pull-completed [id name]
  "Notify that pull has completed"
  (M.success (string.format "Pulled: %s" (or name (tostring id)))))

(fn M.conflict-detected [id]
  "Notify that a conflict was detected"
  (M.warn (string.format "Conflict detected for story %s. Use :LongwayResolve to resolve." (tostring id))))

(fn M.api-error [msg status]
  "Notify about an API error"
  (if status
      (M.error (string.format "API error (%d): %s" status msg))
      (M.error (string.format "API error: %s" msg))))

(fn M.no-token []
  "Notify that no API token is configured"
  (M.error "No Shortcut API token configured. Set SHORTCUT_API_TOKEN or configure token in setup()"))

(fn M.picker-error []
  "Notify that snacks.nvim is required for picker"
  (M.error "snacks.nvim is required for :LongwayPicker. Install folke/snacks.nvim"))

M
