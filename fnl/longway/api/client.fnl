;; HTTP client wrapper for Shortcut API

(local curl (require :plenary.curl))
(local config (require :longway.config))
(local notify (require :longway.ui.notify))

(local M {})

;; Base URL for Shortcut API
(local BASE_URL "https://api.app.shortcut.com/api/v3")

(fn build-headers []
  "Build request headers with authentication"
  (let [token (config.get-token)]
    {"Content-Type" "application/json"
     "Shortcut-Token" token}))

(fn handle-response [response]
  "Process API response and handle errors"
  (let [status response.status
        body response.body]
    (if (and (>= status 200) (< status 300))
        ;; Success
        (if (and body (> (length body) 0))
            {:ok true :data (vim.json.decode body)}
            {:ok true :data nil})
        ;; Error
        (let [error-msg (if (and body (> (length body) 0))
                            (let [(ok err-data) (pcall vim.json.decode body)]
                              (if ok
                                  (or err-data.message err-data.error body)
                                  body))
                            (string.format "HTTP %d" status))]
          {:ok false :status status :error error-msg}))))

(fn M.request [method endpoint opts]
  "Make an API request to Shortcut"
  (let [token (config.get-token)]
    (if (not token)
        (do
          (notify.no-token)
          {:ok false :error "No API token configured"})
        ;; Make the request
        (let [url (.. BASE_URL endpoint)
              headers (build-headers)
              request-opts {:url url
                            :method method
                            :headers headers
                            :timeout 30000}]
          ;; Add body for POST/PUT requests
          (when (and opts opts.body)
            (set request-opts.body (vim.json.encode opts.body)))

          ;; Add query params for GET requests
          (when (and opts opts.query)
            (set request-opts.query opts.query))

          (notify.debug (string.format "API %s %s" method endpoint))

          (let [(ok response) (pcall curl.request request-opts)]
            (if ok
                (handle-response response)
                {:ok false :error (tostring response)}))))))

(fn M.get [endpoint opts]
  "Make a GET request"
  (M.request "get" endpoint opts))

(fn M.post [endpoint opts]
  "Make a POST request"
  (M.request "post" endpoint opts))

(fn M.put [endpoint opts]
  "Make a PUT request"
  (M.request "put" endpoint opts))

(fn M.delete [endpoint opts]
  "Make a DELETE request"
  (M.request "delete" endpoint opts))

M
