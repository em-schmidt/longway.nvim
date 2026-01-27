
# Current Issues/TODOs:

- [x] Comments created in markdown are not syncing to shortcut, no errors are produced.
  - Fixed: parser.fnl now delegates to comments-md.parse-section (single source of truth)
  - Fixed: parse-section now warns when content exists but no comments were parsed (format guidance)
- [x] vim.NIL present in several key fields. See story YAML front matter and epic status tables.
  - Fixed: frontmatter.fnl serialize-value and generate now detect and omit vim.NIL (userdata)
  - Fixed: renderer.fnl nil-safe helper applied to all API fields in story/epic frontmatter, stats, and stories table
  - Fixed: tasks.fnl nil-safe helper applied to format-api-tasks and format-owner-mention
