# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

longway.nvim is a Fennel-based Neovim plugin for bidirectional synchronization between [Shortcut](https://shortcut.com) and local markdown files. Users can pull stories/epics from Shortcut, edit them as markdown in Neovim, and push changes back.

**Current Status:** Phase 6 complete (v0.6.0) - UI polish with Snacks picker integration, progress tracking, and statusline component

## Build Commands

```bash
make test-deps   # Install test dependencies (one-time setup)
make compile     # Compile all Fennel files to Lua
make test        # Run the complete test suite
make clean       # Remove test artifacts
```

Or use scripts directly:
```bash
./scripts/setup-test-deps   # Install plenary.nvim for tests
./scripts/test              # Run tests via headless Neovim
./scripts/compile           # Compile Fennel to Lua using nfnl
```

## Running Specific Tests

Tests use Plenary.busted. To run a specific test file:
```bash
nvim --headless -u .test/init.lua -c "PlenaryBustedFile lua/longway-spec/markdown/parser_spec.lua"
```

## Architecture

```
fnl/longway/           # Fennel source (edit these)
├── init.fnl           # Entry point with setup() and public API
├── config.fnl         # Configuration management
├── core.fnl           # Business logic (pull, push, refresh, open, status)
├── api/
│   ├── client.fnl     # HTTP client (wraps plenary.curl)
│   ├── stories.fnl    # Shortcut Stories API operations
│   ├── tasks.fnl      # Tasks API (CRUD + batch)
│   ├── comments.fnl   # Comments API (CRUD + batch)
│   ├── epics.fnl      # Epics API
│   ├── members.fnl    # Members API + name cache
│   ├── workflows.fnl  # Workflows API
│   ├── iterations.fnl # Iterations API
│   ├── teams.fnl      # Teams API
│   └── search.fnl     # Search API
├── sync/
│   ├── pull.fnl       # Fetch from API → markdown files
│   ├── push.fnl       # Parse markdown → push to API (with conflict detection)
│   ├── tasks.fnl      # Task diff, push, pull, merge logic
│   ├── comments.fnl   # Comment diff, push, pull logic
│   ├── diff.fnl       # Section-level change detection (local vs. frontmatter hashes)
│   ├── resolve.fnl    # Conflict resolution strategies (local/remote/manual)
│   └── auto.fnl       # Auto-push on save with debounce
├── markdown/
│   ├── parser.fnl     # Parse markdown (frontmatter + sync sections)
│   ├── renderer.fnl   # Convert API responses → markdown
│   ├── frontmatter.fnl# YAML frontmatter handling
│   ├── tasks.fnl      # Task parsing, rendering, owner resolution
│   └── comments.fnl   # Comment parsing, rendering, author resolution
├── ui/
│   ├── notify.fnl     # User notifications (with Snacks.notify integration)
│   ├── confirm.fnl    # Confirmation prompts (task/comment deletion)
│   ├── progress.fnl   # Progress tracking for bulk operations
│   ├── picker.fnl     # Snacks picker sources (stories/epics/presets/modified/comments)
│   └── statusline.fnl # Statusline component API (lualine-compatible)
├── cache/
│   └── store.fnl      # In-memory cache
└── util/
    ├── slug.fnl       # Title → filename slug
    └── hash.fnl       # Content + task + comment hashing

fnl/longway-spec/      # Test specifications (mirrors source structure)
lua/longway/           # Compiled Lua (committed for distribution)
lua/longway-spec/      # Compiled tests (committed)
plugin/longway.lua     # User command definitions
```

## Key Patterns

- **Language:** Fennel (Lisp dialect) → compiles to Lua. Edit `.fnl` files, run `make compile`.
- **Naming:** kebab-case for functions/variables (e.g., `get-token`, `pull-story`)
- **Module exports:** Each module exports `M` table with public functions
- **Return values:** Functions return `{:ok bool :data value :error string}` tuples
- **Config access:** Use `(config.get)` to access configuration
- **HTTP:** plenary.curl with errors caught via `pcall`
- **Sync markers:** HTML comments (`<!-- BEGIN SHORTCUT SYNC:{section} -->`) preserve sections in markdown

## Dependencies

- **Runtime:** Neovim >= 0.10.0, plenary.nvim
- **Optional:** snacks.nvim (for `:LongwayPicker` and enhanced notifications)
- **Development:** nfnl (Fennel compiler), plenary.busted (tests)

## Development Workflow

1. Edit Fennel files in `fnl/longway/`
2. Compile: `make compile` (or nfnl auto-compiles if configured) 
3. Test: `make test`
4. Commit both `.fnl` source and compiled `.lua` files

## Key Patterns

### Single Source of Truth

Each entity type has one module owning all parsing and rendering:
- `markdown/tasks.fnl` owns task parsing (`parse-line`, `parse-section`) and rendering (`format-api-tasks`, `render-task`)
- `markdown/comments.fnl` owns comment parsing (`parse-block`, `parse-section`) and rendering (`format-api-comments`, `render-comment`)
- `markdown/parser.fnl` and `markdown/renderer.fnl` delegate to these modules
- `sync/tasks.fnl` and `sync/comments.fnl` delegate to their respective markdown modules for formatting

### Comment Sync Notes

- Shortcut API does not support editing comments — edits trigger a warning, not an API call
- Authors are pre-resolved from UUID to display name via `members.resolve-name` before reaching the renderer
- Comments use `comments_hash` in frontmatter for change detection (parallel to `tasks_hash`)
- Timestamp formatting uses `os.date` with `config.comments.timestamp_format` (strftime format)

### Conflict Detection & Resolution (Phase 5)

- All sync state lives in YAML frontmatter — no separate state files
- `sync_hash`, `tasks_hash`, `comments_hash` track baseline hashes at last sync
- `updated_at` tracks remote timestamp at last sync
- `conflict_sections` (list or nil) tracks which sections have unresolved conflicts
- Pre-push: `sync/diff.fnl` compares current content hashes vs. frontmatter hashes (local changes) and fetches remote `updated_at` (remote changes)
- If both local and remote changed → conflict detected, `conflict_sections` set in frontmatter, user notified
- Resolution via `:LongwayResolve local|remote|manual`
- Auto-push on save: opt-in via `auto_push_on_save` config, debounced via `vim.uv.new_timer`, skips push when hashes match (prevents push-back loop after pull)

## Documentation

- `docs/PRD.md` - Comprehensive product requirements and phase roadmap
- `docs/TESTING_PRD.md` - Testing infrastructure plan
- `docs/IMPLEMENTATION_PLAN.md` - Phase breakdown with tasks
- `docs/PHASE_4_PLAN.md` - Phase 4 comment synchronization implementation plan
- `docs/PHASE_5_PLAN.md` - Phase 5 bidirectional sync & conflicts implementation plan
- `docs/PHASE_6_PLAN.md` - Phase 6 UI polish implementation plan
- `CONTRIBUTING.md` - Development setup guide
