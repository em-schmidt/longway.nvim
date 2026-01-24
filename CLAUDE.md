# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

longway.nvim is a Fennel-based Neovim plugin for bidirectional synchronization between [Shortcut](https://shortcut.com) and local markdown files. Users can pull stories/epics from Shortcut, edit them as markdown in Neovim, and push changes back.

**Current Status:** Phase 1 complete (v0.1.0) - Core foundation with story pull/push

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
│   └── stories.fnl    # Shortcut Stories API operations
├── sync/
│   ├── pull.fnl       # Fetch stories from API → markdown files
│   └── push.fnl       # Parse markdown → push changes to API
├── markdown/
│   ├── parser.fnl     # Parse markdown (frontmatter + sync sections)
│   ├── renderer.fnl   # Convert API responses to markdown
│   └── frontmatter.fnl# YAML frontmatter handling
├── ui/
│   └── notify.fnl     # User notifications
└── util/
    ├── slug.fnl       # Title → filename slug
    └── hash.fnl       # Content hashing for change detection

fnl/longway-spec/      # Test specifications (mirrors source structure)
lua/longway/           # Compiled Lua (committed for distribution)
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

- **Runtime:** Neovim >= 0.9.0, plenary.nvim
- **Development:** nfnl (Fennel compiler), plenary.busted (tests)

## Development Workflow

1. Edit Fennel files in `fnl/longway/`
2. Compile: `make compile` (or nfnl auto-compiles if configured) 
3. Test: `make test`
4. Commit both `.fnl` source and compiled `.lua` files

## Documentation

- `docs/PRD.md` - Comprehensive product requirements and phase roadmap
- `docs/TESTING_PRD.md` - Testing infrastructure plan
- `docs/IMPLEMENTATION_PLAN.md` - Phase breakdown with tasks
- `CONTRIBUTING.md` - Development setup guide
