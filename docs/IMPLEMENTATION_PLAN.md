# longway.nvim Implementation Plan

This document outlines the step-by-step implementation plan for longway.nvim based on the PRD phases.

## Current State

The repository has basic scaffolding:
- `fnl/longway/init.fnl` - Main entry with `setup()` function
- `fnl/longway/config.fnl` - Basic configuration module
- `fnl/longway/core.fnl` - Placeholder core functions
- `plugin/longway.lua` - User command entry points
- nfnl compilation configured

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
- [ ] Add all config fields from PRD section 7.1
- [ ] Implement `config.validate()` for required field checks
- [ ] Add token resolution (env var → file → config)

### 1.2 HTTP Client Module

Create `fnl/longway/api/client.fnl`:

**Tasks:**
- [ ] Create HTTP wrapper using plenary.curl
- [ ] Add authentication header injection
- [ ] Implement base URL handling (`https://api.app.shortcut.com`)
- [ ] Add error response parsing
- [ ] Create async request helper using plenary.async

### 1.3 Stories API Module

Create `fnl/longway/api/stories.fnl`:

**Tasks:**
- [ ] Implement `get-story(id)` - GET /api/v3/stories/{id}
- [ ] Implement `update-story(id, data)` - PUT /api/v3/stories/{id}
- [ ] Add response parsing/normalization

### 1.4 Markdown Renderer

Create `fnl/longway/markdown/renderer.fnl`:

**Tasks:**
- [ ] Implement YAML frontmatter generation
- [ ] Implement story → markdown conversion
- [ ] Add sync marker insertion for description section
- [ ] Implement slug generation utility

### 1.5 Basic Pull Command

Update `fnl/longway/core.fnl` and add sync module:

**Tasks:**
- [ ] Create `fnl/longway/sync/pull.fnl`
- [ ] Implement `pull-story(id)` - fetch and write markdown file
- [ ] Create workspace directory structure on first pull
- [ ] Add `:LongwayPull {id}` command

### 1.6 Basic Push Command

**Tasks:**
- [ ] Create `fnl/longway/markdown/parser.fnl` - parse frontmatter + sync sections
- [ ] Create `fnl/longway/sync/push.fnl`
- [ ] Implement `push-story()` - read current buffer, extract description, PUT to API
- [ ] Add `:LongwayPush` command

### 1.7 Error Handling

**Tasks:**
- [ ] Create `fnl/longway/ui/notify.fnl` - notification wrapper
- [ ] Add error notifications for API failures
- [ ] Add token validation on setup

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
- [ ] Implement `search-stories(query)` - GET /api/v3/search/stories
- [ ] Parse search query string into API parameters
- [ ] Handle pagination for large result sets

### 2.2 Reference Data APIs

**Tasks:**
- [ ] Create `fnl/longway/api/members.fnl` - GET /api/v3/members, GET /api/v3/member
- [ ] Create `fnl/longway/api/workflows.fnl` - GET /api/v3/workflows
- [ ] Create `fnl/longway/api/iterations.fnl` - GET /api/v3/iterations
- [ ] Create `fnl/longway/api/teams.fnl` - GET /api/v3/groups

### 2.3 Cache Module

Create `fnl/longway/cache/store.fnl`:

**Tasks:**
- [ ] Implement JSON file cache in `{workspace}/.longway/cache/`
- [ ] Add cache read/write with TTL support
- [ ] Implement cache refresh commands
- [ ] Cache members, workflows, teams, iterations

### 2.4 Preset Configuration

**Tasks:**
- [ ] Enhance config to support `presets` table
- [ ] Implement preset resolution in sync commands
- [ ] Add `:LongwaySync {preset}` command variant

### 2.5 Epic Support

Create `fnl/longway/api/epics.fnl`:

**Tasks:**
- [ ] Implement `get-epic(id)` - GET /api/v3/epics/{id}
- [ ] Implement `get-epic-stories(id)` - GET /api/v3/epics/{id}/stories
- [ ] Implement `update-epic(id, data)` - PUT /api/v3/epics/{id}

### 2.6 Epic Markdown Renderer

**Tasks:**
- [ ] Add epic → markdown conversion
- [ ] Render story table in epic files
- [ ] Link to story markdown files

### 2.7 Bulk Operations

**Tasks:**
- [ ] Implement `sync-all(query)` - pull multiple stories
- [ ] Add progress indicator for bulk pulls
- [ ] Add `:LongwaySync [query]` command

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
- [ ] Implement `create-task(story_id, data)` - POST
- [ ] Implement `update-task(story_id, task_id, data)` - PUT
- [ ] Implement `delete-task(story_id, task_id)` - DELETE

### 3.2 Task Markdown Parser

Create `fnl/longway/markdown/tasks.fnl`:

**Tasks:**
- [ ] Parse checkbox syntax: `- [x] Description <!-- task:123 -->`
- [ ] Extract task metadata (id, owner, complete)
- [ ] Detect new tasks (no ID or `task:new`)
- [ ] Detect deleted tasks (present in hash, missing in markdown)

### 3.3 Task Markdown Renderer

**Tasks:**
- [ ] Render tasks as checkboxes with inline metadata
- [ ] Format owner mentions
- [ ] Generate tasks section with sync markers

### 3.4 Task Sync Logic

Create `fnl/longway/sync/tasks.fnl`:

**Tasks:**
- [ ] Implement task diff detection
- [ ] Create new tasks on push
- [ ] Update completion status on push
- [ ] Delete tasks with confirmation prompt
- [ ] Merge remote task additions on pull

### 3.5 Hash Tracking for Tasks

Update `fnl/longway/cache/state.fnl`:

**Tasks:**
- [ ] Add `tasks_hash` to sync state
- [ ] Compute hash from task list for change detection

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
- [ ] Implement `list-comments(story_id)` - GET
- [ ] Implement `create-comment(story_id, text)` - POST
- [ ] Implement `delete-comment(story_id, comment_id)` - DELETE

### 4.2 Comment Markdown Parser

Create `fnl/longway/markdown/comments.fnl`:

**Tasks:**
- [ ] Parse comment format: `**Author** · timestamp <!-- comment:id -->`
- [ ] Extract comment metadata (id, author, timestamp)
- [ ] Detect new comments (`comment:new`)
- [ ] Detect deleted comments

### 4.3 Comment Markdown Renderer

**Tasks:**
- [ ] Render comments with author and timestamp
- [ ] Resolve author UUID to display name from cache
- [ ] Format timestamps per config

### 4.4 Comment Sync Logic

Create `fnl/longway/sync/comments.fnl`:

**Tasks:**
- [ ] Pull and render comments
- [ ] Create new comments on push
- [ ] Delete comments with confirmation
- [ ] Warn on edit attempts (not supported by API)

### 4.5 Member Name Resolution

**Tasks:**
- [ ] Lookup member names from cached members
- [ ] Fallback to ID if name unavailable
- [ ] Handle "me" for current user

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
- [ ] Implement content hashing per section
- [ ] Compare local hash with stored hash
- [ ] Compare remote `updated_at` with stored timestamp
- [ ] Categorize: unchanged, local-only, remote-only, conflict

### 5.2 Sync State Module

Create `fnl/longway/cache/state.fnl`:

**Tasks:**
- [ ] Track sync state per story/epic in JSON
- [ ] Store: local_hash, remote_updated_at, last_synced_at
- [ ] Update state after successful sync

### 5.3 Auto-Push on Save

**Tasks:**
- [ ] Add autocmd for BufWritePost in workspace
- [ ] Implement debounced push (configurable delay)
- [ ] Add `auto_push_on_save` config option
- [ ] Show notification on auto-push

### 5.4 Conflict Detection

**Tasks:**
- [ ] Check remote before push
- [ ] Detect when both local and remote changed
- [ ] Store conflict state for resolution

### 5.5 Conflict Resolution

Create `fnl/longway/sync/resolve.fnl`:

**Tasks:**
- [ ] Implement `:LongwayResolve local` - force push
- [ ] Implement `:LongwayResolve remote` - force pull
- [ ] Implement `:LongwayResolve manual` - insert conflict markers
- [ ] Add conflict notification with options

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
- [ ] Implement stories picker with snacks.picker
- [ ] Add story preview (rendered markdown)
- [ ] Open story file on selection
- [ ] Add state/owner/iteration columns

### 6.2 Snacks Picker - Epics

**Tasks:**
- [ ] Implement epics picker
- [ ] Show epic stats in preview
- [ ] Open epic file on selection

### 6.3 Snacks Picker - Presets

**Tasks:**
- [ ] Implement preset picker
- [ ] Show preset description
- [ ] Run sync on selection

### 6.4 Snacks Picker - Modified

**Tasks:**
- [ ] Implement modified files picker
- [ ] Show diff preview
- [ ] Batch push option

### 6.5 Progress Indicators

Create `fnl/longway/ui/progress.fnl`:

**Tasks:**
- [ ] Show progress for bulk sync operations
- [ ] Integrate with snacks or vim.notify
- [ ] Display X/Y stories synced

### 6.6 Notification Improvements

**Tasks:**
- [ ] Categorize notifications (info, warn, error)
- [ ] Add sync summary notifications
- [ ] Respect `notify_level` config

### 6.7 Status Line Integration

**Tasks:**
- [ ] Expose sync status for statusline plugins
- [ ] Show modified/conflict indicators
- [ ] Document integration with lualine/etc.

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

### 7.3 Offline Queue

**Tasks:**
- [ ] Queue push operations when offline
- [ ] Detect network availability
- [ ] Flush queue when online

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
- [ ] Set up testing framework (plenary.test or busted)
- [ ] Add unit tests for markdown parsing
- [ ] Add unit tests for sync logic
- [ ] Add integration tests with mock API

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
├── core.fnl ─────────────┐
│   ├── sync/pull.fnl     │
│   │   ├── api/stories.fnl
│   │   ├── api/epics.fnl
│   │   ├── markdown/renderer.fnl
│   │   └── cache/state.fnl
│   ├── sync/push.fnl     │
│   │   ├── markdown/parser.fnl
│   │   ├── sync/diff.fnl
│   │   └── api/*.fnl
│   └── sync/resolve.fnl  │
├── api/                  │
│   ├── client.fnl ◄──────┘
│   ├── stories.fnl
│   ├── epics.fnl
│   ├── tasks.fnl
│   ├── comments.fnl
│   ├── search.fnl
│   └── rate_limit.fnl
├── markdown/
│   ├── parser.fnl
│   ├── renderer.fnl
│   ├── frontmatter.fnl
│   ├── tasks.fnl
│   └── comments.fnl
├── ui/
│   ├── notify.fnl
│   ├── picker.fnl
│   └── progress.fnl
├── cache/
│   ├── store.fnl
│   └── state.fnl
└── util/
    ├── slug.fnl
    ├── hash.fnl
    └── async.fnl
```

---

## Development Workflow

1. **Write Fennel** in `fnl/longway/`
2. **Compile** with nfnl (`:NfnlCompile` or on save)
3. **Test** in Neovim with `:source %` or restart
4. **Commit** both `.fnl` and generated `.lua` files

---

## Next Steps

To begin implementation:

1. Start with Phase 1.1 - Enhance configuration
2. Set up plenary.nvim dependency
3. Implement the HTTP client (1.2)
4. Build from there iteratively

Each phase should result in a working, usable feature set.
