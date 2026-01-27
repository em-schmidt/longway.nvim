# Phase 6: UI Polish — Implementation Plan

**Goal:** Snacks picker integration for story/epic/preset/comment discovery, progress indicators for bulk operations, notification improvements, and statusline integration.

**Version Target:** v0.6.0

---

## Current State Assessment

Phase 5 (Bidirectional Sync & Conflicts) is complete. The codebase has partial scaffolding for Phase 6:

| Component | Status | Location |
|-----------|--------|----------|
| Config key `picker` (layout, preview, icons) | Defined, unused | `config.fnl` line 65 |
| Config key `progress` (bool) | Defined, unused | `config.fnl` line 62 |
| Config key `notify` / `notify_level` | Done, working | `config.fnl`, `ui/notify.fnl` |
| Notification module | Done (basic `vim.notify`) | `ui/notify.fnl` |
| Confirmation module | Done (`vim.ui.select`) | `ui/confirm.fnl` |
| Story search API | Done (paginated) | `api/search.fnl` |
| Epic API (list, get, stats) | Done | `api/epics.fnl` |
| Members API (cached) | Done | `api/members.fnl` |
| Workflows API (cached) | Done | `api/workflows.fnl` |
| Markdown renderer | Done | `markdown/renderer.fnl` |
| Bulk sync with loop | Done, no per-item progress | `sync/pull.fnl` lines 169–207 |
| Picker module | **Missing** | Needs `ui/picker.fnl` |
| Progress module | **Missing** | Needs `ui/progress.fnl` |
| Statusline module | **Missing** | Needs `ui/statusline.fnl` |
| `:LongwayPicker` command | **Missing** | Needs command in `plugin/longway.lua` |
| Test specs | **Missing** | No `picker_spec`, `progress_spec`, `statusline_spec` files |

**Estimated scope:** ~5 new files, ~6 modified files, ~3 test spec files.

---

## Architecture Overview

### Dependency: snacks.nvim

Phase 6 uses `folke/snacks.nvim` as an **optional** runtime dependency. The picker (`:LongwayPicker`) and enhanced notifications require it, but all other functionality works without it — notifications fall back to `vim.notify`.

snacks.nvim provides:
- `Snacks.picker` — Fuzzy finder with custom sources, formatters, previewers, and actions
- `Snacks.notify` — Replaceable notification system with persistent IDs (for progress updates)

### Module Layout

```
fnl/longway/ui/
├── notify.fnl       # Existing — enhanced with Snacks.notify + progress IDs
├── confirm.fnl      # Existing — no changes
├── picker.fnl       # NEW — Snacks picker sources for stories/epics/presets/modified/comments
├── progress.fnl     # NEW — Progress tracking for bulk operations
└── statusline.fnl   # NEW — Statusline component API for lualine/etc.
```

### Data Flow

```
:LongwayPicker stories
       │
       ▼
  ui/picker.fnl
       │
       ├── finder: api/search.fnl (search-stories-all)
       │           api/epics.fnl (list)
       │           config.fnl (get-presets)
       │           sync/diff.fnl (detect-local-changes)
       │
       ├── format: Item → [{id, "Comment"}, {" "}, {name, "String"}, {state, "Type"}]
       │
       ├── preview: markdown/renderer.fnl → set preview buffer lines + ft=markdown
       │
       └── confirm: Open story file (edit path) or pull if not local
```

```
:LongwaySync owner:me
       │
       ▼
  sync/pull.fnl (sync-stories)
       │
       ├── Before loop: progress.start(total)
       │
       ├── Each item: progress.update(i, total, story.name)
       │              → Snacks.notify with id="longway_progress" (in-place update)
       │
       └── After loop: progress.finish(synced, failed)
```

---

## Implementation Steps

### Step 1: Create Progress Tracking Module

**File:** `fnl/longway/ui/progress.fnl` (new)

Progress tracking for bulk sync operations. Uses `Snacks.notify` with a stable notification ID to update the same notification in-place, or falls back to `vim.notify` if snacks is unavailable.

**Functions to implement:**

```fennel
M.start [operation total]
  ;; Initialize a progress notification
  ;; operation: string like "Syncing" or "Pushing"
  ;; total: number of items
  ;; Shows: "[longway] Syncing: 0/{total}..."
  ;; Uses Snacks.notify with id="longway_progress_{operation}" for in-place updates
  ;; Falls back to vim.notify if snacks unavailable
  ;; Returns: progress-id (string) for subsequent update/finish calls

M.update [progress-id current total item-name]
  ;; Update the progress notification in-place
  ;; progress-id: returned from start()
  ;; current: current item number (1-indexed)
  ;; total: total items
  ;; item-name: optional name of current item (e.g., story name)
  ;; Shows: "[longway] Syncing: {current}/{total} — {item-name}"
  ;; Only updates if config.progress is true

M.finish [progress-id synced failed]
  ;; Complete the progress notification
  ;; Replaces the in-place notification with final summary
  ;; Shows: "[longway] Sync complete: {synced} synced, {failed} failed"
  ;; Sets timeout to auto-dismiss after 3 seconds

M.is-available []
  ;; Returns true if Snacks.notify is available for in-place progress
  ;; Used to decide between rich progress and simple notifications
```

**Key implementation details:**
- Use `pcall(require, "snacks")` to detect snacks.nvim availability
- If snacks is available, use `Snacks.notify(msg, {id = progress_id, title = "longway"})` for in-place updates
- If snacks is unavailable, fall back to `vim.notify` (each update is a new notification — acceptable degradation)
- Respect `config.progress` flag — if false, suppress intermediate updates (only show start/finish)
- Progress IDs are scoped per operation to allow concurrent progress tracking (unlikely but safe)

**Test file:** `fnl/longway-spec/ui/progress_spec.fnl`

**Tests:**
- `start` returns a progress ID string
- `update` does not error when snacks is unavailable
- `finish` produces correct summary message
- `is-available` returns false when snacks is not loaded
- Progress is suppressed when `config.progress` is false
- Multiple concurrent progress operations don't interfere

---

### Step 2: Create Snacks Picker Module

**File:** `fnl/longway/ui/picker.fnl` (new)

Central picker module with custom sources for stories, epics, presets, modified files, and comments. Each source is a function that calls `Snacks.picker` with the appropriate finder, format, preview, and confirm functions.

**Functions to implement:**

```fennel
;;; ---- Source: Stories ----

M.pick-stories [opts]
  ;; Open a Snacks picker for stories
  ;; opts: {:query string  -- search query (optional, uses default preset)
  ;;        :preset string  -- preset name (optional)}
  ;;
  ;; Finder:
  ;;   1. Determine query from opts.query, opts.preset, or config.default_preset
  ;;   2. Call search-api.search-stories-all(query) to get story list
  ;;   3. Map each story to a picker item:
  ;;      {:text "{id} {name} [{state}] @{owner}"
  ;;       :id story.id
  ;;       :name story.name
  ;;       :state (resolve workflow state name)
  ;;       :story_type story.story_type
  ;;       :owners (resolve owner names)
  ;;       :estimate story.estimate
  ;;       :epic_name (resolve epic name if available)
  ;;       :file (local filepath if already pulled, nil otherwise)}
  ;;
  ;; Format:
  ;;   [{story.id, "Number"},  {" "}, {story.name, "Title"},
  ;;    {" ["..state.."]", "Type"}, {" @"..owner, "Comment"}]
  ;;
  ;; Preview:
  ;;   If local file exists → load and display file content (ft=markdown)
  ;;   If no local file → render story via renderer.render-story and display
  ;;
  ;; Confirm:
  ;;   If local file exists → open it (vim.cmd "edit {path}")
  ;;   If no local file → pull story, then open

;;; ---- Source: Epics ----

M.pick-epics [opts]
  ;; Open a Snacks picker for epics
  ;; opts: {} (no filters — epics API doesn't support search)
  ;;
  ;; Finder:
  ;;   1. Call epics-api.list() to get all epics
  ;;   2. Map each epic to a picker item:
  ;;      {:text "{id} {name} [{state}]"
  ;;       :id epic.id
  ;;       :name epic.name
  ;;       :state epic.state
  ;;       :stats epic.stats
  ;;       :file (local filepath if already pulled, nil otherwise)}
  ;;
  ;; Format:
  ;;   [{epic.id, "Number"}, {" "}, {epic.name, "Title"},
  ;;    {" ["..state.."]", "Type"},
  ;;    {" ("..done.."/"..total.." stories)", "Comment"}]
  ;;
  ;; Preview:
  ;;   If local file exists → display file content
  ;;   If no local file → render epic via renderer.render-epic and display
  ;;
  ;; Confirm:
  ;;   If local file exists → open it
  ;;   If no local file → pull epic, then open

;;; ---- Source: Presets ----

M.pick-presets []
  ;; Open a Snacks picker for configured presets
  ;;
  ;; Items: (static, from config)
  ;;   Map each preset to:
  ;;   {:text "{name}: {description}"
  ;;    :name preset-name
  ;;    :query preset.query
  ;;    :description preset.description
  ;;    :is_default (= name config.default_preset)}
  ;;
  ;; Format:
  ;;   [{name, "Title"}, {" — "..description, "Comment"},
  ;;    (when is_default) {" (default)", "Special"}]
  ;;
  ;; Confirm:
  ;;   Run sync with selected preset: core.sync(preset-name)

;;; ---- Source: Modified ----

M.pick-modified [opts]
  ;; Open a Snacks picker for locally modified (pending push) files
  ;;
  ;; Finder:
  ;;   1. Glob for *.md files in workspace_dir (stories/ and epics/)
  ;;   2. For each file:
  ;;      a. Read and parse frontmatter
  ;;      b. Skip files without shortcut_id
  ;;      c. Check diff.any-local-change?(parsed) — skip if unchanged
  ;;      d. Check diff.detect-local-changes(parsed) — get changed sections
  ;;   3. Build items from modified files:
  ;;      {:text "{id} {title} — {changed_sections}"
  ;;       :file filepath
  ;;       :id frontmatter.shortcut_id
  ;;       :name (extracted from H1 or frontmatter)
  ;;       :changed_sections ["description", "tasks", ...]
  ;;       :has_conflict (frontmatter.conflict_sections ~= nil)}
  ;;
  ;; Format:
  ;;   [{id, "Number"}, {" "}, {name, "Title"},
  ;;    {" ("..sections..")", "WarningMsg"},
  ;;    (when has_conflict) {" CONFLICT", "ErrorMsg"}]
  ;;
  ;; Actions:
  ;;   <CR> (confirm) → Open file
  ;;   <C-p> (custom) → Push selected file
  ;;   <C-a> (custom) → Push all modified files (batch push)
  ;;
  ;; Preview:
  ;;   Display the file content (ft=markdown)

;;; ---- Source: Comments ----

M.pick-comments [opts]
  ;; Open a Snacks picker for comments on the current story
  ;; opts: {:bufnr number} (defaults to current buffer)
  ;;
  ;; Finder:
  ;;   1. Parse current buffer to get shortcut_id
  ;;   2. Fetch comments from API: comments-api.list(story_id)
  ;;   3. Map each comment to a picker item:
  ;;      {:text "{author} — {first_line_of_text}"
  ;;       :id comment.id
  ;;       :author (resolve member name)
  ;;       :created_at comment.created_at
  ;;       :body comment.text}
  ;;
  ;; Format:
  ;;   [{author, "Title"}, {" · "..timestamp, "Comment"},
  ;;    {" — "..first_line, "Normal"}]
  ;;
  ;; Preview:
  ;;   Display full comment body (ft=markdown)
  ;;
  ;; Confirm:
  ;;   Jump to comment position in the current buffer (search for comment:{id})

;;; ---- Helpers ----

M.check-snacks []
  ;; Check if snacks.nvim is available
  ;; Returns: bool
  ;; Shows error notification if not available

(fn find-local-file [shortcut-id shortcut-type])
  ;; Search workspace for existing markdown file matching shortcut_id
  ;; Uses vim.fn.glob to search stories/ and epics/ directories
  ;; Reads frontmatter to match shortcut_id
  ;; Returns: filepath or nil

(fn resolve-state-name [workflow-state-id])
  ;; Look up workflow state name from cached workflows
  ;; Returns: state name string or "Unknown"

(fn build-picker-layout [])
  ;; Build layout config from user config.picker settings
  ;; Returns: snacks layout table
```

**Key implementation details:**
- All sources use `Snacks.picker` (or `Snacks.picker.pick`) — never Telescope
- Guard every picker call with `M.check-snacks()` — show a clear error if snacks.nvim is not installed
- Finder functions fetch data via existing API modules (no new API calls needed)
- `find-local-file` uses `vim.fn.glob` to find files matching `{id}-*.md` in the workspace, then reads frontmatter to confirm the `shortcut_id` matches — this avoids maintaining a separate index
- Preview renders markdown content in the preview buffer with `vim.bo[ctx.buf].filetype = "markdown"` for syntax highlighting
- Layout respects `config.picker.layout` (maps to snacks preset name) and `config.picker.preview` (toggles preview pane)
- For the stories picker, workflow state names are resolved from the cached workflows data (via `workflows.list-cached()`)
- Owner names are resolved from cached members (via `members.resolve-name()`)
- The modified files picker performs local-only checks (no API calls) — it reads files from disk and computes hashes

**Test file:** `fnl/longway-spec/ui/picker_spec.fnl`

**Tests:**
- `check-snacks` returns false when snacks is not loaded
- `find-local-file` finds existing file by shortcut_id
- `find-local-file` returns nil when file doesn't exist
- Picker item formatting produces correct highlight structure
- Stories finder maps API response to expected item fields
- Epics finder maps API response to expected item fields
- Presets source builds items from config
- Modified files source correctly detects changed files
- Modified files source skips files without shortcut_id
- Comments finder maps API response to expected item fields

---

### Step 3: Integrate Progress Into Bulk Operations

**File:** `fnl/longway/sync/pull.fnl` (modify existing)

**Changes to `M.sync-stories`:**

The current implementation (lines 169–207) has a simple loop with no per-item feedback. Add progress tracking:

```fennel
;; Before the loop:
(let [progress (require :longway.ui.progress)
      progress-id (progress.start "Syncing" total)]

  ;; Inside the loop (after each pull-story call):
  (progress.update progress-id i total (or story.name (tostring story.id)))

  ;; After the loop:
  (progress.finish progress-id synced failed))
```

This replaces the current `(notify.info (string.format "Found %d stories to sync" total))` and `(notify.info (string.format "Sync complete: %d synced, %d failed" synced failed))` calls with the progress module equivalents.

**Changes to `M.sync-all-presets`:**

Add top-level progress across presets:

```fennel
;; Before the preset loop:
(let [progress (require :longway.ui.progress)
      preset-names (vim.tbl_keys presets)
      progress-id (progress.start "Syncing presets" (length preset-names))]

  ;; Inside the loop:
  (progress.update progress-id i (length preset-names) name)

  ;; After the loop:
  (progress.finish progress-id (length preset-names) 0))
```

**No changes to push.fnl** — push operates on a single buffer and doesn't need progress tracking.

---

### Step 4: Enhance Notification Module

**File:** `fnl/longway/ui/notify.fnl` (modify existing)

**Changes:**

1. Add snacks.nvim integration with fallback:

```fennel
(fn snacks-available? []
  "Check if Snacks.notify is available"
  (let [(ok _) (pcall require :snacks)]
    ok))

(fn M.notify [msg level opts]
  "Send a notification with optional snacks.nvim integration
   opts: {:id string :title string :timeout number} (optional, for snacks)"
  (let [cfg (config.get)
        level (or level vim.log.levels.INFO)]
    (when cfg.notify
      (when (>= level (or cfg.notify_level vim.log.levels.INFO))
        (if (and opts (snacks-available?))
            ;; Use Snacks.notify for rich features (in-place updates, titles)
            (let [Snacks (require :snacks)
                  snacks-opts (vim.tbl_extend :force
                                {:title "longway"} (or opts {}))]
              (Snacks.notify (.. "[longway] " msg) snacks-opts))
            ;; Fallback to vim.notify
            (vim.notify (.. "[longway] " msg) level))))))
```

2. Add new notification helpers for Phase 6:

```fennel
M.picker-error [msg]
  ;; "snacks.nvim is required for :LongwayPicker. Install folke/snacks.nvim"

M.push-batch-completed [synced failed]
  ;; Summary notification for batch push operations
```

**Important:** The existing `M.notify` signature changes from `(msg level)` to `(msg level opts)`. The `opts` parameter is optional and backward-compatible — all existing callers pass only `msg` and `level`, so they continue to work unchanged.

---

### Step 5: Create Statusline Module

**File:** `fnl/longway/ui/statusline.fnl` (new)

Provides functions that statusline plugins (lualine, heirline, etc.) can call to display longway sync state. Does not directly integrate with any specific statusline plugin — instead, exposes a simple API that users wire into their statusline config.

**Functions to implement:**

```fennel
M.get-status []
  ;; Returns a status string for the current buffer, or nil if not a longway file
  ;; Designed to be called frequently (every statusline render), so must be fast
  ;;
  ;; Logic:
  ;;   1. Get current buffer content (cached — see below)
  ;;   2. Parse frontmatter for shortcut_id → nil if not a longway file
  ;;   3. Check conflict_sections → return "CONFLICT" indicator
  ;;   4. Check local changes (hash comparison) → return "modified" indicator
  ;;   5. If synced (hashes match) → return "synced" indicator
  ;;
  ;; Returns: string like "SC:12345 [synced]" or "SC:12345 [modified]" or "SC:12345 [CONFLICT]"
  ;; Returns: nil for non-longway buffers (statusline should hide component)

M.get-status-data []
  ;; Returns structured data instead of formatted string
  ;; For users who want custom formatting
  ;;
  ;; Returns: {:shortcut_id number
  ;;           :shortcut_type string
  ;;           :state string (workflow state name)
  ;;           :sync_status "synced"|"modified"|"conflict"
  ;;           :changed_sections ["description" "tasks"] (list of locally changed sections)
  ;;           :conflict_sections ["description"] or nil}
  ;; Returns: nil for non-longway buffers

M.is-longway-buffer []
  ;; Fast check: is the current buffer a longway-managed file?
  ;; Checks buffer variable (b:longway_id) first, falls back to frontmatter parse
  ;; Returns: bool

M.lualine-component []
  ;; Returns a table compatible with lualine's component API
  ;; Usage in lualine config:
  ;;   lualine_x = { require("longway.ui.statusline").lualine_component() }
  ;;
  ;; Returns: {function, cond, color_fn}
  ;;   function: returns the status string
  ;;   cond: returns true only for longway buffers
  ;;   color: changes based on sync_status (green=synced, yellow=modified, red=conflict)
```

**Key implementation details:**
- **Performance:** Statusline functions are called on every render (~50ms intervals). Avoid parsing the entire buffer on every call:
  - On `BufEnter` and `BufWritePost`, parse frontmatter and store results in buffer variables (`vim.b.longway_id`, `vim.b.longway_sync_status`, etc.)
  - `get-status` reads from buffer variables (fast) and only re-parses on cache miss
  - Register autocmds in `M.setup()` to refresh buffer variables
- **Buffer variable caching:**
  - `vim.b.longway_id` — shortcut_id (set on BufEnter, nil for non-longway files)
  - `vim.b.longway_sync_status` — "synced" | "modified" | "conflict" (updated on BufWritePost)
  - `vim.b.longway_state` — workflow state name
- The `lualine-component` function returns a table that lualine can use directly — no lualine dependency, just follows lualine's expected interface `{1 = fn, cond = fn, color = fn}`

**Test file:** `fnl/longway-spec/ui/statusline_spec.fnl`

**Tests:**
- `is-longway-buffer` returns false for non-markdown buffers
- `get-status` returns nil for non-longway buffers
- `get-status` returns correct string for synced file
- `get-status` returns "modified" indicator when hashes differ
- `get-status` returns "CONFLICT" indicator when conflict_sections is set
- `get-status-data` returns structured table with expected fields
- `lualine-component` returns table with function and cond fields

---

### Step 6: Wire Commands and Entry Points

**File:** `plugin/longway.lua` (modify existing)

**New command:**

```lua
-- Phase 6: Picker command
vim.api.nvim_create_user_command('LongwayPicker', function(opts)
  local source = opts.args
  if source == '' then
    vim.notify('[longway] Usage: :LongwayPicker <stories|epics|presets|modified|comments>', vim.log.levels.ERROR)
    return
  end
  require('longway').picker(source)
end, {
  nargs = 1,
  complete = function()
    return { 'stories', 'epics', 'presets', 'modified', 'comments' }
  end,
  desc = 'Open Snacks picker (stories, epics, presets, modified, comments)',
})
```

**File:** `fnl/longway/core.fnl` (modify existing)

Add `M.picker`:

```fennel
(fn M.picker [source opts]
  "Open a Snacks picker for the given source type
   source: 'stories' | 'epics' | 'presets' | 'modified' | 'comments'"
  (if (not (config.is-configured))
      (notify.no-token)
      (let [picker (require :longway.ui.picker)]
        (if (not (picker.check-snacks))
            nil ;; check-snacks already notified the user
            (match source
              :stories (picker.pick-stories (or opts {}))
              :epics (picker.pick-epics (or opts {}))
              :presets (picker.pick-presets)
              :modified (picker.pick-modified (or opts {}))
              :comments (picker.pick-comments (or opts {}))
              _ (notify.error (string.format "Unknown picker source: %s" source)))))))
```

**File:** `fnl/longway/init.fnl` (modify existing)

```fennel
;; Expose Phase 6 functions
(set M.picker core.picker)

;; In M.setup, wire statusline autocmds:
(let [statusline (require :longway.ui.statusline)]
  (statusline.setup))
```

---

## Implementation Order

```
Step 1: ui/progress.fnl           ← Foundation: progress tracking with snacks fallback
   │
   ▼
Step 2: ui/picker.fnl             ← Core feature: all 5 picker sources
   │
   ├──► Step 3: pull.fnl mods    ← Integrate progress into bulk sync
   │
   ▼
Step 4: ui/notify.fnl mods        ← Snacks.notify integration + new helpers
   │
   ▼
Step 5: ui/statusline.fnl         ← Statusline component API
   │
   ▼
Step 6: Commands & wiring         ← Connect everything together
```

Steps 1 and 5 are independent and can be done in parallel. Step 2 depends on Step 1 (uses progress for the modified files scanner). Step 3 depends on Steps 1 and 2. Step 4 can be done any time. Step 6 depends on all others.

Tests should be written alongside each step.

---

## New Files Summary

| File | Type | Description |
|------|------|-------------|
| `fnl/longway/ui/picker.fnl` | New | Snacks picker sources (stories, epics, presets, modified, comments) |
| `fnl/longway/ui/progress.fnl` | New | Progress tracking for bulk operations with Snacks.notify |
| `fnl/longway/ui/statusline.fnl` | New | Statusline component API with buffer-variable caching |
| `fnl/longway-spec/ui/picker_spec.fnl` | New | Picker tests (item building, formatting, file lookup) |
| `fnl/longway-spec/ui/progress_spec.fnl` | New | Progress module tests |
| `fnl/longway-spec/ui/statusline_spec.fnl` | New | Statusline module tests |

## Modified Files Summary

| File | Changes |
|------|---------|
| `fnl/longway/ui/notify.fnl` | Add Snacks.notify integration with fallback, add `opts` parameter, new helpers |
| `fnl/longway/sync/pull.fnl` | Integrate progress.start/update/finish into sync-stories and sync-all-presets |
| `fnl/longway/core.fnl` | Add `M.picker` function dispatching to picker sources |
| `fnl/longway/init.fnl` | Expose `picker`, wire statusline setup |
| `plugin/longway.lua` | Add `:LongwayPicker` command with completion |
| `CLAUDE.md` | Update architecture section, add Phase 6 docs reference |

---

## Snacks Picker Item Schema

Each picker source builds items conforming to this interface:

```lua
-- snacks.picker.Item (extended with longway-specific fields)
{
  text = string,          -- REQUIRED: searchable/filterable text
  idx = number,           -- item index for ordering
  -- Custom fields (used by format/preview/confirm):
  id = number,            -- shortcut_id
  name = string,          -- story/epic/preset name
  state = string,         -- workflow state name (resolved)
  story_type = string,    -- "feature" | "bug" | "chore"
  owners = string,        -- comma-separated owner names
  estimate = number,      -- story points
  file = string|nil,      -- local filepath (nil if not yet pulled)
  preview = {             -- inline preview data
    text = string,        -- rendered markdown content
    ft = "markdown",      -- filetype for syntax highlighting
  },
}
```

---

## Picker Layouts

The picker respects `config.picker.layout` which maps to snacks layout presets:

| Config Value | Snacks Preset | Description |
|-------------|---------------|-------------|
| `"default"` | `"default"` | Horizontal split: list left, preview right |
| `"vertical"` | `"vertical"` | Vertical split: list top, preview bottom |
| `"dropdown"` | `"dropdown"` | Dropdown from top of screen |
| `"ivy"` | `"ivy"` | Bottom panel (Ivy-style) |
| `"telescope"` | `"telescope"` | Telescope-like centered float |

When `config.picker.preview` is false, the preview pane is hidden.

---

## Config Keys Used (Already Defined)

All config keys needed for Phase 6 are already defined in `config.fnl`:

| Key | Default | Purpose |
|-----|---------|---------|
| `progress` | `true` | Enable per-item progress during bulk operations |
| `picker.layout` | `"default"` | Snacks picker layout preset |
| `picker.preview` | `true` | Show preview pane in pickers |
| `picker.icons` | `true` | Show icons in picker items (reserved for future use) |
| `notify` | `true` | Enable notifications |
| `notify_level` | `vim.log.levels.INFO` | Minimum notification level |

No config schema changes needed.

---

## Statusline Integration Examples

### lualine.nvim

```lua
-- In lualine config:
require("lualine").setup({
  sections = {
    lualine_x = {
      require("longway.ui.statusline").lualine_component(),
    },
  },
})
```

### Custom statusline

```lua
-- In statusline expression:
local longway = require("longway.ui.statusline")
if longway.is_longway_buffer() then
  local status = longway.get_status()
  -- status = "SC:12345 [synced]" or "SC:12345 [modified]" or nil
end
```

### Structured data

```lua
local data = require("longway.ui.statusline").get_status_data()
-- data = {
--   shortcut_id = 12345,
--   shortcut_type = "story",
--   state = "In Progress",
--   sync_status = "modified",
--   changed_sections = {"description", "tasks"},
--   conflict_sections = nil,
-- }
```

---

## Phase 6 Deliverables

- [ ] `:LongwayPicker stories` — Browse and open stories via fuzzy finder
- [ ] `:LongwayPicker epics` — Browse and open epics via fuzzy finder
- [ ] `:LongwayPicker presets` — Select and run a sync preset
- [ ] `:LongwayPicker modified` — View locally modified files, push from picker
- [ ] `:LongwayPicker comments` — Browse comments on current story
- [ ] Progress indicators during bulk sync operations (in-place notification updates)
- [ ] Snacks.notify integration with fallback to vim.notify
- [ ] Statusline component API for lualine and custom statuslines
- [ ] Buffer-variable caching for fast statusline rendering
- [ ] Comprehensive test coverage for all new modules
