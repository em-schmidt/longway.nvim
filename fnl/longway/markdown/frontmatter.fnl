;; YAML frontmatter handling for longway.nvim

(local M {})

(fn serialize-value [value indent]
  "Serialize a Lua value to YAML string"
  (let [indent (or indent 0)
        spaces (string.rep "  " indent)]
    (if (= (type value) "string")
        (if (or (string.find value "\n")
                (string.find value ":")
                (string.find value "\"")
                (string.find value "'"))
            (.. "\"" (string.gsub value "\"" "\\\"") "\"")
            (if (string.match value "^%d+$")
                (.. "\"" value "\"")  ;; Quote numeric strings
                value))
        (= (type value) "number")
        (tostring value)
        (= (type value) "boolean")
        (if value "true" "false")
        (= (type value) "nil")
        "null"
        (= (type value) "table")
        (if (vim.islist value)
            ;; Array
            (let [items []]
              (each [_ v (ipairs value)]
                (table.insert items (.. "\n" spaces "  - " (serialize-value v (+ indent 1)))))
              (table.concat items ""))
            ;; Object
            (let [items []]
              (each [k v (pairs value)]
                (let [key (tostring k)]
                  (if (= (type v) "table")
                      (table.insert items (.. "\n" spaces "  " key ":" (serialize-value v (+ indent 1))))
                      (table.insert items (.. "\n" spaces "  " key ": " (serialize-value v (+ indent 1)))))))
              (table.concat items "")))
        ;; Fallback
        (tostring value))))

(fn M.generate [data]
  "Generate YAML frontmatter from a table"
  (let [lines ["---"]]
    (each [key value (pairs data)]
      (let [k (tostring key)]
        ;; Skip internal fields starting with _
        (when (not (string.match k "^_"))
          (if (= (type value) "table")
              (if (vim.islist value)
                  (do
                    (table.insert lines (.. k ":"))
                    (each [_ v (ipairs value)]
                      (if (= (type v) "table")
                          (do
                            (table.insert lines "  -")
                            (each [ik iv (pairs v)]
                              (table.insert lines (.. "    " (tostring ik) ": " (serialize-value iv 2)))))
                          (table.insert lines (.. "  - " (serialize-value v 1))))))
                  (do
                    (table.insert lines (.. k ":"))
                    (each [ik iv (pairs value)]
                      (table.insert lines (.. "  " (tostring ik) ": " (serialize-value iv 1))))))
              (table.insert lines (.. k ": " (serialize-value value 0)))))))
    (table.insert lines "---")
    (table.concat lines "\n")))

(fn parse-yaml-value [str]
  "Parse a YAML value string into Lua value"
  (let [trimmed (string.gsub str "^%s*(.-)%s*$" "%1")]
    (if (= trimmed "true") true
        (= trimmed "false") false
        (= trimmed "null") nil
        (= trimmed "~") nil
        ;; Quoted string
        (string.match trimmed "^\"(.*)\"$")
        (string.gsub (string.match trimmed "^\"(.*)\"$") "\\\"" "\"")
        (string.match trimmed "^'(.*)'$")
        (string.match trimmed "^'(.*)'$")
        ;; Number
        (tonumber trimmed)
        (tonumber trimmed)
        ;; Plain string
        trimmed)))

(fn M.parse [content]
  "Parse YAML frontmatter from markdown content
   Returns: {:frontmatter table :body string :raw_frontmatter string}"
  (let [start-pattern "^%-%-%-\n"
        end-pattern "\n%-%-%-\n"
        start-match (string.find content start-pattern)]
    (if (not= start-match 1)
        {:frontmatter {} :body content :raw_frontmatter nil}
        (let [end-start (string.find content end-pattern 4)]
          (if (not end-start)
              {:frontmatter {} :body content :raw_frontmatter nil}
              (let [yaml-content (string.sub content 5 (- end-start 1))
                    body (string.sub content (+ end-start 5))
                    frontmatter {}
                    current-key nil
                    current-list nil
                    current-obj nil
                    indent-stack []]
                ;; Simple line-by-line YAML parser
                (each [line (string.gmatch (.. yaml-content "\n") "([^\n]*)\n")]
                  (let [key-value (string.match line "^([%w_]+):%s*(.*)$")
                        list-item (string.match line "^%s*%-%s*(.*)$")
                        nested-kv (string.match line "^%s+([%w_]+):%s*(.*)$")]
                    (if key-value
                        (let [(k v) (string.match line "^([%w_]+):%s*(.*)$")]
                          (if (= v "")
                              (do
                                (set current-key k)
                                (set current-list [])
                                (set current-obj nil))
                              (do
                                (when (and current-key current-list)
                                  (tset frontmatter current-key current-list))
                                (when (and current-key current-obj)
                                  (tset frontmatter current-key current-obj))
                                (set current-key nil)
                                (set current-list nil)
                                (set current-obj nil)
                                (tset frontmatter k (parse-yaml-value v)))))
                        (and list-item current-key current-list)
                        (table.insert current-list (parse-yaml-value list-item))
                        (and nested-kv current-key)
                        (let [(nk nv) (string.match line "^%s+([%w_]+):%s*(.*)$")]
                          (when (not current-obj)
                            (set current-obj {}))
                          (tset current-obj nk (parse-yaml-value nv))))))
                ;; Flush any remaining list/obj
                (when (and current-key current-list (> (length current-list) 0))
                  (tset frontmatter current-key current-list))
                (when (and current-key current-obj)
                  (tset frontmatter current-key current-obj))
                {:frontmatter frontmatter :body body :raw_frontmatter yaml-content}))))))

M
