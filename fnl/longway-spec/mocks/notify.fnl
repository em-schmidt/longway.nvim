;; Mock for notification system
;; Captures notifications for testing

(local M {})

;; State
(var notifications [])

(fn M.reset []
  "Reset mock state"
  (set notifications []))

(fn M.notify [message level]
  "Mock notification - records message and level"
  (table.insert notifications {:message message :level level}))

(fn M.last-notification []
  "Get the most recent notification"
  (. notifications (length notifications)))

(fn M.notification-count []
  "Get total number of notifications"
  (length notifications))

(fn M.get-notifications []
  "Get all recorded notifications"
  notifications)

(fn M.has-notification-with [substring]
  "Check if any notification contains the given substring"
  (each [_ n (ipairs notifications)]
    (when (string.find n.message substring 1 true)
      (lua "return true")))
  false)

(fn M.get-notifications-by-level [level]
  "Get all notifications of a specific level"
  (let [results []]
    (each [_ n (ipairs notifications)]
      (when (= n.level level)
        (table.insert results n)))
    results))

M
