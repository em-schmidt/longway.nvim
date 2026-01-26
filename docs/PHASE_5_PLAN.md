# Phase 5: Bidirectional Sync & Conflicts — Implementation Plan

**Goal:** Automatic sync on save, per-section change detection, and conflict resolution when both local and remote have diverged.

**Version Target:** v0.5.0

---

## Current State Assessment

Phase 4 (Comment Synchronization) is complete. The codebase has partial scaffolding for Phase 5:

| Component | Status | Location |
|-----------|--------|----------|
| Config keys for auto-push | Done | `config.fnl:42-44` (`auto_push_on_save`, `auto_push_delay`, `confirm_push`) |
| Config key for conflict strategy | Done | `config.fnl:48` (`conflict_strategy "prompt"`) |
| Config `get-state-dir` helper | Done | `config.fnl:176-178` (returns `.longway/state`) |
| Content hashing (description) | Done | `util/hash.fnl` (`content-hash`, `has-changed`) |
| Task hashing | Done | `util/hash.fnl` (`tasks-hash`, `tasks-changed?`) |
| Comment hashing | Done | `util/hash.fnl` (`comments-hash`, `comments-changed?`) |
| Frontmatter hash fields | Done | `sync_hash`, `tasks_hash`, `comments_hash` in frontmatter |
| Frontmatter timestamps | Done | `updated_at`, `local_updated_at` in frontmatter |
| Cache store (JSON read/write) | Done | `cache/store.fnl` (reusable patterns for JSON file I/O) |
| Sync state persistence | **Missing** | Needs `cache/state.fnl` |
| Change detection / diff | **Missing** | Needs `sync/diff.fnl` |
| Conflict resolution | **Missing** | Needs `sync/resolve.fnl` |
| Auto-push autocmd | **Missing** | Needs wiring in `init.fnl` |
| Pre-push remote check | **Missing** | `push.fnl` does not check remote `updated_at` before pushing descriptions |
| `:LongwayResolve` command | **Missing** | Needs command definition |
| Enhanced `:LongwayStatus` | **Missing** | Status doesn't show sync state or conflicts |
| Test specs | **Missing** | No `diff_spec`, `state_spec`, or `resolve_spec` files |

**Estimated scope:** ~10 files to create/modify, ~8 test spec files.

---

## Architecture Overview

### Data Flow

```
 Save buffer (BufWritePost)
       │
       ▼
 Debounce (auto_push_delay ms)
       │
       ▼
 ┌─────────────────────┐
 │  Change Detection    │  sync/diff.fnl
 │  (local vs. stored)  │
 └────────┬────────────┘
          │
    local changed?
     ╱          ╲
   No            Yes
   │              │
  Skip     ┌─────▼─────────────┐
           │  Remote Check      │  Fetch remote updated_at
           │  (stored vs. API)  │
           └─────┬─────────────┘
                 │
          remote changed?
           ╱          ╲
         No            Yes
          │              │
    ┌─────▼─────┐  ┌────▼──────────┐
    │  Push      │  │  CONFLICT     │
    │  (normal)  │  │  Notify user  │
    └────────────┘  │  Store state  │
                    └───────────────┘
                          │
                    User runs :LongwayResolve
                     ╱       │        ╲
                  local   remote    manual
                    │        │         │
               Force push  Force   Insert conflict
               update      pull    markers in file
               state       update
                           state
```

### State Storage

Per-story/epic state is stored in `.longway/state/{shortcut_id}.json`:

```json
{
  "shortcut_id": 12345,
  "shortcut_type": "story",
  "last_synced_at": 1706300000,
  "remote_updated_at": "2026-01-20T14:30:00Z",
  "sections": {
    "description": {
      "local_hash": "abc12345",
      "remote_hash": "abc12345"
    },
    "tasks": {
      "local_hash": "def67890",
      "remote_hash": "def67890"
    },
    "comments": {
      "local_hash": "ghi11111",
      "remote_hash": "ghi11111"
    }
  },
  "conflict": null
}
```

When a conflict is detected, the `conflict` field is populated:

```json
{
  "conflict": {
    "detected_at": 1706300100,
    "sections": ["description"],
    "remote_updated_at": "2026-01-21T10:00:00Z",
    "local_description_hash": "new_local",
    "remote_description": "...remote content..."
  }
}
```

---

## Implementation Steps

### Step 1: Create Sync State Module

**File:** `fnl/longway/cache/state.fnl`

**Pattern:** Mirrors `cache/store.fnl` for JSON file I/O but specialized for per-entity sync state.

**Functions to implement:**

```fennel
;;; State File I/O
M.get-state-path [shortcut-id]       ;; → ".longway/state/{id}.json"
M.load [shortcut-id]                 ;; Read state JSON, return table or nil
M.save [shortcut-id state]           ;; Write state JSON

;;; State Queries
M.get-section-hashes [shortcut-id]   ;; → {:description {:local_hash :remote_hash} ...}
M.get-remote-updated-at [shortcut-id] ;; → timestamp string or nil
M.get-conflict [shortcut-id]         ;; → conflict table or nil
M.has-conflict? [shortcut-id]        ;; → bool

;;; State Updates
M.update-after-sync [shortcut-id data]
  ;; data: {:remote_updated_at string
  ;;        :sections {:description {:local_hash :remote_hash} ...}
  ;;        :shortcut_type string}
  ;; Clears any existing conflict, updates last_synced_at

M.set-conflict [shortcut-id conflict-data]
  ;; Store conflict state for later resolution

M.clear-conflict [shortcut-id]
  ;; Clear conflict after resolution
```

**Key implementation details:**
- State files live in `{workspace}/.longway/state/` directory
- Use `vim.fn.mkdir` with `"p"` flag to ensure directory exists
- Use `vim.json.encode`/`vim.json.decode` for serialization (same as `cache/store.fnl`)
- `update-after-sync` is called at the end of every successful push/pull to snapshot the current state
- State is per-entity (one JSON file per story/epic)

**Test file:** `fnl/longway-spec/cache/state_spec.fnl`

**Tests:**
- Load returns nil for non-existent state
- Save and load round-trips correctly
- `update-after-sync` sets all fields and clears conflicts
- `set-conflict` and `clear-conflict` work correctly
- `has-conflict?` returns correct boolean

---

### Step 2: Create Change Detection Module

**File:** `fnl/longway/sync/diff.fnl`

**Pattern:** New module; uses `util/hash.fnl` for hashing and `cache/state.fnl` for stored state.

**Functions to implement:**

```fennel
;;; Section-level change detection
M.detect-local-changes [shortcut-id parsed]
  ;; Compare current parsed content against stored state
  ;; parsed: output of parser.parse (has .description, .tasks, .comments, .frontmatter)
  ;; Returns: {:description :changed|:unchanged
  ;;           :tasks :changed|:unchanged
  ;;           :comments :changed|:unchanged}

M.detect-remote-changes [shortcut-id remote-story]
  ;; Compare remote updated_at against stored state
  ;; Returns: {:changed bool :remote_updated_at string :stored_updated_at string}

M.classify-sync [shortcut-id parsed remote-story]
  ;; Full classification combining local and remote detection
  ;; Returns: {:status :clean|:local-only|:remote-only|:conflict
  ;;           :local_changes {:description bool :tasks bool :comments bool}
  ;;           :remote_changed bool
  ;;           :remote_updated_at string}

;;; Helpers
M.compute-section-hashes [parsed]
  ;; Compute hashes for all sections from parsed content
  ;; Returns: {:description "hash" :tasks "hash" :comments "hash"}

M.first-sync? [shortcut-id]
  ;; Returns true if no sync state exists (never synced before)
```

**Key implementation details:**
- For local change detection: compare current section hashes against `state.sections.{section}.local_hash`
- For remote change detection: compare `remote-story.updated_at` against `state.remote_updated_at`
- `first-sync?` returns true when no state file exists — in this case, skip conflict checks (treat as initial sync)
- `classify-sync` is the main entry point used by the push flow

**Test file:** `fnl/longway-spec/sync/diff_spec.fnl`

**Tests:**
- First sync (no state) returns `:clean` status
- No changes detected returns `:clean`
- Local-only change detected correctly
- Remote-only change detected correctly
- Both changed returns `:conflict`
- `compute-section-hashes` produces correct hashes
- Each section detected independently (description changed but tasks unchanged)

---

### Step 3: Create Conflict Resolution Module

**File:** `fnl/longway/sync/resolve.fnl`

**Pattern:** New module; orchestrates resolution strategies.

**Functions to implement:**

```fennel
M.resolve [strategy opts]
  ;; Main entry point — dispatches to strategy handler
  ;; strategy: "local" | "remote" | "manual"
  ;; opts: {:bufnr number}  (defaults to current buffer)
  ;; Returns: {:ok bool :error string}

M.resolve-local [shortcut-id parsed bufnr]
  ;; Force push local content to Shortcut, ignoring remote changes
  ;; 1. Push description, tasks, comments normally (bypassing conflict check)
  ;; 2. Update sync state with new hashes
  ;; 3. Clear conflict state
  ;; Returns: {:ok bool :error string}

M.resolve-remote [shortcut-id bufnr]
  ;; Force pull remote content, discarding local changes
  ;; 1. Fetch fresh story from API
  ;; 2. Re-render markdown and replace buffer contents
  ;; 3. Update sync state with new hashes
  ;; 4. Clear conflict state
  ;; Returns: {:ok bool :error string}

M.resolve-manual [shortcut-id conflict bufnr]
  ;; Insert conflict markers into the file for manual resolution
  ;; Only applies to description section (tasks/comments use structured merge)
  ;; Format:
  ;;   <!-- CONFLICT: Local version -->
  ;;   {local description content}
  ;;   <!-- CONFLICT: Remote version -->
  ;;   {remote description content}
  ;;   <!-- END CONFLICT -->
  ;; Returns: {:ok bool :error string}

M.get-conflict-status [shortcut-id]
  ;; Get current conflict state for display
  ;; Returns: {:has_conflict bool :sections [string] :detected_at number} or nil
```

**Key implementation details:**
- `resolve-local` reuses `push.push-story` but passes an option to skip the remote check
- `resolve-remote` reuses `pull.refresh-current-buffer` logic
- `resolve-manual` fetches remote description and inserts conflict markers around the description sync section
- After any resolution, sync state is updated and conflict is cleared
- The `resolve` entry point reads the current buffer, parses frontmatter to get `shortcut_id`, then dispatches

**Test file:** `fnl/longway-spec/sync/resolve_spec.fnl`

**Tests:**
- `resolve` dispatches to correct strategy
- `resolve` errors on invalid strategy
- `resolve` errors when buffer has no shortcut_id
- `resolve-manual` inserts correct conflict markers
- Conflict markers follow the format from PRD section 4.3
- Resolution clears conflict state

---

### Step 4: Integrate Change Detection into Push Flow

**File:** `fnl/longway/sync/push.fnl` (modify existing)

**Changes:**

1. Add a `check-remote-before-push` function:

```fennel
(fn check-remote-before-push [story-id parsed]
  "Check if remote has changed since last sync.
   Returns: {:ok bool :conflict bool :remote-story table :error string}"
  (let [diff (require :longway.sync.diff)
        state (require :longway.cache.state)]
    ;; Skip check if this is first sync (no stored state)
    (if (diff.first-sync? story-id)
        {:ok true :conflict false}
        ;; Fetch remote story to check updated_at
        (let [remote-result (stories-api.get story-id)]
          (if (not remote-result.ok)
              {:ok false :error remote-result.error}
              (let [classification (diff.classify-sync story-id parsed remote-result.data)]
                (if (= classification.status :conflict)
                    ;; Store conflict state for resolution
                    (do
                      (state.set-conflict story-id
                        {:detected_at (os.time)
                         :sections (icollect [section changed (pairs classification.local_changes)]
                                    (when changed section))
                         :remote_updated_at classification.remote_updated_at})
                      {:ok true :conflict true :classification classification})
                    {:ok true :conflict false
                     :remote-story remote-result.data
                     :classification classification})))))))
```

2. Modify `M.push-story` to call `check-remote-before-push` before proceeding:
   - If conflict detected, notify user and return `{:ok false :conflict true}`
   - Add an `opts.force` flag that skips the remote check (used by `resolve-local`)

3. After successful push, call `state.update-after-sync` to snapshot current state:

```fennel
;; At end of successful push in push-story:
(let [diff-mod (require :longway.sync.diff)
      state-mod (require :longway.cache.state)
      section-hashes (diff-mod.compute-section-hashes parsed)]
  (state-mod.update-after-sync story-id
    {:remote_updated_at (or (and results.description
                                 results.description.story
                                 results.description.story.updated_at)
                            "")
     :shortcut_type "story"
     :sections {:description {:local_hash section-hashes.description
                              :remote_hash section-hashes.description}
                :tasks {:local_hash section-hashes.tasks
                        :remote_hash section-hashes.tasks}
                :comments {:local_hash section-hashes.comments
                           :remote_hash section-hashes.comments}}}))
```

**Test file:** `fnl/longway-spec/sync/push_spec.fnl` (extend existing)

**New tests:**
- Push with no prior state succeeds (first sync, no conflict check)
- Push with unchanged remote succeeds normally
- Push with changed remote triggers conflict notification
- Push with `force: true` skips conflict check
- Successful push updates sync state

---

### Step 5: Integrate State Tracking into Pull Flow

**File:** `fnl/longway/sync/pull.fnl` (modify existing)

**Changes:**

1. After successful pull, update sync state:

```fennel
;; After writing the story file in pull-story:
(let [diff-mod (require :longway.sync.diff)
      state-mod (require :longway.cache.state)
      ;; Parse the just-written markdown to get section hashes
      parser-mod (require :longway.markdown.parser)
      parsed (parser-mod.parse markdown)
      section-hashes (diff-mod.compute-section-hashes parsed)]
  (state-mod.update-after-sync story.id
    {:remote_updated_at (or story.updated_at "")
     :shortcut_type "story"
     :sections {:description {:local_hash section-hashes.description
                              :remote_hash section-hashes.description}
                :tasks {:local_hash section-hashes.tasks
                        :remote_hash section-hashes.tasks}
                :comments {:local_hash section-hashes.comments
                           :remote_hash section-hashes.comments}}}))
```

2. Similarly update state after `refresh-current-buffer` succeeds.

**No new test file** — extend existing pull specs if they exist, or add focused state-tracking tests to `state_spec.fnl`.

---

### Step 6: Implement Auto-Push on Save

**File:** `fnl/longway/init.fnl` (modify existing)

**Changes:**

1. Add an `auto-push` module or inline the autocmd setup in `M.setup`:

```fennel
;; In M.setup, after config is set:
(when (. (config.get) :auto_push_on_save)
  (setup-auto-push))
```

2. Create a new module `fnl/longway/sync/auto.fnl`:

```fennel
M.setup []
  ;; Create augroup "longway_auto_push"
  ;; Register BufWritePost autocmd for *.md files in workspace dir
  ;; Autocmd callback:
  ;;   1. Check if file is in workspace dir
  ;;   2. Check if file has shortcut_id in frontmatter
  ;;   3. Debounce: cancel any pending timer, set new timer
  ;;   4. On timer fire: run push (which includes conflict detection)

M.teardown []
  ;; Remove augroup (for config changes / plugin reload)

M.is-active []
  ;; Returns true if auto-push is currently active
```

**Key implementation details:**
- Use `vim.api.nvim_create_augroup("longway_auto_push", {clear = true})` for clean setup
- Use `vim.api.nvim_create_autocmd("BufWritePost", ...)` with pattern matching workspace dir
- Debounce with `vim.defer_fn` — store timer reference in module-local variable
- Cancel previous timer with `vim.fn.timer_stop` if one is pending (or use `vim.uv.new_timer()` for more control)
- The autocmd callback should:
  1. Parse the buffer to verify it's a longway file (has `shortcut_id`)
  2. Schedule a deferred push via `vim.defer_fn`
  3. On push, if conflict detected, notify user but don't auto-resolve
- Must handle the case where user saves multiple times quickly (debounce resets)
- Must NOT auto-push if the buffer is the result of a pull/refresh (to avoid push-back loops) — detect this by comparing hashes immediately after pull

**Test file:** `fnl/longway-spec/sync/auto_spec.fnl`

**Tests:**
- Auto-push is not set up when `auto_push_on_save` is false
- Auto-push creates augroup when enabled
- Teardown removes the augroup
- Debounce logic: rapid saves result in single push
- Non-longway files in workspace are ignored

---

### Step 7: Add `:LongwayResolve` Command and Enhance `:LongwayStatus`

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

**Changes:**

1. Add `M.resolve` function:

```fennel
(fn M.resolve [strategy]
  "Resolve a sync conflict using the given strategy"
  (if (not (config.is-configured))
      (notify.no-token)
      (let [resolve-mod (require :longway.sync.resolve)]
        (resolve-mod.resolve strategy {}))))
```

2. Enhance `M.status` to show sync state and conflicts:

```fennel
;; After existing status output, add:
(let [state-mod (require :longway.cache.state)
      sync-state (state-mod.load fm.shortcut_id)]
  (when sync-state
    (print (string.format "Last synced: %s"
                          (if sync-state.last_synced_at
                              (os.date "%Y-%m-%d %H:%M" sync-state.last_synced_at)
                              "never")))
    (when (state-mod.has-conflict? fm.shortcut_id)
      (let [conflict (state-mod.get-conflict fm.shortcut_id)]
        (print (string.format "⚠ CONFLICT detected at %s"
                              (os.date "%Y-%m-%d %H:%M" conflict.detected_at)))
        (print (string.format "  Affected sections: %s"
                              (table.concat conflict.sections ", ")))
        (print "  Resolve with: :LongwayResolve <local|remote|manual>")))))
```

**File:** `fnl/longway/init.fnl` (modify existing)

**Changes:**

1. Expose the new `resolve` function:

```fennel
(set M.resolve core.resolve)
```

2. Wire up auto-push setup in `M.setup`:

```fennel
;; After config validation:
(when (. (config.get) :auto_push_on_save)
  (let [auto (require :longway.sync.auto)]
    (auto.setup)))
```

---

### Step 8: Write Test Specifications

Create test files for all new modules:

| Test File | Tests | Priority |
|-----------|-------|----------|
| `fnl/longway-spec/cache/state_spec.fnl` | State CRUD, round-trip, conflict tracking | High |
| `fnl/longway-spec/sync/diff_spec.fnl` | Change detection, classification | High |
| `fnl/longway-spec/sync/resolve_spec.fnl` | Resolution strategies, marker format | High |
| `fnl/longway-spec/sync/auto_spec.fnl` | Autocmd setup, debounce, teardown | Medium |

**Test approach:** Follow existing pattern from Phase 3/4 specs:
- Use `plenary.busted` (`describe`, `it`, `assert.are.same`)
- Mock API calls where needed
- Test pure functions directly (hashing, classification, marker generation)
- Test state file I/O using temp directories

---

## Implementation Order

The steps should be implemented in this order due to dependencies:

```
Step 1: cache/state.fnl          ← Foundation: state persistence
   │
   ▼
Step 2: sync/diff.fnl            ← Uses state for comparison
   │
   ├──► Step 4: push.fnl mods    ← Uses diff for pre-push check
   │       │
   │       ▼
   ├──► Step 5: pull.fnl mods    ← Updates state after pull
   │
   ▼
Step 3: sync/resolve.fnl         ← Uses state + diff for resolution
   │
   ▼
Step 6: sync/auto.fnl            ← Uses push (which uses diff)
   │
   ▼
Step 7: Commands & Status         ← Wires everything together
   │
   ▼
Step 8: Tests                     ← Comprehensive test coverage
```

Steps 4 and 5 can be done in parallel after Step 2. Step 8 (tests) should be written alongside each step, not deferred.

---

## New Files Summary

| File | Type | Description |
|------|------|-------------|
| `fnl/longway/cache/state.fnl` | New | Per-entity sync state persistence |
| `fnl/longway/sync/diff.fnl` | New | Section-level change detection |
| `fnl/longway/sync/resolve.fnl` | New | Conflict resolution strategies |
| `fnl/longway/sync/auto.fnl` | New | Auto-push on save with debounce |
| `fnl/longway-spec/cache/state_spec.fnl` | New | State module tests |
| `fnl/longway-spec/sync/diff_spec.fnl` | New | Diff module tests |
| `fnl/longway-spec/sync/resolve_spec.fnl` | New | Resolve module tests |
| `fnl/longway-spec/sync/auto_spec.fnl` | New | Auto-push tests |

## Modified Files Summary

| File | Changes |
|------|---------|
| `fnl/longway/sync/push.fnl` | Add pre-push remote check, state update after push, `force` option |
| `fnl/longway/sync/pull.fnl` | Add state update after pull/refresh |
| `fnl/longway/core.fnl` | Add `M.resolve`, enhance `M.status` with sync state |
| `fnl/longway/init.fnl` | Expose `resolve`, wire auto-push setup |
| `plugin/longway.lua` | Add `:LongwayResolve` command |

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

- [ ] Sync state tracked per story/epic in `.longway/state/`
- [ ] Pre-push conflict detection (compares local and remote changes)
- [ ] Conflict notification when both local and remote have diverged
- [ ] `:LongwayResolve local` — Force push local content
- [ ] `:LongwayResolve remote` — Force pull remote content
- [ ] `:LongwayResolve manual` — Insert conflict markers for manual resolution
- [ ] `:LongwayStatus` enhanced to show sync state and conflict info
- [ ] Auto-push on save (opt-in, debounced, conflict-aware)
- [ ] Comprehensive test coverage for all new modules
