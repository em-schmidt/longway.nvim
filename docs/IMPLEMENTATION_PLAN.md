# longway.nvim Implementation Plan

This document outlines the step-by-step implementation plan for longway.nvim based on the PRD phases.

## Current State

Phases 1–6 are complete (v0.6.0). The plugin supports:
- API client with authentication and token resolution
- Story and epic pull/push with markdown rendering
- Search/filter with presets and bulk sync
- Reference data APIs (members, workflows, iterations, teams) with caching
- Task synchronization (create, update, delete, batch) with checkbox rendering
- Comment synchronization (create, delete, batch) with author resolution and timestamp formatting
- Confirmation prompts for task/comment deletion
- Warning when editing existing comments (Shortcut API doesn't support comment edits)
- Content hashing for change detection (sync_hash, tasks_hash, comments_hash)
- Bidirectional sync with section-level change detection (description, tasks, comments)
- Auto-push on save with debounce (opt-in via config)
- Conflict detection and resolution (local/remote/manual strategies)
- Snacks picker integration (stories, epics, presets, modified files)
- Progress indicators for bulk sync operations
- Statusline integration (lualine component + raw status API)
- 400+ tests across all modules

---

## Phase 1: Core Foundation (v0.1.0)

**Goal:** Establish the API client, basic story operations, and markdown file creation.

### 1.1 Configuration Enhancement

Update `fnl/longway/config.fnl` to support full configuration schema:

```fennel
;; Default config fields to add:
{:token nil
 :token_file nil
 :workspace_dir (vim.fn.expand "~/shortcut")
 :stories_subdir "stories"
 :epics_subdir "epics"
 :debug false
 :notify true}
```

**Tasks:**
- [x] Add all config fields from PRD section 7.1
- [x] Implement `config.validate()` for required field checks
- [x] Add token resolution (env var → file → config)

### 1.2 HTTP Client Module

Create `fnl/longway/api/client.fnl`:

**Tasks:**
- [x] Create HTTP wrapper using plenary.curl
- [x] Add authentication header injection
- [x] Implement base URL handling (`https://api.app.shortcut.com`)
- [x] Add error response parsing
- [x] Create async request helper using plenary.async

### 1.3 Stories API Module

Create `fnl/longway/api/stories.fnl`:

**Tasks:**
- [x] Implement `get-story(id)` - GET /api/v3/stories/{id}
- [x] Implement `update-story(id, data)` - PUT /api/v3/stories/{id}
- [x] Add response parsing/normalization

### 1.4 Markdown Renderer

Create `fnl/longway/markdown/renderer.fnl`:

**Tasks:**
- [x] Implement YAML frontmatter generation
- [x] Implement story → markdown conversion
- [x] Add sync marker insertion for description section
- [x] Implement slug generation utility

### 1.5 Basic Pull Command

Update `fnl/longway/core.fnl` and add sync module:

**Tasks:**
- [x] Create `fnl/longway/sync/pull.fnl`
- [x] Implement `pull-story(id)` - fetch and write markdown file
- [x] Create workspace directory structure on first pull
- [x] Add `:LongwayPull {id}` command

### 1.6 Basic Push Command

**Tasks:**
- [x] Create `fnl/longway/markdown/parser.fnl` - parse frontmatter + sync sections
- [x] Create `fnl/longway/sync/push.fnl`
- [x] Implement `push-story()` - read current buffer, extract description, PUT to API
- [x] Add `:LongwayPush` command

### 1.7 Error Handling

**Tasks:**
- [x] Create `fnl/longway/ui/notify.fnl` - notification wrapper
- [x] Add error notifications for API failures
- [x] Add token validation on setup

**Phase 1 Deliverables:**
- `:LongwayPull {story_id}` - Fetch a story by ID
- `:LongwayPush` - Push current buffer's description to Shortcut
- `:LongwayInfo` - Show config status

---

## Phase 2: Filtering & Search (v0.2.0)

**Goal:** Enable flexible story queries, presets, and reference data caching.

### 2.1 Search API Module

Create `fnl/longway/api/search.fnl`:

**Tasks:**
- [x] Implement `search-stories(query)` - GET /api/v3/search/stories
- [x] Parse search query string into API parameters
- [x] Handle pagination for large result sets

### 2.2 Reference Data APIs

**Tasks:**
- [x] Create `fnl/longway/api/members.fnl` - GET /api/v3/members, GET /api/v3/member
- [x] Create `fnl/longway/api/workflows.fnl` - GET /api/v3/workflows
- [x] Create `fnl/longway/api/iterations.fnl` - GET /api/v3/iterations
- [x] Create `fnl/longway/api/teams.fnl` - GET /api/v3/groups

### 2.3 Cache Module

Create `fnl/longway/cache/store.fnl`:

**Tasks:**
- [x] Implement JSON file cache in `{workspace}/.longway/cache/`
- [x] Add cache read/write with TTL support
- [x] Implement cache refresh commands
- [x] Cache members, workflows, teams, iterations

### 2.4 Preset Configuration

**Tasks:**
- [x] Enhance config to support `presets` table
- [x] Implement preset resolution in sync commands
- [x] Add `:LongwaySync {preset}` command variant

### 2.5 Epic Support

Create `fnl/longway/api/epics.fnl`:

**Tasks:**
- [x] Implement `get-epic(id)` - GET /api/v3/epics/{id}
- [x] Implement `get-epic-stories(id)` - GET /api/v3/epics/{id}/stories
- [x] Implement `update-epic(id, data)` - PUT /api/v3/epics/{id}

### 2.6 Epic Markdown Renderer

**Tasks:**
- [x] Add epic → markdown conversion
- [x] Render story table in epic files
- [x] Link to story markdown files

### 2.7 Bulk Operations

**Tasks:**
- [x] Implement `sync-all(query)` - pull multiple stories
- [x] Add progress indicator for bulk pulls
- [x] Add `:LongwaySync [query]` command

**Phase 2 Deliverables:**
- `:LongwaySync owner:me state:started` - Filter-based sync
- `:LongwaySync {preset_name}` - Preset sync
- `:LongwaySyncAll` - Sync all presets
- Epic markdown files with story tables

---

## Phase 3: Task Synchronization (v0.3.0)

**Goal:** Bidirectional task sync with checkbox rendering.

### 3.1 Task API Module

Create `fnl/longway/api/tasks.fnl`:

**Tasks:**
- [x] Implement `create-task(story_id, data)` - POST
- [x] Implement `update-task(story_id, task_id, data)` - PUT
- [x] Implement `delete-task(story_id, task_id)` - DELETE

### 3.2 Task Markdown Parser

Create `fnl/longway/markdown/tasks.fnl`:

**Tasks:**
- [x] Parse checkbox syntax: `- [x] Description <!-- task:123 -->`
- [x] Extract task metadata (id, owner, complete)
- [x] Detect new tasks (no ID or `task:new`)
- [x] Detect deleted tasks (present in hash, missing in markdown)

### 3.3 Task Markdown Renderer

**Tasks:**
- [x] Render tasks as checkboxes with inline metadata
- [x] Format owner mentions
- [x] Generate tasks section with sync markers

### 3.4 Task Sync Logic

Create `fnl/longway/sync/tasks.fnl`:

**Tasks:**
- [x] Implement task diff detection
- [x] Create new tasks on push
- [x] Update completion status on push
- [x] Delete tasks with confirmation prompt
- [x] Merge remote task additions on pull

### 3.5 Hash Tracking for Tasks

Update `fnl/longway/cache/state.fnl`:

**Tasks:**
- [x] Add `tasks_hash` to sync state
- [x] Compute hash from task list for change detection

**Phase 3 Deliverables:**
- Tasks rendered as `- [x] Description <!-- task:id -->` checkboxes
- Checkbox changes sync completion status to Shortcut
- New tasks created from markdown
- Task deletion with confirmation

---

## Phase 4: Comment Synchronization (v0.4.0)

**Goal:** Pull comments and allow new comment creation.

### 4.1 Comment API Module

Create `fnl/longway/api/comments.fnl`:

**Tasks:**
- [x] Implement `list-comments(story_id)` - GET
- [x] Implement `create-comment(story_id, text)` - POST
- [x] Implement `delete-comment(story_id, comment_id)` - DELETE

### 4.2 Comment Markdown Parser

Create `fnl/longway/markdown/comments.fnl`:

**Tasks:**
- [x] Parse comment format: `**Author** · timestamp <!-- comment:id -->`
- [x] Extract comment metadata (id, author, timestamp)
- [x] Detect new comments (`comment:new`)
- [x] Detect deleted comments

### 4.3 Comment Markdown Renderer

**Tasks:**
- [x] Render comments with author and timestamp
- [x] Resolve author UUID to display name from cache
- [x] Format timestamps per config

### 4.4 Comment Sync Logic

Create `fnl/longway/sync/comments.fnl`:

**Tasks:**
- [x] Pull and render comments
- [x] Create new comments on push
- [x] Delete comments with confirmation
- [x] Warn on edit attempts (not supported by API)

### 4.5 Member Name Resolution

**Tasks:**
- [x] Lookup member names from cached members
- [x] Fallback to ID if name unavailable
- [x] Handle "me" for current user

**Phase 4 Deliverables:**
- Comments rendered in dedicated section
- New comments can be created from markdown
- Author names resolved from cache
- Warning when editing existing comments

---

## Phase 5: Bidirectional Sync & Conflicts (v0.5.0)

**Goal:** Automatic sync, change detection, and conflict handling.

### 5.1 Change Detection

Create `fnl/longway/sync/diff.fnl`:

**Tasks:**
- [x] Implement content hashing per section
- [x] Compare local hash with stored hash
- [x] Compare remote `updated_at` with stored timestamp
- [x] Categorize: unchanged, local-only, remote-only, conflict

### 5.2 Sync State Module

Sync state stored in YAML frontmatter (no separate state files):

**Tasks:**
- [x] Track sync state per story/epic in frontmatter
- [x] Store: sync_hash, tasks_hash, comments_hash, updated_at
- [x] Update state after successful sync

### 5.3 Auto-Push on Save

**Tasks:**
- [x] Add autocmd for BufWritePost in workspace
- [x] Implement debounced push (configurable delay)
- [x] Add `auto_push_on_save` config option
- [x] Show notification on auto-push

### 5.4 Conflict Detection

**Tasks:**
- [x] Check remote before push
- [x] Detect when both local and remote changed
- [x] Store conflict state for resolution

### 5.5 Conflict Resolution

Create `fnl/longway/sync/resolve.fnl`:

**Tasks:**
- [x] Implement `:LongwayResolve local` - force push
- [x] Implement `:LongwayResolve remote` - force pull
- [x] Implement `:LongwayResolve manual` - insert conflict markers
- [x] Add conflict notification with options

**Phase 5 Deliverables:**
- Automatic push on save (optional)
- Conflict detection before push
- `:LongwayResolve {local|remote|manual}` command
- `:LongwayStatus` shows sync state

---

## Phase 6: UI Polish (v0.6.0)

**Goal:** Snacks picker integration and improved UX.

### 6.1 Snacks Picker - Stories

Create `fnl/longway/ui/picker.fnl`:

**Tasks:**
- [x] Implement stories picker with snacks.picker
- [x] Add story preview (rendered markdown)
- [x] Open story file on selection
- [x] Add state/owner/iteration columns

### 6.2 Snacks Picker - Epics

**Tasks:**
- [x] Implement epics picker
- [x] Show epic stats in preview
- [x] Open epic file on selection

### 6.3 Snacks Picker - Presets

**Tasks:**
- [x] Implement preset picker
- [x] Show preset description
- [x] Run sync on selection

### 6.4 Snacks Picker - Modified

**Tasks:**
- [x] Implement modified files picker
- [x] Show diff preview
- [x] Batch push option

### 6.5 Progress Indicators

Create `fnl/longway/ui/progress.fnl`:

**Tasks:**
- [x] Show progress for bulk sync operations
- [x] Integrate with snacks or vim.notify
- [x] Display X/Y stories synced

### 6.6 Notification Improvements

**Tasks:**
- [x] Categorize notifications (info, warn, error)
- [x] Add sync summary notifications
- [x] Respect `notify_level` config

### 6.7 Status Line Integration

**Tasks:**
- [x] Expose sync status for statusline plugins
- [x] Show modified/conflict indicators
- [x] Document integration with lualine/etc.

**Phase 6 Deliverables:**
- `:LongwayPicker stories/epics/presets/modified`
- Progress indicators during bulk operations
- Enhanced notifications
- Statusline integration API

---

## Phase 7: Advanced Features (v1.0.0)

**Goal:** Polish, documentation, and advanced workflows.

### 7.1 Vimdiff Conflict Resolution

**Tasks:**
- [ ] Implement `:LongwayResolve diff` with vimdiff
- [ ] Create temp files for local/remote versions
- [ ] Apply resolved content back to file

### 7.2 Batch Operations

**Tasks:**
- [ ] `:LongwayPushAll` - push all modified files
- [ ] Add confirmation for batch operations
- [ ] Show batch operation summary

### 7.3 Story Status

**Tasks:**
- [ ] Add story status to story markdown frontmatter
- [ ] Add picker for changing story status

### 7.4 Rate Limit Handling

Create `fnl/longway/api/rate_limit.fnl`:

**Tasks:**
- [ ] Track request count per minute
- [ ] Implement request throttling
- [ ] Add exponential backoff on 429

### 7.5 Documentation

**Tasks:**
- [ ] Write README.md with installation/usage
- [ ] Add vimdoc help file (doc/longway.txt)
- [ ] Document all commands and configuration
- [ ] Add examples for common workflows

### 7.6 Test Coverage

**Tasks:**
- [ ] Review current test coverage for gaps, document any opportunities for improvements

**Phase 7 Deliverables:**
- Vimdiff-based conflict resolution
- Offline operation queue
- Rate limiting protection
- Complete documentation
- Test suite

---

## Module Dependency Graph

```
init.fnl
├── config.fnl
├── core.fnl ──────────────────────┐
│   ├── sync/pull.fnl              │
│   │   ├── api/stories.fnl       │
│   │   ├── api/comments.fnl      │
│   │   ├── api/epics.fnl         │
│   │   ├── markdown/renderer.fnl │
│   │   └── cache/store.fnl       │
│   ├── sync/push.fnl              │
│   │   ├── markdown/parser.fnl   │
│   │   ├── sync/tasks.fnl        │
│   │   ├── sync/comments.fnl     │
│   │   ├── sync/diff.fnl         │  (Phase 5: change detection)
│   │   ├── api/tasks.fnl         │
│   │   ├── api/comments.fnl      │
│   │   └── ui/confirm.fnl        │
│   ├── sync/tasks.fnl             │
│   │   └── markdown/tasks.fnl    │
│   ├── sync/comments.fnl          │
│   │   ├── markdown/comments.fnl  │
│   │   └── api/comments.fnl      │
│   ├── sync/diff.fnl              │  (Phase 5: section-level change detection)
│   │   └── util/hash.fnl         │
│   ├── sync/resolve.fnl           │  (Phase 5: conflict resolution)
│   │   ├── sync/pull.fnl         │
│   │   └── sync/push.fnl         │
│   └── sync/auto.fnl              │  (Phase 5: auto-push on save)
│       └── sync/push.fnl         │
├── api/                           │
│   ├── client.fnl ◄───────────────┘
│   ├── stories.fnl
│   ├── epics.fnl
│   ├── tasks.fnl
│   ├── comments.fnl
│   ├── members.fnl
│   ├── workflows.fnl
│   ├── iterations.fnl
│   ├── teams.fnl
│   └── search.fnl
├── markdown/
│   ├── parser.fnl ──► tasks.fnl, comments.fnl (delegates parsing)
│   ├── renderer.fnl ──► tasks.fnl, comments.fnl (delegates rendering)
│   ├── frontmatter.fnl
│   ├── tasks.fnl      (single source of truth for tasks)
│   └── comments.fnl   (single source of truth for comments)
├── ui/
│   ├── notify.fnl
│   ├── confirm.fnl
│   ├── picker.fnl      (Phase 6: snacks.picker integration)
│   ├── progress.fnl    (Phase 6: bulk operation progress)
│   └── statusline.fnl  (Phase 6: statusline component)
├── cache/
│   └── store.fnl
└── util/
    ├── slug.fnl
    └── hash.fnl
```

---

## Development Workflow

1. **Write Fennel** in `fnl/longway/`
2. **Compile** with nfnl (`:NfnlCompile` or on save)
3. **Test** in Neovim with `:source %` or restart
4. **Commit** both `.fnl` and generated `.lua` files

---

## Next Steps

Phases 1–6 are complete. Next:

1. **Phase 7: Advanced Features** — Vimdiff conflict resolution, batch operations, offline queue, rate limiting, documentation, test coverage

Each phase should result in a working, usable feature set.
