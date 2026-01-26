# Phase 4: Comment Synchronization — Implementation Plan

**Goal:** Pull comments from Shortcut and render them in markdown; allow new comment creation and comment deletion from the editor.

**Version Target:** v0.4.0

---

## Current State Assessment

Phase 3 (Task Synchronization) is complete. The codebase has significant comment scaffolding already in place:

| Component | Status | Location |
|-----------|--------|----------|
| Comment API stubs | Done | `api/stories.fnl:37-53` (list, create, delete) |
| Comment parsing | Done | `markdown/parser.fnl:38-77` (parse-comment-block, extract-comments) |
| Comment rendering | Done | `markdown/renderer.fnl:74-96` (render-comment, render-comments) |
| Config defaults | Done | `config.fnl:36-39` (max_pull, show_timestamps, timestamp_format, confirm_delete) |
| Test helpers | Done | `longway-spec/init.fnl:58-66` (make-comment, sample markdown) |
| Dedicated comments module (api) | Missing | Needs `api/comments.fnl` |
| Dedicated comments module (markdown) | Missing | Needs `markdown/comments.fnl` |
| Comment sync orchestration | Missing | Needs `sync/comments.fnl` |
| Comments hash tracking | Missing | `hash.fnl` has no `comments-hash` |
| Push integration (comments) | Missing | `push.fnl` only pushes description + tasks |
| Status integration (comments) | Missing | `core.fnl` status only shows tasks |
| Edit-warning for existing comments | Missing | Not implemented |
| Test specs for comments | Missing | No `comments_spec.fnl` files |

**Estimated scope:** ~12 files to create/modify, following the established Phase 3 (tasks) pattern exactly.

---

## Implementation Steps

### Step 1: Create `fnl/longway/api/comments.fnl`

**Pattern:** Mirrors `api/tasks.fnl`

Create a dedicated comment API module, extracting and expanding the stubs currently in `api/stories.fnl`.

**Functions to implement:**

```fennel
M.list [story-id]           ;; GET /stories/{id}/comments
M.get [story-id comment-id] ;; GET /stories/{id}/comments/{id}
M.create [story-id data]    ;; POST /stories/{id}/comments  (data: {:text string :author_id string})
M.delete [story-id comment-id] ;; DELETE /stories/{id}/comments/{id}
M.batch-create [story-id comments]  ;; Create multiple comments sequentially
M.batch-delete [story-id comment-ids] ;; Delete multiple comments sequentially
```

**Key differences from tasks API:**
- `create` takes `{:text string}` rather than `{:description string :complete bool}`
- No `update` endpoint — Shortcut API does not support editing comments
- `author_id` is optional in create (defaults to token owner)

**Also:** Remove the comment stubs from `api/stories.fnl` (lines 37-53) and redirect to the new module, or keep as thin wrappers that delegate to `api/comments.fnl`.

---

### Step 2: Create `fnl/longway/markdown/comments.fnl`

**Pattern:** Mirrors `markdown/tasks.fnl`

A dedicated module for structured comment parsing, rendering, and comparison. Much of the logic already exists in `parser.fnl` and `renderer.fnl` — this module provides the structured layer on top.

**Functions to implement:**

```fennel
;;; Parsing
M.parse-block [block]        ;; Parse a single comment block → {:id :author :timestamp :text :is_new}
M.parse-section [content]    ;; Parse full comments section → [comment, ...]

;;; Author Resolution
M.resolve-author-name [author-id]  ;; UUID → display name (via members cache)
M.resolve-author-id [name]         ;; Display name → UUID (for new comments)
M.get-current-user []              ;; Get current authenticated user info

;;; Rendering
M.render-comment [comment]         ;; Render single comment → markdown string
M.render-comments [comments]       ;; Render comment list → markdown string
M.render-section [comments]        ;; Render with sync markers

;;; Formatting
M.format-api-comments [raw-comments] ;; Convert API response → rendering format
                                     ;; Resolves author_id to display name
                                     ;; Formats timestamps per config

;;; Comparison
M.comment-changed? [local remote]  ;; Check if comment text differs (for edit detection)
M.comments-equal? [a b]            ;; Compare two comment lists
M.find-comment-by-id [comments id] ;; Lookup helper
```

**Design decisions:**
- `format-api-comments` resolves `author_id` UUIDs to display names using `members.resolve-name` (already in `api/members.fnl:73-79`)
- Timestamp formatting uses `config.comments.timestamp_format` (strftime format, default `"%Y-%m-%d %H:%M"`)
- `comment-changed?` detects text edits — used to warn users that edits can't sync
- The existing `parse-comment-block` in `parser.fnl` and `render-comment` in `renderer.fnl` can either be moved here or kept and called from here; recommend **moving** for consistency with how `markdown/tasks.fnl` owns task parsing/rendering

---

### Step 3: Add `comments-hash` to `util/hash.fnl`

**Pattern:** Mirrors `tasks-hash`

Add two functions:

```fennel
M.comments-hash [comments]     ;; Canonical hash: id|text for each comment, sorted by id
M.comments-changed? [old-hash comments]  ;; Compare stored hash with current
```

The canonical string format: `"{id}|{text}"` per comment, sorted by ID, joined with `\n`. New comments (no ID) use `"new"` as ID placeholder.

---

### Step 4: Create `fnl/longway/sync/comments.fnl`

**Pattern:** Mirrors `sync/tasks.fnl`

The core sync orchestration module.

**Functions to implement:**

```fennel
;;; Diffing
M.diff [local-comments remote-comments]
  ;; Returns: {:created [comments] :deleted [comment-ids] :unchanged [comments] :edited [comments]}
  ;; Note: "edited" is a special category — these generate warnings, NOT API updates

M.has-changes? [diff]
  ;; Returns: bool

;;; Push Operations
M.push [story-id local-comments remote-comments opts]
  ;; Orchestrates: create new → delete removed → warn on edits
  ;; opts: {:confirm_delete bool :skip_delete bool}
  ;; Returns: {:ok bool :created n :deleted n :warned n :errors [] :comments [updated list]}

;;; Pull Operations
M.pull [story comments-data]
  ;; Extract and format comments from API response
  ;; story: Story data from API (may include inline comments)
  ;; comments-data: Separate comments list from list-comments API call
  ;; Returns: {:ok bool :comments [formatted comments]}

;;; Merge (for future bidirectional sync - Phase 5)
M.merge [local-comments remote-comments previous-comments]
  ;; Returns: {:comments [merged] :conflicts [ids] :remote_added [comments] :remote_deleted [ids]}
```

**Comment sync behavior (from PRD section 3.2.3):**

| Scenario | Action |
|----------|--------|
| New comment locally (`comment:new`) | `create-comment` via API, update ID in markdown |
| Comment deleted locally | `delete-comment` via API (with confirmation if `config.comments.confirm_delete`) |
| Comment edited locally | **Warn** — Shortcut API doesn't support editing. Show notification. |
| Comment added remotely | Append to comments section on pull |

**Key difference from task sync:** There is no "update" path. Editing an existing comment's text locally should trigger a warning notification, not an API call.

---

### Step 5: Integrate comments into `sync/push.fnl`

**Modify** `push.fnl` to push comments alongside description and tasks.

**Changes needed:**

1. Add `require` for `comments-sync` and `comments-md` modules
2. Create `push-story-comments` function (parallel to `push-story-tasks`):
   - Fetch current remote comments via `comments-api.list`
   - Run `comments-sync.diff` with local parsed comments
   - Handle `confirm_delete` for deletions
   - Warn on edits
   - Create new comments
   - Return updated comment list
3. Create `update-buffer-comments` function (parallel to `update-buffer-tasks`):
   - After push, update the comments section in the buffer with new IDs
4. Integrate into `M.push-story`:
   - After task push block, add comment push block gated by `cfg.sync_sections.comments`
   - Update `comments_hash` in frontmatter after successful push
5. **Edit warning**: When `diff.edited` is non-empty, show:
   `"Warning: {n} comment(s) were edited locally. Shortcut does not support comment editing — changes will not sync."`

---

### Step 6: Integrate comments into `sync/pull.fnl`

**Modify** `pull.fnl` to fetch and include comments when pulling stories.

**Changes needed:**

1. In `M.pull-story`: After fetching the story, also call `comments-api.list(story-id)` to get comments (the story response may not include full comment data)
2. Pass comments to `renderer.render-story` — the renderer already handles comments (lines 123-128), but currently relies on `story.comments` which may not be populated by the API response
3. Respect `config.comments.max_pull` — limit the number of comments fetched

**Note:** The Shortcut story GET response does _not_ include full comment text. Comments must be fetched separately via `GET /stories/{id}/comments`. The existing `renderer.render-story` already renders comments if `story.comments` is populated, so the main change is ensuring `pull-story` populates that field.

---

### Step 7: Integrate comments into `core.fnl`

**Modify** `core.fnl` to show comment status.

**Changes needed:**

1. Add `print-comment-status` function (parallel to `print-task-status`):
   - Count local comments, new comments
   - Compare `comments_hash` from frontmatter with current hash
   - Print summary: `"Comments: {n} local ({m} new)"`
2. Call from `M.status` after `print-task-status`
3. Update version string from `"0.3.0"` to `"0.4.0"`

---

### Step 8: Update `markdown/renderer.fnl` for comments_hash

**Modify** `renderer.fnl` to compute and store `comments_hash`.

**Changes needed in `M.render-story`:**

1. Add `comments_hash` to frontmatter data (line 49 area — alongside `sync_hash` and `tasks_hash`)
2. In the hash computation section (lines 137-139), add:
   ```fennel
   (set fm-data.comments_hash (hash.comments-hash (or story.comments [])))
   ```

---

### Step 9: Update `ui/confirm.fnl` for comment deletions

**Add** comment-specific confirmation helpers.

**Functions to add:**

```fennel
M.confirm-delete-comments [comments callback]
  ;; Show confirmation for comment deletions with preview
  ;; Shows first 5 comments (truncated text) with author names

M.confirm-delete-comment-ids [comment-ids remote-comments callback]
  ;; Lookup descriptions from remote and delegate to confirm-delete-comments
```

**Pattern:** Direct parallel of `confirm-delete-tasks` / `confirm-delete-task-ids`.

---

### Step 10: Update test helpers in `longway-spec/init.fnl`

**Modify** existing test helpers:

1. Add `comments` config defaults to `setup-test-config` (already partially there, but ensure `comments` section is included):
   ```fennel
   :comments {:max_pull 50
              :show_timestamps true
              :timestamp_format "%Y-%m-%d %H:%M"
              :confirm_delete true}
   ```
2. Enhance `make-comment` if needed (add `author_id` field for API response format)
3. Add `make-api-comment` helper for raw API response format:
   ```fennel
   {:id 11111
    :text "Test comment"
    :author_id "author-uuid-1"
    :created_at "2026-01-10T10:30:00Z"
    :updated_at "2026-01-10T10:30:00Z"
    :story_id 12345}
   ```

---

### Step 11: Create test specs

**Create the following test files:**

#### `fnl/longway-spec/api/comments_spec.fnl`
- Test `list`, `get`, `create`, `delete` with mocked HTTP client
- Test `batch-create`, `batch-delete` error aggregation
- Test error handling (API failures)

#### `fnl/longway-spec/markdown/comments_spec.fnl`
- Test `parse-block` with valid/malformed comment blocks
- Test `parse-section` with multiple comments, new comments, empty sections
- Test `render-comment` output format matches expected markdown
- Test `render-section` with sync markers
- Test `format-api-comments` with author resolution
- Test `comment-changed?` for text edits
- Test `comments-equal?` list comparison
- Test round-trip: render → parse → compare

#### `fnl/longway-spec/sync/comments_spec.fnl`
- Test `diff` — detects created, deleted, unchanged, edited
- Test `has-changes?` for each diff category
- Test `pull` — formats API comments correctly
- Test `merge` — handles new local, new remote, conflicts, deletions
- Test integration: parse markdown → diff with remote → detect changes
- Test `comments-hash` stability

---

### Step 12: Compile and run tests

1. Run `make compile` to compile all new/modified Fennel files to Lua
2. Run `make test` to execute the full test suite
3. Fix any compilation or test failures
4. Commit both `.fnl` source and compiled `.lua` files

---

## File Summary

### New Files (8)

| File | Description |
|------|-------------|
| `fnl/longway/api/comments.fnl` | Comment API operations (CRUD + batch) |
| `fnl/longway/markdown/comments.fnl` | Comment parsing, rendering, formatting |
| `fnl/longway/sync/comments.fnl` | Comment sync orchestration (diff, push, pull) |
| `fnl/longway-spec/api/comments_spec.fnl` | API module tests |
| `fnl/longway-spec/markdown/comments_spec.fnl` | Markdown module tests |
| `fnl/longway-spec/sync/comments_spec.fnl` | Sync module tests |
| `lua/longway/api/comments.lua` | Compiled Lua (auto-generated) |
| `lua/longway/markdown/comments.lua` | Compiled Lua (auto-generated) |
| `lua/longway/sync/comments.lua` | Compiled Lua (auto-generated) |

### Modified Files (8)

| File | Changes |
|------|---------|
| `fnl/longway/api/stories.fnl` | Remove/redirect comment stubs (lines 37-53) |
| `fnl/longway/util/hash.fnl` | Add `comments-hash`, `comments-changed?` |
| `fnl/longway/sync/push.fnl` | Add comment push logic, buffer update, edit warnings |
| `fnl/longway/sync/pull.fnl` | Fetch comments separately, populate story.comments |
| `fnl/longway/markdown/renderer.fnl` | Add `comments_hash` computation in frontmatter |
| `fnl/longway/core.fnl` | Add comment status, bump version to 0.4.0 |
| `fnl/longway/ui/confirm.fnl` | Add comment deletion confirmation helpers |
| `fnl/longway-spec/init.fnl` | Enhance test helpers for comments |

---

## Architecture Diagram

```
                    ┌──────────────────┐
                    │    core.fnl      │
                    │  (status, push)  │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        ┌─────▼──────┐ ┌────▼─────┐ ┌──────▼───────┐
        │ sync/pull  │ │sync/push │ │sync/comments │  ◄── NEW
        └─────┬──────┘ └────┬─────┘ └──────┬───────┘
              │              │              │
              │         ┌────┴────┐    ┌────┴─────┐
              │         │comments │    │ comments │
              │         │  -sync  │    │  -md     │   ◄── NEW
              │         └────┬────┘    └────┬─────┘
              │              │              │
         ┌────▼──────────────▼──────────────▼────┐
         │           api/comments.fnl            │   ◄── NEW
         │  (list, get, create, delete, batch)   │
         └───────────────────┬───────────────────┘
                             │
                    ┌────────▼─────────┐
                    │  api/client.fnl  │
                    │  (HTTP wrapper)  │
                    └──────────────────┘
```

---

## Key Design Decisions

### 1. No update path for comments
The Shortcut API does not support editing comments. When a user modifies the text of an existing comment (one with a `comment:{id}` that is not `new`), the sync should:
- Detect the edit via `comment-changed?`
- Show a warning notification: the edit will be lost on next pull
- NOT attempt an API call

### 2. Comment ordering
Comments are rendered in chronological order (oldest first), matching the `created_at` timestamp from the API. New local comments (`comment:new`) are appended at the end.

### 3. Author resolution strategy
- On **pull**: Resolve `author_id` UUID → display name using the members cache (`api/members.fnl`)
- On **push** (create): The API automatically associates the token owner as author; no need to resolve
- **Fallback**: If member cache miss, use the raw UUID as display name

### 4. Separate comment fetch on pull
The Shortcut story GET endpoint does not return full comment text in the `comments` field. Comments must be fetched separately via `GET /stories/{id}/comments`. This is a separate API call during pull.

### 5. Module extraction vs. inline
Following the Phase 3 pattern, comments get their own dedicated modules (`api/comments.fnl`, `markdown/comments.fnl`, `sync/comments.fnl`) rather than being inline in existing files. This keeps the architecture consistent and testable.

---

## Phase 4 Deliverables (from PRD)

- [x] Config defaults for comments (already done)
- [x] Comments rendered in dedicated sync section
- [x] New comments can be created from markdown (`<!-- comment:new -->`)
- [x] Author names resolved from member cache
- [x] Comment deletion with confirmation prompt
- [x] Warning when editing existing comments
- [x] `comments_hash` tracked in frontmatter for change detection
- [x] Timestamp formatting per config
