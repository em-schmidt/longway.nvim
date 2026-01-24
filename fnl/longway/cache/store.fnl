;; Cache module for longway.nvim
;; Stores reference data (members, workflows, iterations, teams) with TTL support

(local config (require :longway.config))
(local notify (require :longway.ui.notify))

(local M {})

;; Default TTL in seconds (1 hour)
(local DEFAULT_TTL 3600)

;; Cache types and their TTLs
(local CACHE_TYPES
  {:members 3600      ;; 1 hour
   :workflows 86400   ;; 24 hours (rarely change)
   :iterations 3600   ;; 1 hour
   :teams 3600        ;; 1 hour
   :labels 3600       ;; 1 hour
   :projects 3600})   ;; 1 hour

(fn get-cache-dir []
  "Get the cache directory path"
  (.. (config.get-workspace-dir) "/.longway/cache"))

(fn get-cache-path [cache-type]
  "Get the full path for a cache file"
  (.. (get-cache-dir) "/" cache-type ".json"))

(fn ensure-cache-dir []
  "Ensure the cache directory exists"
  (let [cache-dir (get-cache-dir)]
    (when (not= (vim.fn.isdirectory cache-dir) 1)
      (vim.fn.mkdir cache-dir "p"))))

(fn read-json-file [path]
  "Read and parse a JSON file, returns nil on error"
  (when (= (vim.fn.filereadable path) 1)
    (let [content (vim.fn.readfile path)
          text (table.concat content "\n")]
      (when (> (length text) 0)
        (let [ok data (pcall vim.json.decode text)]
          (when ok data))))))

(fn write-json-file [path data]
  "Write data as JSON to a file"
  (ensure-cache-dir)
  (let [ok json (pcall vim.json.encode data)]
    (when ok
      (vim.fn.writefile [(json)] path)
      true)))

(fn is-expired [cache-entry ttl]
  "Check if a cache entry has expired"
  (if (not cache-entry)
      true
      (not cache-entry.timestamp)
      true
      (let [now (os.time)
            age (- now cache-entry.timestamp)
            effective-ttl (or ttl (. CACHE_TYPES cache-entry.type) DEFAULT_TTL)]
        (> age effective-ttl))))

(fn M.get [cache-type]
  "Get cached data if valid, returns nil if expired or missing
   Returns: {:ok bool :data value :expired bool}"
  (let [path (get-cache-path cache-type)
        cache-entry (read-json-file path)]
    (if (not cache-entry)
        {:ok false :data nil :expired true}
        (is-expired cache-entry (. CACHE_TYPES cache-type))
        {:ok true :data cache-entry.data :expired true}
        {:ok true :data cache-entry.data :expired false})))

(fn M.set [cache-type data]
  "Store data in cache with timestamp
   Returns: {:ok bool :error string}"
  (let [cache-entry {:type cache-type
                     :timestamp (os.time)
                     :data data}
        path (get-cache-path cache-type)
        ok (write-json-file path cache-entry)]
    (if ok
        {:ok true}
        {:ok false :error "Failed to write cache file"})))

(fn M.invalidate [cache-type]
  "Invalidate (delete) a specific cache
   Returns: {:ok bool}"
  (let [path (get-cache-path cache-type)]
    (when (= (vim.fn.filereadable path) 1)
      (vim.fn.delete path))
    {:ok true}))

(fn M.invalidate-all []
  "Invalidate all caches
   Returns: {:ok bool}"
  (each [cache-type _ (pairs CACHE_TYPES)]
    (M.invalidate cache-type))
  {:ok true})

(fn M.get-or-fetch [cache-type fetch-fn]
  "Get from cache or fetch using provided function if expired
   fetch-fn: function that returns {:ok bool :data value :error string}
   Returns: {:ok bool :data value :error string :from-cache bool}"
  (let [cached (M.get cache-type)]
    (if (and cached.ok (not cached.expired))
        ;; Valid cache hit
        {:ok true :data cached.data :from-cache true}
        ;; Need to fetch
        (let [result (fetch-fn)]
          (if result.ok
              (do
                (M.set cache-type result.data)
                {:ok true :data result.data :from-cache false})
              ;; Fetch failed, return stale cache if available
              (if (and cached.ok cached.data)
                  (do
                    (notify.debug "Using stale cache due to fetch failure")
                    {:ok true :data cached.data :from-cache true :stale true})
                  result))))))

(fn M.get-age [cache-type]
  "Get the age of a cache entry in seconds, returns nil if not cached"
  (let [path (get-cache-path cache-type)
        cache-entry (read-json-file path)]
    (when (and cache-entry cache-entry.timestamp)
      (- (os.time) cache-entry.timestamp))))

(fn M.get-status []
  "Get status of all caches
   Returns: table with cache-type -> {:exists bool :age number :expired bool}"
  (let [status {}]
    (each [cache-type ttl (pairs CACHE_TYPES)]
      (let [path (get-cache-path cache-type)
            cache-entry (read-json-file path)]
        (tset status cache-type
              (if (not cache-entry)
                  {:exists false :age nil :expired true}
                  (let [age (- (os.time) (or cache-entry.timestamp 0))]
                    {:exists true
                     :age age
                     :expired (> age ttl)})))))
    status))

(fn M.refresh [cache-type fetch-fn]
  "Force refresh a cache, ignoring expiry
   Returns: {:ok bool :data value :error string}"
  (let [result (fetch-fn)]
    (when result.ok
      (M.set cache-type result.data))
    result))

M
