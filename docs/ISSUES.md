
# Current Issues/TODOs:

- [x] `:LongwayPicker presets` and `:LongwaySync` both throw the following error
    E5108: Error executing lua: Vim:E117: Unknown function: ref
stack traceback:
        [C]: in function 'ref'
        ...rs/eric/workspace/longway.nvim/lua/longway/sync/pull.lua:201: in function 'fn'
        ...ic/.local/share/nvim/lazy/snacks.nvim/lua/snacks/win.lua:362: in function <...ic/.local/share/nvim/lazy/snacks.nvim/lua/snacks/win.lua:357>
  - Fixed: sync/pull.fnl sync-stories used non-existent vim.fn.ref and vim.fn.setreg/getreg for counters; replaced with simple Lua variables

- [x] Automatic story sync for default preset only shows initial progress '[longway] Syncing: 0/100..', no stories sync, no progress updates happen.
  - Fixed: caused by the vim.fn.ref crash above — the sync loop never executed; resolved by same fix
  - Fixed: added vim.cmd.redraw after progress.update to force screen refresh during synchronous sync loop
  - Fixed: pull-story now accepts {:silent true} opts to suppress per-story "Pulling..."/"Pulled:" notifications during bulk sync; progress bar is the single notification source

- [x] `:LongwayRefresh` overwrites and or removes Local Notes

- [x] Picking an epic in the `:LongwayPicker epics` thows
    E5108: Error executing lua: vim/_editor.lua:0: nvim_exec2(), line 1: Vim(edit):E37: No write since last change (add ! to override)
stack traceback:
        [C]: in function 'nvim_exec2'
        vim/_editor.lua: in function 'fn'
        ...ic/.local/share/nvim/lazy/snacks.nvim/lua/snacks/win.lua:362: in function <...ic/.local/share/nvim/lazy/snacks.nvim/lua/snacks/win.lua:357>

- [x] Epic progress doesn't show total stories: example:

    ```markdown

    # GitHub Migration PoC

    **Progress:** 5/0 stories done (0%)

    ```

    This epic contains 15 stores, but shows 5/0 done
  - Fixed: code read `stats.num_stories` (nonexistent) instead of `stats.num_stories_total` from the Shortcut API; corrected in epics.fnl, renderer.fnl, picker.fnl, and test helpers

# Completed Issues/TODOs:

- [x] Comments created in markdown are not syncing to shortcut, no errors are produced.
  - Fixed: parser.fnl now delegates to comments-md.parse-section (single source of truth)
  - Fixed: parse-section now warns when content exists but no comments were parsed (format guidance)
- [x] vim.NIL present in several key fields. See story YAML front matter and epic status tables.
  - Fixed: frontmatter.fnl serialize-value and generate now detect and omit vim.NIL (userdata)
  - Fixed: renderer.fnl nil-safe helper applied to all API fields in story/epic frontmatter, stats, and stories table
  - Fixed: tasks.fnl nil-safe helper applied to format-api-tasks and format-owner-mention

