;; Configuration module for longway.nvim

(local M {})

;; Default configuration
(local default-config
  {;; Authentication
   :token nil
   :token_file nil

   ;; Workspace
   :workspace_dir (vim.fn.expand "~/shortcut")
   :stories_subdir "stories"
   :epics_subdir "epics"

   ;; File format
   :filename_template "{id}-{slug}"
   :slug_max_length 50
   :slug_separator "-"

   ;; Sync markers
   :sync_start_marker "<!-- BEGIN SHORTCUT SYNC:{section} -->"
   :sync_end_marker "<!-- END SHORTCUT SYNC:{section} -->"

   ;; Section sync toggles
   :sync_sections {:description true
                   :tasks true
                   :comments true}

   ;; Task sync options
   :tasks {:show_owners true
           :confirm_delete true
           :auto_assign_on_complete false}

   ;; Comment sync options
   :comments {:max_pull 50
              :show_timestamps true
              :timestamp_format "%Y-%m-%d %H:%M"
              :confirm_delete true}

   ;; Sync behavior
   :auto_push_on_save false
   :auto_push_delay 2000
   :confirm_push false
   :pull_on_open false

   ;; Conflict handling
   :conflict_strategy "prompt"

   ;; Filter presets
   :presets {}
   :default_preset nil

   ;; Rate limiting
   :rate_limit {:requests_per_minute 180
                :retry_delay_base 1000
                :max_retries 3}

   ;; UI
   :notify true
   :notify_level vim.log.levels.INFO
   :progress true

   ;; Snacks picker
   :picker {:layout "default"
            :preview true
            :icons true}

   ;; Debug
   :debug false
   :log_file nil})

;; Current configuration state (initialized with defaults so plugin works without setup())
(var config (vim.deepcopy default-config))

(fn read-token-file [path]
  "Read token from file, returns nil if file doesn't exist or is unreadable"
  (let [expanded (vim.fn.expand path)
        exists (= (vim.fn.filereadable expanded) 1)]
    (when exists
      (let [lines (vim.fn.readfile expanded)]
        (when (> (length lines) 0)
          (string.gsub (. lines 1) "%s+" ""))))))

(fn resolve-token [opts]
  "Resolve API token from config, file, or environment variable"
  ;; Priority: opts.token > opts.token_file > env var > default token_file
  (or opts.token
      (when opts.token_file (read-token-file opts.token_file))
      (os.getenv "SHORTCUT_API_TOKEN")
      (read-token-file "~/.config/longway/token")))

(fn validate-config [cfg]
  "Validate configuration, returns [ok errors] tuple"
  (let [errors []]
    ;; Check for token
    (when (not cfg._resolved_token)
      (table.insert errors "No API token found. Set SHORTCUT_API_TOKEN env var, token in config, or create ~/.config/longway/token"))

    ;; Check workspace_dir is set
    (when (or (not cfg.workspace_dir) (= cfg.workspace_dir ""))
      (table.insert errors "workspace_dir must be set"))

    ;; Return validation result
    (if (= (length errors) 0)
        [true nil]
        [false errors])))

(fn M.setup [opts]
  "Setup the plugin with user configuration"
  (let [opts (or opts {})
        merged (vim.tbl_deep_extend :force default-config opts)
        token (resolve-token opts)]
    ;; Store resolved token separately (not in user-visible config)
    (set merged._resolved_token token)
    (set config merged)

    ;; Validate in debug mode
    (when config.debug
      (let [[ok errors] (validate-config config)]
        (when (not ok)
          (each [_ err (ipairs errors)]
            (vim.notify (.. "[longway] Config warning: " err) vim.log.levels.WARN)))))

    config))

(fn M.get []
  "Get current configuration"
  config)

(fn M.get-token []
  "Get the resolved API token"
  config._resolved_token)

(fn M.get-workspace-dir []
  "Get the expanded workspace directory path"
  (vim.fn.expand config.workspace_dir))

(fn M.get-stories-dir []
  "Get the full path to stories directory"
  (.. (M.get-workspace-dir) "/" config.stories_subdir))

(fn M.get-epics-dir []
  "Get the full path to epics directory"
  (.. (M.get-workspace-dir) "/" config.epics_subdir))

(fn M.validate []
  "Validate current configuration"
  (validate-config config))

(fn M.is-configured []
  "Check if plugin is properly configured with a token"
  (not (not config._resolved_token)))

(fn M.get-preset [name]
  "Get a preset by name
   Returns: preset table or nil"
  (when (and config.presets name)
    (. config.presets name)))

(fn M.get-presets []
  "Get all configured presets
   Returns: table of name -> preset"
  (or config.presets {}))

(fn M.get-default-preset []
  "Get the default preset name
   Returns: string or nil"
  config.default_preset)

(fn M.get-cache-dir []
  "Get the cache directory path"
  (.. (M.get-workspace-dir) "/.longway/cache"))

(fn M.get-state-dir []
  "Get the sync state directory path"
  (.. (M.get-workspace-dir) "/.longway/state"))

M
