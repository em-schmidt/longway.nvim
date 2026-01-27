# Product Requirements Document: longway.nvim

## Shortcut ↔ Markdown Synchronization Plugin for Neovim

**Version:** 1.0.0-draft
**Author:** Eric Schmidt
**Date:** January 21, 2026
**Repository:** https://github.com/em-schmidt/longway.nvim

---

## Executive Summary

longway.nvim is a Neovim plugin that provides bidirectional synchronization between Shortcut (project management) and local markdown files. Users can pull epics and stories from Shortcut based on configurable filter criteria, work with them as markdown documents in their preferred editor, and push changes back to Shortcut on save. This enables a keyboard-driven, distraction-free workflow for managing project work items.

---

## Problem Statement

Engineers and product managers who prefer keyboard-driven workflows and local-first tooling face friction when working with web-based project management tools. Switching context to a browser interrupts flow state, and web interfaces don't integrate with personal knowledge management systems or support offline editing.

**Pain Points:**
- Context switching between editor and browser disrupts focus
- No integration with local markdown-based note systems (Obsidian, etc.)
- Cannot work offline or in environments with limited connectivity
- Web interfaces lack vim-style navigation and editing
- Difficulty maintaining personal notes alongside official story descriptions

---

## Goals and Non-Goals

### Goals

1. **Bidirectional Sync**: Pull stories/epics from Shortcut → markdown; push markdown changes → Shortcut
2. **Flexible Filtering**: Select work items by owner, assignee, iteration, epic, team, label, state, or custom search queries
3. **Comment Sync**: Bidirectional synchronization of story comments as markdown sections
4. **Task Sync**: Bidirectional synchronization of story tasks as markdown checklists
5. **Conflict Handling**: Detect and surface conflicts when both local and remote have changed
6. **Minimal Friction**: One-command sync, auto-sync on save, snacks picker integration for discovery
7. **Preserves Local Notes**: Support sections that persist locally without syncing to Shortcut

### Non-Goals (v1.0)

- Real-time collaborative editing
- File attachment handling
- Webhook-based push notifications from Shortcut
- Creating new stories/epics from scratch (future enhancement)
- Comment threading/replies in markdown (comments rendered flat with metadata)
- Linked file management

---

## User Personas

### Primary: Eric (Principal Engineer)
- Uses Neovim as primary editor with extensive customization
- Maintains personal knowledge base in Obsidian-style markdown
- Works on infrastructure across multiple epics and iterations
- Wants to review and update story descriptions without leaving terminal
- Needs to work offline during travel or in secure environments

### Secondary: Product Manager
- Comfortable with terminal but not a power user
- Wants quick keyboard shortcuts for common operations
- Values seeing epic progress at a glance in markdown format
- Needs to batch-update multiple story descriptions efficiently

---

## Detailed Requirements

### 1. Authentication

**1.1 API Token Management**
- Store Shortcut API token securely (environment variable or encrypted file)
- Support `SHORTCUT_API_TOKEN` environment variable
- Support config file at `~/.config/longway/token` with 600 permissions
- Validate token on plugin load with user-friendly error messages

```lua
-- Configuration example
require("longway").setup({
  token = vim.env.SHORTCUT_API_TOKEN,
  -- OR
  token_file = vim.fn.expand("~/.config/longway/token"),
})
```

### 2. Filter Configuration

**2.1 Supported Filters**

| Filter | API Support | Search Operator | Example |
|--------|-------------|-----------------|---------|
| Owner | `owner_ids` | `owner:name` | Current user's stories |
| Requester | `requested_by_id` | `requester:name` | Stories I requested |
| Team | `group_id` | `team:TeamName` | Infrastructure team |
| Iteration | `iteration_id` | `iteration:name` | Current sprint |
| Epic | `epic_id` | `epic:name` | Specific epic |
| Label | `label_ids` | `label:name` | Tagged stories |
| State | `workflow_state_id` | `state:name` | "In Progress" only |
| Type | `story_type` | `type:feature` | Features only |
| Custom Query | - | Full search syntax | Complex filters |

**2.2 Filter Presets**

```lua
require("longway").setup({
  presets = {
    mine = {
      search = "owner:me state:started",
      description = "My in-progress stories"
    },
    sprint = {
      search = "iteration:current team:Infrastructure",
      description = "Current sprint, infrastructure team"
    },
    review = {
      search = "owner:me state:'Ready for Review'",
      description = "Stories awaiting review"
    },
  },
  default_preset = "mine",
})
```

**2.3 Dynamic Filters**

```lua
-- Via command
:LongwaySync owner:me iteration:current

-- Via Telescope picker with preset selection
:LongwayPicker presets

-- Via Lua API
require("longway").sync({ search = "epic:'Q1 Goals' state:unstarted" })
```

### 3. Markdown File Format

**3.1 File Naming Convention**

```
{workspace}/stories/{story_id}-{sanitized_title}.md
{workspace}/epics/{epic_id}-{sanitized_title}.md
```

Example: `stories/12345-implement-user-auth.md`

**3.2 Story Markdown Structure**

```markdown
---
shortcut_id: 12345
shortcut_type: story
shortcut_url: https://app.shortcut.com/workspace/story/12345
epic_id: 100
epic_name: "User Authentication"
iteration_id: 50
iteration_name: "Sprint 23"
team: "Infrastructure"
state: "In Progress"
story_type: feature
estimate: 3
owners:
  - name: "Eric Schmidt"
    id: "uuid-here"
labels:
  - "backend"
  - "security"
created_at: "2026-01-15T10:00:00Z"
updated_at: "2026-01-20T14:30:00Z"
local_updated_at: "2026-01-21T09:00:00Z"
sync_hash: "abc123"
tasks_hash: "task789"
comments_hash: "comm456"
---

# Implement User Authentication

## Description

<!-- BEGIN SHORTCUT SYNC:description -->
This is the synchronized description from Shortcut.
It supports **markdown** formatting.

### Acceptance Criteria
- Users can sign in with email/password
- Session tokens expire after 24 hours
- Failed attempts are rate-limited
<!-- END SHORTCUT SYNC:description -->

## Tasks

<!-- BEGIN SHORTCUT SYNC:tasks -->
- [x] Design authentication flow diagram <!-- task:101 @eric complete:true -->
- [x] Set up database schema for users <!-- task:102 @eric complete:true -->
- [ ] Implement password hashing with Argon2 <!-- task:103 @eric complete:false -->
- [ ] Create login API endpoint <!-- task:104 complete:false -->
- [ ] Add rate limiting middleware <!-- task:105 complete:false -->
- [ ] Write integration tests <!-- task:106 complete:false -->
<!-- END SHORTCUT SYNC:tasks -->

## Comments

<!-- BEGIN SHORTCUT SYNC:comments -->
---
**Eric Schmidt** · 2026-01-18 10:30 <!-- comment:201 -->

Should we use JWT or session tokens? I'm leaning toward JWT for statelessness but want to discuss trade-offs.

---
**Jane Doe** · 2026-01-18 14:15 <!-- comment:202 -->

JWT sounds good for our microservices architecture. Let's use short-lived access tokens (15min) with refresh tokens (7 days).

---
**Eric Schmidt** · 2026-01-20 09:00 <!-- comment:203 -->

Agreed. I've updated the design doc with the token strategy. Moving forward with implementation.

<!-- END SHORTCUT SYNC:comments -->

## Local Notes

<!-- This section is NOT synced to Shortcut -->
### Implementation Ideas
- Consider using Argon2 for password hashing
- Check existing OAuth infrastructure

### Links
- [Auth0 Best Practices](https://auth0.com/docs)
- [JWT.io Debugger](https://jwt.io)
```

**3.2.1 Task Format Specification**

Tasks are rendered as markdown checkboxes with inline metadata comments:

```markdown
- [x] Task description <!-- task:{id} @{owner_mention} complete:true -->
- [ ] Task description <!-- task:{id} complete:false -->
```

| Component | Description |
|-----------|-------------|
| `- [x]` / `- [ ]` | Checkbox state (complete/incomplete) |
| Task description | The task's description text |
| `task:{id}` | Shortcut task ID for sync tracking |
| `@{owner}` | Optional: task owner's mention name |
| `complete:bool` | Explicit completion state |

**New tasks** (created locally) omit the task ID until first push:

```markdown
- [ ] New task I'm adding locally <!-- task:new -->
```

**3.2.2 Comment Format Specification**

Comments are rendered as markdown blockquote-style entries:

```markdown
---
**{Author Name}** · {YYYY-MM-DD HH:MM} <!-- comment:{id} -->

{Comment text with markdown support}
```

| Component | Description |
|-----------|-------------|
| `---` | Visual separator between comments |
| `**{Author}**` | Comment author's display name (bold) |
| `{timestamp}` | Human-readable creation time |
| `comment:{id}` | Shortcut comment ID for sync tracking |
| Comment body | Full markdown content of the comment |

**New comments** (created locally) use a placeholder ID:

```markdown
---
**Eric Schmidt** · 2026-01-21 15:00 <!-- comment:new -->

Adding this comment from my editor.
```

**3.2.3 Sync Behavior for Tasks and Comments**

| Scenario | Behavior |
|----------|----------|
| New task locally | On push: create task via API, update ID in markdown |
| Task completed locally | On push: update task completion status |
| Task deleted locally | On push: delete task (with confirmation) |
| Task added remotely | On pull: append to tasks section |
| Task reordered | Position tracked by order in markdown |
| New comment locally | On push: create comment via API, update ID |
| Comment edited locally | **Not synced** - Shortcut API doesn't support editing |
| Comment deleted locally | On push: delete comment (with confirmation) |
| Comment added remotely | On pull: append to comments section |

**3.3 Epic Markdown Structure**

```markdown
---
shortcut_id: 100
shortcut_type: epic
shortcut_url: https://app.shortcut.com/workspace/epic/100
state: "In Progress"
owners:
  - name: "Eric Schmidt"
    id: "uuid-here"
objective_ids:
  - 5
labels:
  - "Q1"
planned_start_date: "2026-01-01"
deadline: "2026-03-31"
created_at: "2025-12-01T10:00:00Z"
updated_at: "2026-01-20T14:30:00Z"
local_updated_at: "2026-01-21T09:00:00Z"
sync_hash: "def456"
stats:
  num_stories_total: 15
  num_stories_done: 8
  num_points: 45
  num_points_done: 24
---

# User Authentication Epic

## Description

<!-- BEGIN SHORTCUT SYNC -->
Implement secure user authentication across all services.

### Goals
- Single sign-on capability
- OAuth2 provider support
- Audit logging for all auth events
<!-- END SHORTCUT SYNC -->

## Stories

| ID | Title | State | Owner | Points |
|----|-------|-------|-------|--------|
| [12345](./stories/12345-implement-user-auth.md) | Implement User Auth | In Progress | Eric | 3 |
| [12346](./stories/12346-oauth-integration.md) | OAuth Integration | Unstarted | - | 5 |

## Local Notes

<!-- Not synced -->
Architecture decisions and meeting notes go here.
```

**3.4 Sync Boundary Markers**

Each synced section uses typed markers:

```markdown
<!-- BEGIN SHORTCUT SYNC:description -->
Story description content
<!-- END SHORTCUT SYNC:description -->

<!-- BEGIN SHORTCUT SYNC:tasks -->
Task checklist content
<!-- END SHORTCUT SYNC:tasks -->

<!-- BEGIN SHORTCUT SYNC:comments -->
Comment thread content
<!-- END SHORTCUT SYNC:comments -->
```

| Section | Sync Direction | Notes |
|---------|---------------|-------|
| `description` | Bidirectional | Maps to story/epic description field |
| `tasks` | Bidirectional | Creates/updates/deletes tasks |
| `comments` | Pull + Create | Can add new, cannot edit existing |

- Content within markers syncs to Shortcut
- Content outside markers (Local Notes) is preserved locally only
- Markers are configurable in setup
- Each section has its own sync hash for granular change detection

### 4. Synchronization Behavior

**4.1 Pull (Shortcut → Local)**

```
┌─────────────────────────────────────────────────────────────┐
│                      PULL OPERATION                          │
├─────────────────────────────────────────────────────────────┤
│  1. Query Shortcut API with configured filters               │
│  2. For each story/epic:                                     │
│     a. Check if local file exists                           │
│     b. If no local file → create new markdown               │
│     c. If local file exists:                                │
│        - Compare sync_hash with remote updated_at           │
│        - If remote unchanged → skip                         │
│        - If remote changed & local unchanged → update local │
│        - If both changed → CONFLICT (see 4.3)               │
│  3. Update frontmatter metadata                             │
│  4. Report sync summary                                      │
└─────────────────────────────────────────────────────────────┘
```

**4.2 Push (Local → Shortcut)**

```
┌─────────────────────────────────────────────────────────────┐
│                      PUSH OPERATION                          │
├─────────────────────────────────────────────────────────────┤
│  1. Parse markdown file                                      │
│  2. Extract content between sync markers                     │
│  3. Compare with sync_hash to detect changes                │
│  4. If changed:                                              │
│     a. Fetch current remote state                           │
│     b. If remote also changed → CONFLICT (see 4.3)          │
│     c. If remote unchanged → PUT to Shortcut API            │
│     d. Update local sync_hash and local_updated_at          │
│  5. Report success/failure                                   │
└─────────────────────────────────────────────────────────────┘
```

**4.3 Conflict Resolution**

When both local and remote have changed since last sync:

1. **Notify user** with diff preview
2. **Options:**
   - `:LongwayResolve local` - Push local, overwrite remote
   - `:LongwayResolve remote` - Pull remote, overwrite local
   - `:LongwayResolve diff` - Open diff view (vimdiff style)
   - `:LongwayResolve manual` - Create conflict markers in file

```markdown
<!-- CONFLICT: Local version -->
Local content here
<!-- CONFLICT: Remote version -->
Remote content here
<!-- END CONFLICT -->
```

**4.4 Auto-sync on Save**

```lua
require("longway").setup({
  auto_push_on_save = true,  -- Push changes when saving .md in workspace
  auto_push_delay = 2000,    -- Debounce delay in ms
  confirm_push = false,      -- Prompt before pushing (default: false)
})
```

### 5. Commands and Keybindings

**5.1 Ex Commands**

| Command | Description |
|---------|-------------|
| `:LongwaySync [filters]` | Pull stories matching filters |
| `:LongwaySyncAll` | Pull all stories from all presets |
| `:LongwayPush` | Push current buffer to Shortcut |
| `:LongwayPushAll` | Push all modified files |
| `:LongwayOpen` | Open current story in browser |
| `:LongwayRefresh` | Refresh current buffer from Shortcut |
| `:LongwayStatus` | Show sync status of current file |
| `:LongwayResolve {strategy}` | Resolve conflict |
| `:LongwayPicker {type}` | Open Telescope picker |
| `:LongwayInfo` | Show plugin status and config |

**5.2 Snacks Picker Integration**

```lua
-- Stories picker with live preview
:LongwayPicker stories

-- Epics picker
:LongwayPicker epics

-- Preset selector
:LongwayPicker presets

-- Modified files (pending push)
:LongwayPicker modified

-- Comments on current story
:LongwayPicker comments
```

Pickers use `snacks.picker` with custom sources:

```lua
-- Example: Stories picker implementation
Snacks.picker({
  source = "longway_stories",
  prompt = "Shortcut Stories",
  format = function(item)
    return {
      { item.id, "Comment" },
      { " " },
      { item.name, "String" },
      { " [" .. item.state .. "]", "Type" },
    }
  end,
  preview = function(item)
    return require("longway.markdown.renderer").render_story(item)
  end,
  confirm = function(item)
    require("longway").open_story(item.id)
  end,
})

**5.3 Suggested Keybindings**

```lua
-- In plugin setup or user config
vim.keymap.set("n", "<leader>ws", ":LongwaySync<CR>", { desc = "Sync from Shortcut" })
vim.keymap.set("n", "<leader>wp", ":LongwayPush<CR>", { desc = "Push to Shortcut" })
vim.keymap.set("n", "<leader>wo", ":LongwayOpen<CR>", { desc = "Open in browser" })
vim.keymap.set("n", "<leader>wr", ":LongwayRefresh<CR>", { desc = "Refresh from Shortcut" })
vim.keymap.set("n", "<leader>wf", ":LongwayPicker stories<CR>", { desc = "Find stories" })
```

### 6. API Integration Details

**6.1 Shortcut API Endpoints Used**

| Operation | Endpoint | Method |
|-----------|----------|--------|
| **Stories** | | |
| Search stories | `/api/v3/search/stories` | GET |
| Get story | `/api/v3/stories/{id}` | GET |
| Update story | `/api/v3/stories/{id}` | PUT |
| **Epics** | | |
| List epics | `/api/v3/epics` | GET |
| Get epic | `/api/v3/epics/{id}` | GET |
| Update epic | `/api/v3/epics/{id}` | PUT |
| Get epic stories | `/api/v3/epics/{id}/stories` | GET |
| **Tasks** | | |
| Create task | `/api/v3/stories/{story-id}/tasks` | POST |
| Get task | `/api/v3/stories/{story-id}/tasks/{task-id}` | GET |
| Update task | `/api/v3/stories/{story-id}/tasks/{task-id}` | PUT |
| Delete task | `/api/v3/stories/{story-id}/tasks/{task-id}` | DELETE |
| **Comments** | | |
| List story comments | `/api/v3/stories/{story-id}/comments` | GET |
| Create comment | `/api/v3/stories/{story-id}/comments` | POST |
| Get comment | `/api/v3/stories/{story-id}/comments/{comment-id}` | GET |
| Delete comment | `/api/v3/stories/{story-id}/comments/{comment-id}` | DELETE |
| **Reference Data** | | |
| List iterations | `/api/v3/iterations` | GET |
| Get current member | `/api/v3/member` | GET |
| List teams | `/api/v3/groups` | GET |
| List workflow states | `/api/v3/workflows` | GET |
| List members | `/api/v3/members` | GET |

**6.2 Rate Limiting**

- Shortcut API limit: 200 requests/minute
- Implement exponential backoff on 429 responses
- Batch operations where possible (bulk story fetches)
- Cache member/team/workflow data locally (refresh on demand)

```lua
require("longway").setup({
  rate_limit = {
    requests_per_minute = 180,  -- Stay under limit
    retry_delay_base = 1000,    -- Base delay for retries (ms)
    max_retries = 3,
  },
})
```

**6.3 Search Query Syntax**

Leverage Shortcut's search operators for flexible filtering:

```
owner:me                     -- Current user's stories
owner:"Eric Schmidt"         -- Specific owner by name
team:Infrastructure          -- By team name
iteration:current            -- Current iteration
iteration:"Sprint 23"        -- Named iteration
epic:"User Auth"             -- By epic name
state:started                -- Workflow state
state:"In Progress"          -- Multi-word state
type:feature                 -- Story type
type:bug
type:chore
label:backend                -- By label
estimate:3                   -- By estimate
!has:owner                   -- Unassigned stories
created:2026-01-01..         -- Created after date
updated:..2026-01-15         -- Updated before date
```

### 7. Configuration

**7.1 Full Configuration Schema**

```lua
require("longway").setup({
  -- Authentication
  token = nil,  -- API token (or use SHORTCUT_API_TOKEN env var)
  token_file = nil,  -- Path to file containing token

  -- Workspace
  workspace_dir = vim.fn.expand("~/shortcut"),  -- Root directory for synced files
  stories_subdir = "stories",
  epics_subdir = "epics",

  -- File format
  filename_template = "{id}-{slug}",  -- {id}, {slug}, {type}
  slug_max_length = 50,
  slug_separator = "-",

  -- Sync markers
  sync_start_marker = "<!-- BEGIN SHORTCUT SYNC:{section} -->",
  sync_end_marker = "<!-- END SHORTCUT SYNC:{section} -->",

  -- Section sync toggles
  sync_sections = {
    description = true,  -- Always sync description
    tasks = true,        -- Sync tasks as checkboxes
    comments = true,     -- Sync comments
  },

  -- Task sync options
  tasks = {
    show_owners = true,          -- Include @owner in task metadata
    confirm_delete = true,       -- Confirm before deleting tasks
    auto_assign_on_complete = false, -- Assign self when completing unassigned task
  },

  -- Comment sync options
  comments = {
    max_pull = 50,              -- Max comments to pull per story
    show_timestamps = true,      -- Include timestamps in rendered comments
    timestamp_format = "%Y-%m-%d %H:%M", -- strftime format
    confirm_delete = true,       -- Confirm before deleting comments
  },

  -- Sync behavior
  auto_push_on_save = false,
  auto_push_delay = 2000,
  confirm_push = false,
  pull_on_open = false,  -- Auto-refresh when opening synced file

  -- Conflict handling
  conflict_strategy = "prompt",  -- "prompt", "local", "remote", "manual"

  -- Filter presets
  presets = {},
  default_preset = nil,

  -- Rate limiting
  rate_limit = {
    requests_per_minute = 180,
    retry_delay_base = 1000,
    max_retries = 3,
  },

  -- UI
  notify = true,  -- Show notifications
  notify_level = vim.log.levels.INFO,
  progress = true,  -- Show progress for bulk operations

  -- Snacks picker
  picker = {
    layout = "default",  -- or "vertical", "horizontal"
    preview = true,
    icons = true,
  },

  -- Debug
  debug = false,
  log_file = nil,  -- Path to log file
})
```

### 8. Data Storage

**8.1 Local Cache**

Store cached data in `{workspace_dir}/.longway/`:

```
.longway/
├── cache/
│   ├── members.json      -- Team member data
│   ├── workflows.json    -- Workflow states
│   ├── teams.json        -- Team/group data
│   └── iterations.json   -- Iteration data
├── state/
│   ├── sync_state.json   -- Last sync timestamps
│   └── conflicts.json    -- Unresolved conflicts
└── logs/
    └── longway.log       -- Debug log (if enabled)
```

**8.2 Sync State Tracking**

```json
{
  "stories": {
    "12345": {
      "local_hash": "abc123",
      "remote_updated_at": "2026-01-20T14:30:00Z",
      "last_synced_at": "2026-01-21T09:00:00Z",
      "local_file": "stories/12345-implement-user-auth.md"
    }
  },
  "epics": {
    "100": {
      "local_hash": "def456",
      "remote_updated_at": "2026-01-20T14:30:00Z",
      "last_synced_at": "2026-01-21T09:00:00Z",
      "local_file": "epics/100-user-authentication.md"
    }
  }
}
```

---

## Technical Architecture

### Module Structure

```
fnl/longway/
├── init.fnl           -- Main entry, setup(), public API
├── config.fnl         -- Configuration handling
├── api/
│   ├── client.fnl     -- HTTP client wrapper
│   ├── stories.fnl    -- Story API operations
│   ├── epics.fnl      -- Epic API operations
│   ├── tasks.fnl      -- Task API operations
│   ├── comments.fnl   -- Comment API operations
│   ├── search.fnl     -- Search query handling
│   └── rate_limit.fnl -- Rate limiting logic
├── sync/
│   ├── pull.fnl       -- Pull operations
│   ├── push.fnl       -- Push operations
│   ├── diff.fnl       -- Diff/conflict detection
│   ├── resolve.fnl    -- Conflict resolution
│   ├── auto.fnl       -- Auto-push on save with debounce
│   ├── tasks.fnl      -- Task sync logic
│   └── comments.fnl   -- Comment sync logic
├── markdown/
│   ├── parser.fnl     -- Parse markdown + frontmatter
│   ├── renderer.fnl   -- Render story/epic to markdown
│   ├── frontmatter.fnl-- YAML frontmatter handling
│   ├── tasks.fnl      -- Parse/render task checkboxes
│   └── comments.fnl   -- Parse/render comment sections
├── ui/
│   ├── notify.fnl     -- Notification helpers
│   ├── confirm.fnl    -- Confirmation prompts
│   ├── picker.fnl     -- Snacks picker integration
│   ├── progress.fnl   -- Progress indicators
│   └── statusline.fnl -- Statusline component (lualine, custom)
├── cache/
│   ├── store.fnl      -- Local cache management
│   └── state.fnl      -- Sync state tracking
└── util/
    ├── slug.fnl       -- Title to slug conversion
    ├── hash.fnl       -- Content hashing
    └── async.fnl      -- Async operation helpers
```

### Dependencies

**Required:**
- `plenary.nvim` - Async utilities, HTTP client, path handling

**Optional:**
- `folke/snacks.nvim` - Picker UI (stories, epics, presets, modified files picker)
- `nvim-notify` - For enhanced notifications (falls back to vim.notify)

### Fennel/Lua Compilation

Using nfnl for Fennel → Lua compilation:
- Source in `fnl/longway/`
- Compiled output in `lua/longway/`
- Committed Lua for users without nfnl

---

## Implementation Phases

### Phase 1: Core Foundation (v0.1.0) ✓
- [x] API client with authentication
- [x] Basic story pull by ID
- [x] Markdown file creation with frontmatter
- [x] Manual push command for descriptions
- [x] Basic error handling

### Phase 2: Filtering & Search (v0.2.0) ✓
- [x] Search query parsing
- [x] Filter presets
- [x] Bulk story pull
- [x] Epic pull with story list
- [x] Cache for members/workflows

### Phase 3: Task Synchronization (v0.3.0) ✓
- [x] Task parsing from markdown checkboxes
- [x] Task rendering with metadata comments
- [x] Task creation (local → Shortcut)
- [x] Task completion sync (bidirectional)
- [x] Task deletion with confirmation

### Phase 4: Comment Synchronization (v0.4.0) ✓
- [x] Comment pull and rendering
- [x] Comment creation (local → Shortcut)
- [x] Member name resolution for display
- [x] Comment deletion with confirmation
- [x] Timestamp formatting and timezone handling

### Phase 5: Bidirectional Sync & Conflicts (v0.5.0) ✓
- [x] Change detection (local/remote) for all sections
- [x] Auto-push on save
- [x] Conflict detection per section
- [x] Basic conflict resolution

### Phase 6: UI Polish (v0.6.0) ✓
- [x] Snacks pickers (stories, epics, presets, modified)
- [x] Progress indicators
- [x] Notification improvements
- [x] Status line integration

### Phase 7: Advanced Features (v1.0.0)
- [ ] Advanced conflict resolution (vimdiff)
- [ ] Batch operations
- [ ] Offline queue
- [ ] Documentation
- [ ] Test coverage

---

## Success Metrics

1. **Sync Reliability**: <1% failed syncs due to plugin bugs
2. **Performance**: Pull 50 stories in <5 seconds
3. **Conflict Rate**: Clear conflict UX, <5% require manual resolution
4. **Adoption**: Positive feedback from initial users

---

## Open Questions

1. **Comment editing**: Shortcut API doesn't support editing comments. Should we warn users? Allow local-only edits?
2. **Comment threading**: Shortcut supports threaded comments. Flatten for v1 or attempt nested rendering?
3. **Task owners**: Should unassigned tasks prompt for owner on completion?
4. **Story creation**: Allow creating new stories from markdown? Risk of duplicates.
5. **Multi-workspace**: Support multiple Shortcut workspaces?
6. **Git integration**: Auto-commit synced changes? Branch per epic?
7. **Attachment references**: Should we at least list attachments (without syncing content)?
8. **External links**: Sync external_links field as a section?

---

## Appendix A: Shortcut API Response Examples

### Story Response (with tasks)

```json
{
  "id": 12345,
  "name": "Implement User Authentication",
  "description": "Markdown description here...",
  "story_type": "feature",
  "workflow_state_id": 500000001,
  "epic_id": 100,
  "iteration_id": 50,
  "group_id": "uuid-team",
  "owner_ids": ["uuid-owner"],
  "requested_by_id": "uuid-requester",
  "follower_ids": ["uuid-1", "uuid-2"],
  "label_ids": [1, 2],
  "labels": [
    {"id": 1, "name": "backend"},
    {"id": 2, "name": "security"}
  ],
  "tasks": [
    {
      "id": 101,
      "description": "Design authentication flow diagram",
      "complete": true,
      "owner_ids": ["uuid-owner"],
      "created_at": "2026-01-15T10:00:00Z",
      "updated_at": "2026-01-16T14:00:00Z",
      "position": 1
    },
    {
      "id": 102,
      "description": "Set up database schema for users",
      "complete": true,
      "owner_ids": ["uuid-owner"],
      "created_at": "2026-01-15T10:05:00Z",
      "updated_at": "2026-01-17T09:00:00Z",
      "position": 2
    },
    {
      "id": 103,
      "description": "Implement password hashing with Argon2",
      "complete": false,
      "owner_ids": ["uuid-owner"],
      "created_at": "2026-01-15T10:10:00Z",
      "updated_at": "2026-01-15T10:10:00Z",
      "position": 3
    }
  ],
  "estimate": 3,
  "deadline": "2026-02-01T00:00:00Z",
  "created_at": "2026-01-15T10:00:00Z",
  "updated_at": "2026-01-20T14:30:00Z",
  "app_url": "https://app.shortcut.com/workspace/story/12345"
}
```

### Comment Response

```json
{
  "id": 201,
  "author_id": "uuid-author",
  "text": "Should we use JWT or session tokens? I'm leaning toward JWT for statelessness but want to discuss trade-offs.",
  "created_at": "2026-01-18T10:30:00Z",
  "updated_at": "2026-01-18T10:30:00Z",
  "story_id": 12345,
  "app_url": "https://app.shortcut.com/workspace/story/12345#comment-201"
}
```

### Task Create Request

```json
{
  "description": "New task description",
  "complete": false,
  "owner_ids": ["uuid-owner"]
}
```

### Task Update Request

```json
{
  "complete": true
}
```

### Comment Create Request

```json
{
  "text": "Comment text with **markdown** support.",
  "author_id": "uuid-author"
}
```

### Epic Response

```json
{
  "id": 100,
  "name": "User Authentication",
  "description": "Epic description...",
  "state": "in progress",
  "epic_state_id": 500000010,
  "owner_ids": ["uuid-owner"],
  "follower_ids": ["uuid-1"],
  "objective_ids": [5],
  "label_ids": [3],
  "labels": [{"id": 3, "name": "Q1"}],
  "planned_start_date": "2026-01-01",
  "deadline": "2026-03-31",
  "stats": {
    "num_stories_total": 15,
    "num_stories_done": 8,
    "num_points": 45,
    "num_points_done": 24
  },
  "created_at": "2025-12-01T10:00:00Z",
  "updated_at": "2026-01-20T14:30:00Z",
  "app_url": "https://app.shortcut.com/workspace/epic/100"
}
```

---

## Appendix B: Search Operator Reference

From Shortcut documentation, supported search operators:

| Operator | Description | Example |
|----------|-------------|---------|
| `owner:` | Story owner | `owner:me`, `owner:"Jane Doe"` |
| `requester:` | Story requester | `requester:me` |
| `team:` | Team/group | `team:Engineering` |
| `epic:` | Epic name/ID | `epic:"Q1 Goals"`, `epic:100` |
| `iteration:` | Iteration | `iteration:current`, `iteration:"Sprint 23"` |
| `state:` | Workflow state | `state:started`, `state:"In Progress"` |
| `type:` | Story type | `type:feature`, `type:bug`, `type:chore` |
| `label:` | Label | `label:backend` |
| `estimate:` | Point estimate | `estimate:3`, `estimate:1..5` |
| `project:` | Project | `project:"Mobile App"` |
| `created:` | Creation date | `created:2026-01-01..` |
| `updated:` | Update date | `updated:..2026-01-15` |
| `completed:` | Completion date | `completed:today` |
| `due:` | Due date | `due:tomorrow` |
| `has:` | Has attribute | `has:owner`, `has:deadline` |
| `!has:` | Missing attribute | `!has:estimate` |
| `is:` | State boolean | `is:started`, `is:done`, `is:blocked` |
| `!is:` | Not state | `!is:archived` |

---

*End of PRD*
