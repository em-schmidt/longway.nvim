# Phase 5: Bidirectional Sync & Conflicts — Implementation Plan

**Goal:** Automatic sync on save, per-section change detection, and conflict resolution when both local and remote have diverged.

**Version Target:** v0.5.0

---

## Current State Assessment

Phase 4 (Comment Synchronization) is complete. The codebase has partial scaffolding for Phase 5:

| Component | Status | Location |
|-----------|--------|----------|
| Config keys for auto-push | Done | `config.fnl` (`auto_push_on_save`, `auto_push_delay`, `confirm_push`) |
| Config key for conflict strategy | Done | `config.fnl` (`conflict_strategy "prompt"`) |
| Content hashing (description) | Done | `util/hash.fnl` (`content-hash`, `has-changed`) |
| Task hashing | Done | `util/hash.fnl` (`tasks-hash`, `tasks-changed?`) |
| Comment hashing | Done | `util/hash.fnl` (`comments-hash`, `comments-changed?`) |
| Frontmatter hash fields | Done | `sync_hash`, `tasks_hash`, `comments_hash` in frontmatter |
| Frontmatter timestamps | Done | `updated_at` (remote), `local_updated_at` in frontmatter |
| Change detection / diff | **Missing** | Needs `sync/diff.fnl` |
| Conflict resolution | **Missing** | Needs `sync/resolve.fnl` |
| Auto-push autocmd | **Missing** | Needs `sync/auto.fnl` |
| Pre-push remote check | **Missing** | `push.fnl` does not check remote `updated_at` before pushing |
| `:LongwayResolve` command | **Missing** | Needs command definition |
| Enhanced `:LongwayStatus` | **Missing** | Status doesn't show sync state or conflicts |
| Test specs | **Missing** | No `diff_spec`, `resolve_spec`, or `auto_spec` files |

**Estimated scope:** ~8 files to create/modify, ~3 test spec files.

---

## Architecture Overview

### Single Source of Truth: Frontmatter

All sync state lives in the YAML frontmatter of each markdown file. **No separate state files.** The frontmatter already tracks:

```yaml
---
shortcut_id: 12345
shortcut_type: story
updated_at: "2026-01-20T14:30:00Z"     # Remote timestamp at last pull/push
local_updated_at: "2026-01-20T15:00:00Z" # When we last wrote the file
sync_hash: abc12345                      # Description hash at last sync
tasks_hash: def67890                     # Tasks hash at last sync
comments_hash: ghi11111                  # Comments hash at last sync
---
```

Phase 5 adds one new frontmatter field for conflict tracking:

```yaml
conflict_sections: ["description"]  # Sections with detected conflicts (nil when clean)
```

This keeps everything in one place — the markdown file itself is the complete record of sync state. No separate JSON files to keep in sync with the frontmatter.

### Change Detection Logic

**Local changes:** Compare current parsed content hashes against frontmatter hashes.
- Description changed? → `hash.content-hash(parsed.description) != frontmatter.sync_hash`
- Tasks changed? → `hash.tasks-hash(parsed.tasks) != frontmatter.tasks_hash`
- Comments changed? → `hash.comments-hash(parsed.comments) != frontmatter.comments_hash`

**Remote changes:** Fetch story from API, compare `story.updated_at` against `frontmatter.updated_at`.

### Data Flow

```
 Save buffer (BufWritePost)
       │
       ▼
 Debounce (auto_push_delay ms)
       │
       ▼
 ┌─────────────────────────────┐
 │  Local Change Detection     │  sync/diff.fnl
 │  (current hash vs. fm hash) │
 └────────┬────────────────────┘
          │
    local changed?
     ╱          ╲
   No            Yes
   │              │
  Skip     ┌─────▼──────────────────┐
           │  Remote Check           │  Fetch remote updated_at
           │  (API vs. fm.updated_at)│
           └─────┬──────────────────┘
                 │
          remote changed?
           ╱          ╲
         No            Yes
          │              │
    ┌─────▼─────┐  ┌────▼──────────────────────┐
    │  Push      │  │  CONFLICT                 │
    │  (normal)  │  │  Set fm.conflict_sections │
    └────────────┘  │  Notify user              │
                    └───────────────────────────┘
                          │
                    User runs :LongwayResolve
                     ╱       │        ╲
                  local   remote    manual
                    │        │         │
               Force push  Force   Insert conflict
               update fm   pull    markers in file
                           update
                           fm
```

---

## Implementation Steps

### Step 1: Create Change Detection Module

**File:** `fnl/longway/sync/diff.fnl`

Uses `util/hash.fnl` for hashing and reads frontmatter from parsed content for stored state.

**Functions to implement:**

```fennel
;;; Section-level change detection
M.detect-local-changes [parsed]
  ;; Compare current parsed content against frontmatter hashes
  ;; parsed: output of parser.parse (has .description, .tasks, .comments, .frontmatter)
  ;; Reads sync_hash, tasks_hash, comments_hash from parsed.frontmatter
  ;; Returns: {:description bool :tasks bool :comments bool}
  ;;          (true = changed)

M.detect-remote-change [frontmatter remote-updated-at]
  ;; Compare remote updated_at against frontmatter.updated_at
  ;; Returns: bool (true = remote changed)

M.classify [parsed remote-updated-at]
  ;; Full classification combining local and remote detection
  ;; Returns: {:status :clean|:local-only|:remote-only|:conflict
  ;;           :local_changes {:description bool :tasks bool :comments bool}
  ;;           :remote_changed bool}

;;; Helpers
M.compute-section-hashes [parsed]
  ;; Compute current hashes for all sections from parsed content
  ;; Returns: {:description "hash" :tasks "hash" :comments "hash"}

M.any-local-change? [parsed]
  ;; Returns true if ANY section has local changes vs. frontmatter hashes
  ;; Convenience wrapper over detect-local-changes

M.first-sync? [frontmatter]
  ;; Returns true if frontmatter has no sync_hash (never synced before)
  ;; In this case skip conflict checks — treat as initial sync
```

**Key implementation details:**
- All state comes from `parsed.frontmatter` — no external state files
- `first-sync?` checks if `sync_hash` is empty/nil (set to `""` on initial render)
- `classify` is the main entry point used by the push flow
- For first syncs, always return `:local-only` (safe to push without conflict check)

**Test file:** `fnl/longway-spec/sync/diff_spec.fnl`

**Tests:**
- First sync (empty hashes) returns `:local-only` for any local content
- No changes detected returns `:clean`
- Local-only change detected correctly (hash mismatch, same `updated_at`)
- Remote-only change detected correctly (hashes match, different `updated_at`)
- Both changed returns `:conflict`
- `compute-section-hashes` produces correct hashes matching `util/hash` functions
- Each section detected independently (description changed but tasks unchanged)
- `any-local-change?` returns true when any section differs

---

### Step 2: Create Conflict Resolution Module

**File:** `fnl/longway/sync/resolve.fnl`

Orchestrates resolution strategies. Reads/writes frontmatter for conflict state.

**Functions to implement:**

```fennel
M.resolve [strategy opts]
  ;; Main entry point — dispatches to strategy handler
  ;; strategy: "local" | "remote" | "manual"
  ;; opts: {:bufnr number}  (defaults to current buffer)
  ;; 1. Parse current buffer to get shortcut_id and frontmatter
  ;; 2. Verify conflict_sections exists in frontmatter
  ;; 3. Dispatch to resolve-local / resolve-remote / resolve-manual
  ;; Returns: {:ok bool :error string}

M.resolve-local [shortcut-id parsed bufnr]
  ;; Force push local content to Shortcut, ignoring remote changes
  ;; 1. Call push.push-story with {:force true} to bypass conflict check
  ;; 2. Clear conflict_sections from frontmatter
  ;; Returns: {:ok bool :error string}

M.resolve-remote [shortcut-id bufnr]
  ;; Force pull remote content, discarding local changes
  ;; 1. Fetch fresh story from API
  ;; 2. Re-render markdown and replace buffer contents (reuses pull logic)
  ;; 3. Frontmatter is regenerated fresh (no conflict_sections)
  ;; Returns: {:ok bool :error string}

M.resolve-manual [shortcut-id bufnr]
  ;; Insert conflict markers into the description sync section
  ;; 1. Fetch remote story description
  ;; 2. Find the description sync section in buffer
  ;; 3. Replace with conflict markers showing both versions:
  ;;    <!-- CONFLICT: Local version -->
  ;;    {local description content}
  ;;    <!-- CONFLICT: Remote version (updated 2026-01-21T10:00:00Z) -->
  ;;    {remote description content}
  ;;    <!-- END CONFLICT — edit above, then :LongwayPush to resolve -->
  ;; 4. Clear conflict_sections from frontmatter (user is now manually resolving)
  ;; Returns: {:ok bool :error string}
```

**Key implementation details:**
- `resolve-local` delegates to `push.push-story` with `{:force true}`
- `resolve-remote` delegates to `pull.refresh-current-buffer` (which regenerates frontmatter)
- `resolve-manual` only applies to the description section — tasks and comments use structured merge via their existing diff/push logic and don't need manual markers
- Conflict state is cleared from frontmatter after any resolution strategy
- `resolve` validates that the buffer actually has `conflict_sections` set before proceeding

**Test file:** `fnl/longway-spec/sync/resolve_spec.fnl`

**Tests:**
- `resolve` dispatches to correct strategy
- `resolve` errors on invalid strategy name
- `resolve` errors when buffer has no `shortcut_id`
- `resolve` errors when no conflict exists (`conflict_sections` is nil)
- `resolve-manual` inserts correct conflict markers in description section
- Conflict markers include remote timestamp for context

---

### Step 3: Integrate Change Detection into Push Flow

**File:** `fnl/longway/sync/push.fnl` (modify existing)

**Changes:**

1. Add a `check-remote-before-push` function:

```fennel
(fn check-remote-before-push [story-id parsed]
  "Check if remote has changed since last sync.
   Returns: {:ok bool :conflict bool :classification table :error string}"
  (let [diff (require :longway.sync.diff)]
    ;; Skip check on first sync
    (if (diff.first-sync? parsed.frontmatter)
        {:ok true :conflict false}
        ;; Fetch remote story to check updated_at
        (let [remote-result (stories-api.get story-id)]
          (if (not remote-result.ok)
              {:ok false :error remote-result.error}
              (let [classification (diff.classify parsed remote-result.data.updated_at)]
                {:ok true
                 :conflict (= classification.status :conflict)
                 :classification classification
                 :remote-story remote-result.data}))))))
```

2. Modify `M.push-story` to call `check-remote-before-push` at the start:
   - If `opts.force` is true, skip the check entirely (used by `resolve-local`)
   - If conflict detected:
     - Set `conflict_sections` in frontmatter listing which sections have local changes
     - Notify user: "Conflict detected — remote has changed. Use :LongwayResolve to resolve."
     - Return `{:ok false :conflict true}`

3. After successful push, update frontmatter hashes and `updated_at`:
   - This is already partially done (tasks_hash and comments_hash are updated)
   - Add: update `sync_hash` with new description hash
   - Add: update `updated_at` with the remote `updated_at` from the push response
   - Clear `conflict_sections` if present

**Test updates:** Add to existing push tests:
- Push with no prior sync_hash succeeds (first sync, no conflict check)
- Push with unchanged remote succeeds normally
- Push with changed remote sets `conflict_sections` and returns `{:conflict true}`
- Push with `{:force true}` skips conflict check
- Successful push updates `sync_hash` and `updated_at` in frontmatter

---

### Step 4: Integrate State Tracking into Pull Flow

**File:** `fnl/longway/sync/pull.fnl` (modify existing)

**Changes:**

After successful pull/refresh, the rendered markdown already includes fresh hashes via `renderer.render-story` (which calls `hash.content-hash`, `hash.tasks-hash`, `hash.comments-hash` and sets them in frontmatter). The `updated_at` from the API response is also written to frontmatter.

This means **pull already writes correct sync state** — no changes needed for basic state tracking.

However, one addition:
- In `refresh-current-buffer`, clear `conflict_sections` from frontmatter if present (a refresh is effectively "resolve remote")

---

### Step 5: Implement Auto-Push on Save

**File:** `fnl/longway/sync/auto.fnl` (new)

**Functions to implement:**

```fennel
M.setup []
  ;; Create augroup "longway_auto_push"
  ;; Register BufWritePost autocmd for *.md files in workspace dir
  ;; Autocmd callback:
  ;;   1. Check if file is in workspace dir
  ;;   2. Parse buffer to check for shortcut_id in frontmatter
  ;;   3. Debounce: cancel any pending timer, set new timer
  ;;   4. On timer fire: run push-current-buffer (includes conflict detection)

M.teardown []
  ;; Remove augroup (for config changes / plugin reload)

M.is-active []
  ;; Returns true if auto-push is currently active
```

**Key implementation details:**
- Use `vim.api.nvim_create_augroup("longway_auto_push", {clear = true})`
- Use `vim.api.nvim_create_autocmd("BufWritePost", ...)` with pattern `"*.md"`
- In the callback, verify the file path is within `config.get-workspace-dir()`
- Debounce using `vim.uv.new_timer()`:
  - Store timer per buffer (table keyed by bufnr)
  - On each save: stop existing timer for that buffer, start new one with `auto_push_delay`
  - On timer fire: call `push.push-current-buffer()`
- **Loop prevention:** After a pull/refresh writes the buffer, the BufWritePost fires. To avoid immediately pushing back:
  - Check `diff.any-local-change?(parsed)` before pushing — if hashes match frontmatter, skip (the pull just wrote those hashes)
  - This is free since the pull sets hashes matching the content it wrote
- Conflict during auto-push: notify user, do not auto-resolve

**Test file:** `fnl/longway-spec/sync/auto_spec.fnl`

**Tests:**
- Auto-push is not set up when `auto_push_on_save` is false
- `setup` creates augroup
- `teardown` removes augroup
- `is-active` returns correct state
- Non-longway markdown files are ignored (no shortcut_id)

---

### Step 6: Add `:LongwayResolve` Command and Enhance `:LongwayStatus`

**File:** `plugin/longway.lua` (modify existing)

**New command:**

```lua
vim.api.nvim_create_user_command('LongwayResolve', function(opts)
  local strategy = opts.args
  if strategy == '' then
    vim.notify('[longway] Usage: :LongwayResolve <local|remote|manual>', vim.log.levels.ERROR)
    return
  end
  require('longway').resolve(strategy)
end, {
  nargs = 1,
  complete = function()
    return { 'local', 'remote', 'manual' }
  end,
  desc = 'Resolve sync conflict (local, remote, or manual)',
})
```

**File:** `fnl/longway/core.fnl` (modify existing)

Add `M.resolve`:

```fennel
(fn M.resolve [strategy]
  "Resolve a sync conflict using the given strategy"
  (if (not (config.is-configured))
      (notify.no-token)
      (let [resolve-mod (require :longway.sync.resolve)]
        (resolve-mod.resolve strategy {}))))
```

Enhance `M.status` to show conflict info:

```fennel
;; After existing status output:
(when fm.conflict_sections
  (notify.warn (string.format "CONFLICT in: %s — resolve with :LongwayResolve <local|remote|manual>"
                              (table.concat fm.conflict_sections ", "))))
```

**File:** `fnl/longway/init.fnl` (modify existing)

```fennel
;; Expose Phase 5 functions
(set M.resolve core.resolve)

;; In M.setup, wire auto-push:
(when (. (config.get) :auto_push_on_save)
  (let [auto (require :longway.sync.auto)]
    (auto.setup)))
```

---

## Implementation Order

```
Step 1: sync/diff.fnl            ← Foundation: change detection from frontmatter
   │
   ├──► Step 3: push.fnl mods    ← Pre-push conflict check + state update
   │
   ├──► Step 4: pull.fnl mods    ← Clear conflict_sections on refresh
   │
   ▼
Step 2: sync/resolve.fnl         ← Uses diff, delegates to push/pull
   │
   ▼
Step 5: sync/auto.fnl            ← Uses push (which uses diff)
   │
   ▼
Step 6: Commands & Status         ← Wires everything together
```

Steps 3 and 4 can be done in parallel after Step 1. Tests should be written alongside each step.

---

## New Files Summary

| File | Type | Description |
|------|------|-------------|
| `fnl/longway/sync/diff.fnl` | New | Section-level change detection using frontmatter hashes |
| `fnl/longway/sync/resolve.fnl` | New | Conflict resolution strategies (local/remote/manual) |
| `fnl/longway/sync/auto.fnl` | New | Auto-push on save with debounce |
| `fnl/longway-spec/sync/diff_spec.fnl` | New | Change detection tests |
| `fnl/longway-spec/sync/resolve_spec.fnl` | New | Conflict resolution tests |
| `fnl/longway-spec/sync/auto_spec.fnl` | New | Auto-push tests |

## Modified Files Summary

| File | Changes |
|------|---------|
| `fnl/longway/sync/push.fnl` | Add pre-push conflict check, `force` option, update `sync_hash`/`updated_at` |
| `fnl/longway/sync/pull.fnl` | Clear `conflict_sections` on refresh |
| `fnl/longway/core.fnl` | Add `M.resolve`, enhance `M.status` with conflict info |
| `fnl/longway/init.fnl` | Expose `resolve`, wire auto-push setup |
| `plugin/longway.lua` | Add `:LongwayResolve` command |

## Frontmatter Changes

One new field added to frontmatter:

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `conflict_sections` | list or nil | nil | Sections with unresolved conflicts (e.g., `["description"]`) |

Existing fields used for change detection (no changes):

| Field | Purpose in Phase 5 |
|-------|---------------------|
| `sync_hash` | Baseline description hash — compared against current to detect local edits |
| `tasks_hash` | Baseline tasks hash — compared against current to detect local edits |
| `comments_hash` | Baseline comments hash — compared against current to detect local edits |
| `updated_at` | Remote timestamp — compared against API to detect remote changes |

---

## Config Keys Used (Already Defined)

All config keys needed for Phase 5 are already defined in `config.fnl`:

| Key | Default | Purpose |
|-----|---------|---------|
| `auto_push_on_save` | `false` | Enable auto-push on BufWritePost |
| `auto_push_delay` | `2000` | Debounce delay in milliseconds |
| `confirm_push` | `false` | Prompt before pushing (manual push) |
| `conflict_strategy` | `"prompt"` | Default conflict handling strategy |

No config changes needed.

---

## Phase 5 Deliverables

- [ ] Change detection via frontmatter hashes (no separate state files)
- [ ] Pre-push conflict detection (compares local hashes + remote `updated_at`)
- [ ] Conflict notification with `conflict_sections` tracked in frontmatter
- [ ] `:LongwayResolve local` — Force push local content
- [ ] `:LongwayResolve remote` — Force pull remote content
- [ ] `:LongwayResolve manual` — Insert conflict markers for manual resolution
- [ ] `:LongwayStatus` enhanced to show conflict info
- [ ] Auto-push on save (opt-in, debounced, conflict-aware)
- [ ] Comprehensive test coverage for all new modules
