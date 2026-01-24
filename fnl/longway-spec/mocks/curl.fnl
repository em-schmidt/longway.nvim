;; Mock for plenary.curl
;; Intercepts HTTP requests for testing

(local M {})

;; State
(var response nil)
(var calls [])
(var response-queue [])

(fn M.reset []
  "Reset mock state"
  (set response nil)
  (set calls [])
  (set response-queue []))

(fn M.setup-response [resp]
  "Set the next response to return"
  (set response resp))

(fn M.queue-response [resp]
  "Queue a response (for multiple sequential calls)"
  (table.insert response-queue resp))

(fn M.get-response []
  "Get the next response (from queue or default)"
  (if (> (length response-queue) 0)
      (table.remove response-queue 1)
      response))

(fn M.request [opts]
  "Mock HTTP request - records call and returns configured response"
  (table.insert calls opts)
  (let [resp (M.get-response)]
    (or resp {:status 200 :body "{}"})))

(fn M.get [url opts]
  "Mock GET request"
  (M.request (vim.tbl_extend :force (or opts {}) {:url url :method "GET"})))

(fn M.post [url opts]
  "Mock POST request"
  (M.request (vim.tbl_extend :force (or opts {}) {:url url :method "POST"})))

(fn M.put [url opts]
  "Mock PUT request"
  (M.request (vim.tbl_extend :force (or opts {}) {:url url :method "PUT"})))

(fn M.delete [url opts]
  "Mock DELETE request"
  (M.request (vim.tbl_extend :force (or opts {}) {:url url :method "DELETE"})))

(fn M.last-call []
  "Get the most recent call"
  (. calls (length calls)))

(fn M.call-count []
  "Get total number of calls"
  (length calls))

(fn M.get-calls []
  "Get all recorded calls"
  calls)

(fn M.has-header [call header-name]
  "Check if a call included a specific header"
  (when (and call call.headers)
    (each [_ h (ipairs call.headers)]
      (when (string.find h header-name 1 true)
        (lua "return true"))))
  false)

(fn M.get-header [call header-name]
  "Get value of a specific header from a call"
  (when (and call call.headers)
    (each [_ h (ipairs call.headers)]
      (let [pattern (.. header-name ":%s*(.+)")]
        (let [value (string.match h pattern)]
          (when value
            (lua "return value"))))))
  nil)

M
