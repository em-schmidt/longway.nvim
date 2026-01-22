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

M
