# Phase 3: Task Synchronization Implementation Plan

**Version:** v0.3.0
**Goal:** Bidirectional task synchronization between Shortcut and markdown checkboxes

---

## Overview

Phase 3 adds the ability to:
- Pull tasks from Shortcut stories and render them as markdown checkboxes
- Detect local task changes (completion, edits, additions, deletions)
- Push task changes back to Shortcut
- Handle task owner assignment
- Track task sync state for change detection

---

## Current State Analysis

### Already Implemented

| Component | Location | Status |
|-----------|----------|--------|
| Task API endpoints | `fnl/longway/api/stories.fnl:39-56` | Complete |
| Basic task parser | `fnl/longway/markdown/parser.fnl:30-63` | Partial |
| Basic task renderer | `fnl/longway/markdown/renderer.fnl:64-86` | Partial |
| Task section markers | Configured in `config.fnl` | Complete |
| Member cache | `fnl/longway/api/members.fnl` | Complete |

### Missing Components

| Component | Planned Location | Description |
|-----------|------------------|-------------|
| Dedicated Task API | `fnl/longway/api/tasks.fnl` | Cleaner separation from stories |
| Task Sync Logic | `fnl/longway/sync/tasks.fnl` | Core sync orchestration |
| Task Hash Tracking | `fnl/longway/util/hash.fnl` | Task-specific hashing |
| Owner Resolution | `fnl/longway/markdown/tasks.fnl` | UUID ↔ mention name mapping |
| Push Integration | `fnl/longway/sync/push.fnl` | Wire tasks into push flow |
| Confirmation UI | `fnl/longway/ui/confirm.fnl` | Delete confirmation prompts |

---

## Implementation Tasks

### Task 1: Create Dedicated Task API Module

**File:** `fnl/longway/api/tasks.fnl`

Move task functions from `stories.fnl` to a dedicated module for cleaner organization.

```fennel
;; API Functions
(fn M.create [story-id task-data])    ;; POST /stories/{id}/tasks
(fn M.update [story-id task-id data]) ;; PUT /stories/{id}/tasks/{task-id}
(fn M.delete [story-id task-id])      ;; DELETE /stories/{id}/tasks/{task-id}
(fn M.list [story-id])                ;; GET /stories/{id} (tasks embedded in story)
```

**Task data schema:**
```fennel
{:description "Task text"
 :complete false
 :owner_ids ["uuid-1" "uuid-2"]}
```

**Acceptance Criteria:**
- [ ] Create new `fnl/longway/api/tasks.fnl` module
- [ ] Implement all CRUD operations with proper error handling
- [ ] Add tests in `fnl/longway-spec/api/tasks_spec.fnl`

---

### Task 2: Enhance Task Markdown Module

**File:** `fnl/longway/markdown/tasks.fnl` (new dedicated module)

Create a comprehensive task markdown handling module.

#### 2.1 Task Parsing

Parse the markdown format:
```markdown
- [x] Task description <!-- task:123 @owner complete:true -->
- [ ] New task without ID <!-- task:new -->
- [ ] Plain task with no metadata
```

**Parser output structure:**
```fennel
{:description "Task description"
 :id 123                    ;; nil for new tasks
 :complete true
 :is_new false
 :owner_mention "owner"     ;; extracted from @mention
 :owner_ids ["uuid"]        ;; resolved from mention
 :position 1}               ;; order in list
```

#### 2.2 Task Rendering

Render tasks with full metadata:
```fennel
(fn render-task [task opts])
;; opts: {:show_owners bool :resolve_names bool}
```

**Output format:**
```markdown
- [x] Task description <!-- task:123 @eric complete:true -->
```

#### 2.3 Owner Resolution

Integrate with member cache:
```fennel
(fn resolve-owner-mention [mention])   ;; @name -> uuid
(fn resolve-owner-id [uuid])           ;; uuid -> display name
(fn get-current-user-id [])            ;; for auto-assign
```

**Acceptance Criteria:**
- [ ] Create `fnl/longway/markdown/tasks.fnl`
- [ ] Parse all task format variations
- [ ] Handle missing/malformed metadata gracefully
- [ ] Resolve owner mentions bidirectionally
- [ ] Add comprehensive tests

---

### Task 3: Implement Task Sync Logic

**File:** `fnl/longway/sync/tasks.fnl`

This is the core sync orchestration module.

#### 3.1 Task Diff Detection

Compare local tasks against remote to detect changes:

```fennel
(fn diff-tasks [local-tasks remote-tasks])
;; Returns:
{:created [tasks]      ;; local tasks with no ID (task:new)
 :updated [tasks]      ;; local tasks with changed completion/description
 :deleted [task-ids]   ;; remote tasks missing from local
 :unchanged [tasks]}   ;; no changes needed
```

**Change detection logic:**
| Local State | Remote State | Action |
|-------------|--------------|--------|
| `task:new` | - | Create task via API |
| ID present, completion changed | ID exists | Update task |
| ID present, description changed | ID exists | Update task |
| Missing (ID was in previous sync) | ID exists | Delete task (with confirm) |
| Present | Missing | Was deleted remotely, remove from local |

#### 3.2 Push Tasks

```fennel
(fn push-tasks [story-id local-tasks remote-tasks opts])
;; opts: {:confirm_delete bool :dry_run bool}
;; Returns: {:ok bool :created n :updated n :deleted n :errors []}
```

**Push flow:**
1. Compute diff between local and remote tasks
2. Create new tasks (POST), capture returned IDs
3. Update modified tasks (PUT)
4. Delete removed tasks (DELETE) with confirmation if configured
5. Return updated task list with new IDs

#### 3.3 Pull Tasks

```fennel
(fn pull-tasks [story])
;; Returns: {:ok bool :tasks [rendered-tasks]}
```

**Pull flow:**
1. Extract tasks from story response
2. Resolve owner IDs to display names
3. Sort by position
4. Return formatted task list

#### 3.4 Merge Tasks

Handle the case where both local and remote have changes:

```fennel
(fn merge-tasks [local-tasks remote-tasks])
;; Returns: {:tasks [merged] :conflicts []}
```

**Merge strategy:**
- New local tasks → keep (will be created on push)
- New remote tasks → append to local
- Both changed same task → flag as conflict
- Deleted locally, changed remotely → flag as conflict

**Acceptance Criteria:**
- [ ] Create `fnl/longway/sync/tasks.fnl`
- [ ] Implement diff detection
- [ ] Implement push flow with error handling
- [ ] Implement pull flow with owner resolution
- [ ] Add merge strategy for concurrent changes
- [ ] Comprehensive tests for all scenarios

---

### Task 4: Task Hash Tracking

**File:** Update `fnl/longway/util/hash.fnl`

Add task-specific hashing for change detection.

```fennel
(fn M.tasks-hash [tasks])
;; Compute hash from task list for comparison
;; Include: id, description, complete state, owner_ids
```

**Hash computation:**
```fennel
;; Sort tasks by ID for consistent ordering
;; Concatenate: id|description|complete|owners
;; Apply DJB2 hash
```

Update frontmatter to track `tasks_hash`:
```yaml
---
sync_hash: "abc123"      # description hash
tasks_hash: "def456"     # tasks section hash
comments_hash: "ghi789"  # comments section hash (Phase 4)
---
```

**Acceptance Criteria:**
- [ ] Add `tasks-hash` function to `hash.fnl`
- [ ] Update frontmatter generation to include `tasks_hash`
- [ ] Update parser to extract `tasks_hash`
- [ ] Add tests for hash stability

---

### Task 5: Integrate into Push Flow

**File:** Update `fnl/longway/sync/push.fnl`

Extend `push-story` to handle tasks.

```fennel
(fn M.push-story [story-id parsed opts]
  ;; Existing: push description
  ;; New: push tasks if changed
  (let [cfg (config.get)]
    ;; Push description (existing)
    (when (description-changed? parsed)
      (push-description story-id parsed.description))

    ;; Push tasks (new)
    (when cfg.sync_sections.tasks
      (let [remote (stories-api.get story-id)
            result (tasks-sync.push-tasks story-id
                                          parsed.tasks
                                          remote.data.tasks
                                          {:confirm_delete cfg.tasks.confirm_delete})]
        ;; Handle result, update local file with new IDs
        ...))))
```

**New tasks in markdown should get IDs:**
```markdown
;; Before push:
- [ ] New task <!-- task:new -->

;; After push (ID 456 assigned by Shortcut):
- [ ] New task <!-- task:456 complete:false -->
```

**Acceptance Criteria:**
- [ ] Modify `push-story` to include task sync
- [ ] Update local file with assigned task IDs after creation
- [ ] Handle partial failures gracefully
- [ ] Add tests for push flow

---

### Task 6: Integrate into Pull Flow

**File:** Update `fnl/longway/sync/pull.fnl`

Tasks are already fetched as part of story data. Ensure they're properly rendered.

```fennel
;; In pull-story, story.tasks contains task data
;; renderer.render-story already handles tasks
;; Ensure owner names are resolved before rendering
```

**Enhancement needed:**
- Resolve `owner_ids` UUIDs to display names using member cache
- Handle missing member data gracefully

**Acceptance Criteria:**
- [ ] Verify tasks render correctly on pull
- [ ] Add owner name resolution
- [ ] Handle API edge cases (empty tasks, missing owners)
- [ ] Add tests for pull scenarios

---

### Task 7: Confirmation UI

**File:** `fnl/longway/ui/confirm.fnl` (new)

Add confirmation prompts for destructive operations.

```fennel
(fn M.confirm [message callback])
;; Uses vim.ui.select or vim.fn.confirm

(fn M.confirm-delete-tasks [tasks callback])
;; "Delete 3 tasks? [y/n]"
;; Lists task descriptions for review
```

**Configuration:**
```lua
require("longway").setup({
  tasks = {
    confirm_delete = true,  -- Prompt before deleting tasks
  },
})
```

**Acceptance Criteria:**
- [ ] Create `fnl/longway/ui/confirm.fnl`
- [ ] Implement confirmation flow
- [ ] Integrate into task push flow
- [ ] Respect `confirm_delete` config
- [ ] Add tests (may need mocking)

---

### Task 8: Update Commands

**File:** Update `plugin/longway.lua`

No new commands needed - tasks sync as part of existing `:LongwayPush` and `:LongwayPull`.

**Optional:** Add status information:
```
:LongwayStatus
> Story #12345: Implement User Auth
> Description: synced (hash: abc123)
> Tasks: 3 local, 3 remote, 0 pending changes
> Last sync: 2026-01-21 09:00
```

**Acceptance Criteria:**
- [ ] Verify `:LongwayPush` syncs tasks
- [ ] Verify `:LongwayPull` renders tasks
- [ ] Update `:LongwayStatus` to show task info

---

### Task 9: Comprehensive Tests

**Files:** `fnl/longway-spec/`

Create test files for all new modules:

```
fnl/longway-spec/
├── api/
│   └── tasks_spec.fnl           # Task API tests
├── markdown/
│   └── tasks_spec.fnl           # Task parser/renderer tests
├── sync/
│   └── tasks_spec.fnl           # Task sync logic tests
└── integration/
    └── task_sync_spec.fnl       # End-to-end task sync tests
```

**Test scenarios:**

| Scenario | Test |
|----------|------|
| Parse complete task | `- [x] Task <!-- task:123 @eric complete:true -->` |
| Parse incomplete task | `- [ ] Task <!-- task:123 complete:false -->` |
| Parse new task | `- [ ] Task <!-- task:new -->` |
| Parse plain task | `- [ ] Task with no metadata` |
| Render task with owner | Include @mention |
| Diff: create new | Local has task:new, remote doesn't |
| Diff: update completion | Local [x], remote incomplete |
| Diff: delete | Local missing, remote has ID |
| Push: create | API called with correct data |
| Push: update | API called with changed fields |
| Push: delete | Confirmation shown, API called |
| Pull: render | Tasks appear in correct format |
| Owner resolution | UUID → display name |

**Acceptance Criteria:**
- [ ] 80%+ code coverage for new modules
- [ ] All edge cases tested
- [ ] Integration tests pass

---

## File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `fnl/longway/api/tasks.fnl` | Create | Dedicated task API module |
| `fnl/longway/api/stories.fnl` | Update | Remove task functions (moved) |
| `fnl/longway/markdown/tasks.fnl` | Create | Task parse/render module |
| `fnl/longway/markdown/parser.fnl` | Update | Import tasks module |
| `fnl/longway/markdown/renderer.fnl` | Update | Import tasks module |
| `fnl/longway/sync/tasks.fnl` | Create | Task sync orchestration |
| `fnl/longway/sync/push.fnl` | Update | Integrate task push |
| `fnl/longway/sync/pull.fnl` | Update | Ensure task render |
| `fnl/longway/util/hash.fnl` | Update | Add tasks-hash function |
| `fnl/longway/ui/confirm.fnl` | Create | Confirmation prompts |
| `fnl/longway/config.fnl` | Update | Add tasks config validation |
| `fnl/longway-spec/api/tasks_spec.fnl` | Create | API tests |
| `fnl/longway-spec/markdown/tasks_spec.fnl` | Create | Parser/renderer tests |
| `fnl/longway-spec/sync/tasks_spec.fnl` | Create | Sync logic tests |

---

## Markdown Format Reference

### Task Line Format

```markdown
- [x] Task description <!-- task:{id} @{owner} complete:true -->
- [ ] Task description <!-- task:{id} complete:false -->
- [ ] New task <!-- task:new -->
```

| Component | Required | Description |
|-----------|----------|-------------|
| `- [x]` / `- [ ]` | Yes | Checkbox state |
| Task description | Yes | The task text |
| `task:{id}` | Yes | Shortcut task ID or "new" |
| `@{owner}` | No | Owner mention name |
| `complete:{bool}` | Yes | Explicit completion state |

### Full Tasks Section

```markdown
## Tasks

<!-- BEGIN SHORTCUT SYNC:tasks -->
- [x] Design authentication flow <!-- task:101 @eric complete:true -->
- [x] Set up database schema <!-- task:102 @eric complete:true -->
- [ ] Implement password hashing <!-- task:103 @eric complete:false -->
- [ ] Create login endpoint <!-- task:104 complete:false -->
- [ ] New task I added locally <!-- task:new -->
<!-- END SHORTCUT SYNC:tasks -->
```

---

## API Reference

### Create Task
```
POST /api/v3/stories/{story-id}/tasks
Body: {"description": "string", "complete": bool, "owner_ids": ["uuid"]}
Response: Task object with assigned ID
```

### Update Task
```
PUT /api/v3/stories/{story-id}/tasks/{task-id}
Body: {"complete": bool, "description": "string"}
Response: Updated task object
```

### Delete Task
```
DELETE /api/v3/stories/{story-id}/tasks/{task-id}
Response: 204 No Content
```

---

## Implementation Order

1. **Task API Module** - Foundation for all operations
2. **Task Markdown Module** - Parse and render tasks
3. **Task Hash Tracking** - Change detection
4. **Task Sync Logic** - Core sync orchestration
5. **Push Integration** - Wire into existing push flow
6. **Pull Integration** - Verify rendering works
7. **Confirmation UI** - Add delete confirmations
8. **Tests** - Comprehensive test coverage
9. **Documentation** - Update README with task sync info

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Task ID collision | Use Shortcut-assigned IDs only |
| Owner resolution fails | Fallback to UUID display |
| API rate limits | Batch operations where possible |
| Partial push failure | Track which tasks succeeded, report errors |
| Concurrent edits | Hash comparison before push |

---

## Success Criteria

Phase 3 is complete when:

1. `:LongwayPull {id}` renders tasks as checkboxes with metadata
2. Toggling a checkbox and running `:LongwayPush` updates Shortcut
3. Adding a new task line (`- [ ] New task <!-- task:new -->`) creates it in Shortcut
4. Removing a task line (with confirmation) deletes it from Shortcut
5. Task owners display correctly with resolved names
6. All tests pass
7. Documentation updated

---

*End of Phase 3 Plan*
