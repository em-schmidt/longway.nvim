;; Slug generation utilities for longway.nvim

(local config (require :longway.config))

(local M {})

(fn M.sanitize [text]
  "Sanitize text for use in filenames"
  (-> text
      ;; Convert to lowercase
      (string.lower)
      ;; Replace spaces and underscores with separator
      (string.gsub "[%s_]+" "-")
      ;; Remove non-alphanumeric characters (except hyphens)
      (string.gsub "[^%w%-]" "")
      ;; Collapse multiple hyphens
      (string.gsub "%-+" "-")
      ;; Remove leading/trailing hyphens
      (string.gsub "^%-+" "")
      (string.gsub "%-+$" "")))

(fn M.truncate [text max-length]
  "Truncate text to max length, breaking at word boundaries"
  (if (<= (length text) max-length)
      text
      ;; Find last hyphen before max-length
      (let [truncated (string.sub text 1 max-length)
            last-hyphen (string.find truncated "%-[^%-]*$")]
        (if last-hyphen
            (string.sub truncated 1 (- last-hyphen 1))
            truncated))))

(fn M.generate [title]
  "Generate a slug from a title using config settings"
  (let [cfg (config.get)
        max-length (or cfg.slug_max_length 50)
        sanitized (M.sanitize title)]
    (M.truncate sanitized max-length)))

(fn M.make-filename [id title type]
  "Generate a filename for a story or epic"
  (let [cfg (config.get)
        slug (M.generate title)
        template (or cfg.filename_template "{id}-{slug}")]
    (-> template
        (string.gsub "{id}" (tostring id))
        (string.gsub "{slug}" slug)
        (string.gsub "{type}" (or type "story"))
        (.. ".md"))))

M
