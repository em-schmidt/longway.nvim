;; Custom assertions for longway.nvim tests
;; Extends luassert with domain-specific assertions

(local say (require :say))
(local assert (require :luassert))

;; has_substring - Check if a string contains a substring
(fn has-substring [state args]
  (let [[haystack needle] args]
    (and haystack
         needle
         (not= nil (string.find haystack needle 1 true)))))

(say:set "assertion.has_substring.positive"
         "Expected string to contain substring.\nString: %s\nSubstring: %s")
(say:set "assertion.has_substring.negative"
         "Expected string NOT to contain substring.\nString: %s\nSubstring: %s")

(assert:register "assertion" "has_substring"
                 has-substring
                 "assertion.has_substring.positive"
                 "assertion.has_substring.negative")

;; is_valid_slug - Check if a string is a valid slug
(fn is-valid-slug [state args]
  (let [[slug] args]
    (and (= (type slug) "string")
         (> (length slug) 0)
         (not (string.find slug "[^a-z0-9%-]"))
         (not (string.match slug "^%-"))
         (not (string.match slug "%-$")))))

(say:set "assertion.is_valid_slug.positive"
         "Expected '%s' to be a valid slug (lowercase alphanumeric with hyphens, no leading/trailing hyphens)")
(say:set "assertion.is_valid_slug.negative"
         "Expected '%s' NOT to be a valid slug")

(assert:register "assertion" "is_valid_slug"
                 is-valid-slug
                 "assertion.is_valid_slug.positive"
                 "assertion.is_valid_slug.negative")

;; is_valid_hash - Check if a string is a valid hex hash
(fn is-valid-hash [state args]
  (let [[hash] args]
    (and (= (type hash) "string")
         (= (length hash) 8)
         (string.match hash "^%x+$"))))

(say:set "assertion.is_valid_hash.positive"
         "Expected '%s' to be a valid 8-character hex hash")
(say:set "assertion.is_valid_hash.negative"
         "Expected '%s' NOT to be a valid hash")

(assert:register "assertion" "is_valid_hash"
                 is-valid-hash
                 "assertion.is_valid_hash.positive"
                 "assertion.is_valid_hash.negative")

;; has_frontmatter - Check if markdown has valid frontmatter
(fn has-frontmatter [state args]
  (let [[content] args]
    (and content
         (string.match content "^%-%-%-\n")
         (string.find content "\n%-%-%-\n" 4))))

(say:set "assertion.has_frontmatter.positive"
         "Expected content to have valid YAML frontmatter")
(say:set "assertion.has_frontmatter.negative"
         "Expected content NOT to have frontmatter")

(assert:register "assertion" "has_frontmatter"
                 has-frontmatter
                 "assertion.has_frontmatter.positive"
                 "assertion.has_frontmatter.negative")

;; has_sync_section - Check if content has a specific sync section
(fn has-sync-section [state args]
  (let [[content section-name] args
        start-marker (.. "<!-- BEGIN SHORTCUT SYNC:" section-name " -->")
        end-marker (.. "<!-- END SHORTCUT SYNC:" section-name " -->")]
    (and content
         (string.find content start-marker 1 true)
         (string.find content end-marker 1 true))))

(say:set "assertion.has_sync_section.positive"
         "Expected content to have sync section '%s'")
(say:set "assertion.has_sync_section.negative"
         "Expected content NOT to have sync section '%s'")

(assert:register "assertion" "has_sync_section"
                 has-sync-section
                 "assertion.has_sync_section.positive"
                 "assertion.has_sync_section.negative")

{: has-substring
 : is-valid-slug
 : is-valid-hash
 : has-frontmatter
 : has-sync-section}
