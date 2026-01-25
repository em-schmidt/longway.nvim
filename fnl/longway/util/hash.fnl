;; Content hashing utilities for longway.nvim

(local M {})

(fn M.djb2 [str]
  "Simple DJB2 hash function for strings"
  (var hash 5381)
  (for [i 1 (length str)]
    (let [c (string.byte str i)]
      (set hash (+ (* hash 33) c))
      ;; Keep hash in reasonable range using bit operations
      (set hash (% hash 0x7FFFFFFF))))
  (string.format "%08x" hash))

(fn M.content-hash [content]
  "Generate a hash for content (normalizes whitespace first)"
  (let [normalized (-> content
                       ;; Normalize line endings
                       (string.gsub "\r\n" "\n")
                       ;; Trim trailing whitespace from lines
                       (string.gsub "[ \t]+\n" "\n")
                       ;; Trim leading/trailing whitespace
                       (string.gsub "^%s+" "")
                       (string.gsub "%s+$" ""))]
    (M.djb2 normalized)))

(fn M.has-changed [old-hash new-content]
  "Check if content has changed compared to stored hash"
  (let [new-hash (M.content-hash new-content)]
    (not= old-hash new-hash)))

(fn M.tasks-hash [tasks]
  "Generate a hash for a list of tasks
   Includes: id, description, complete state
   Tasks are sorted by ID for consistent ordering"
  (if (or (not tasks) (= (length tasks) 0))
      (M.djb2 "")
      ;; Build a canonical string representation
      (let [;; Sort tasks by ID (nil IDs go first, sorted by description)
            sorted (vim.deepcopy tasks)]
        (table.sort sorted (fn [a b]
                             (if (and a.id b.id)
                                 (< a.id b.id)
                                 (if a.id false
                                     (if b.id true
                                         (< (or a.description "") (or b.description "")))))))
        ;; Build canonical string: id|description|complete for each task
        (let [parts []]
          (each [_ task (ipairs sorted)]
            (table.insert parts
                          (string.format "%s|%s|%s"
                                         (or task.id "new")
                                         (or task.description "")
                                         (if task.complete "true" "false"))))
          (M.djb2 (table.concat parts "\n"))))))

(fn M.tasks-changed? [old-hash tasks]
  "Check if tasks have changed compared to stored hash"
  (let [new-hash (M.tasks-hash tasks)]
    (not= old-hash new-hash)))

M
