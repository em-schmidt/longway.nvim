# Contributing to longway.nvim

Thank you for your interest in contributing to longway.nvim! This guide will help you get started.

## Development Setup

### Prerequisites

- Neovim >= 0.10.0
- [nfnl](https://github.com/Olical/nfnl) (for Fennel compilation)
- Git

### Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/em-schmidt/longway.nvim.git
   cd longway.nvim
   ```

2. Install test dependencies:
   ```bash
   ./scripts/setup-test-deps
   ```

3. If you have nfnl installed in Neovim, Fennel files will auto-compile on save.

## Project Structure

```
.
├── fnl/longway/           # Fennel source files
│   ├── init.fnl          # Main entry point
│   ├── config.fnl        # Configuration
│   ├── core.fnl          # Core functions
│   ├── api/
│   │   ├── client.fnl    # HTTP client (wraps plenary.curl)
│   │   ├── stories.fnl   # Stories API
│   │   ├── tasks.fnl     # Tasks API (CRUD + batch)
│   │   ├── comments.fnl  # Comments API (CRUD + batch)
│   │   ├── epics.fnl     # Epics API
│   │   ├── members.fnl   # Members API + name cache
│   │   ├── workflows.fnl # Workflows API
│   │   ├── iterations.fnl# Iterations API
│   │   ├── teams.fnl     # Teams API
│   │   └── search.fnl    # Search API
│   ├── sync/
│   │   ├── pull.fnl      # Fetch from API → markdown files
│   │   ├── push.fnl      # Parse markdown → push to API
│   │   ├── tasks.fnl     # Task diff, push, pull, merge logic
│   │   └── comments.fnl  # Comment diff, push, pull logic
│   ├── markdown/
│   │   ├── parser.fnl    # Parse markdown (frontmatter + sync sections)
│   │   ├── renderer.fnl  # Convert API responses → markdown
│   │   ├── tasks.fnl     # Task parsing, rendering, owner resolution
│   │   ├── comments.fnl  # Comment parsing, rendering, author resolution
│   │   └── frontmatter.fnl # YAML frontmatter handling
│   ├── ui/
│   │   ├── notify.fnl    # User notifications
│   │   └── confirm.fnl   # Confirmation prompts (task/comment deletion)
│   ├── util/
│   │   ├── hash.fnl      # Content + task + comment hashing
│   │   └── slug.fnl      # Title → filename slug
│   └── cache/
│       └── store.fnl     # In-memory cache
├── fnl/longway-spec/      # Test specifications (Fennel)
├── lua/longway/           # Compiled Lua (committed)
├── lua/longway-spec/      # Compiled tests (committed)
├── scripts/
│   ├── setup-test-deps   # Install test dependencies
│   ├── test              # Run test suite
│   └── compile           # Compile Fennel files
└── .test/                 # Test environment
```

## Running Tests

### Quick Start

```bash
# One-time setup (installs plenary.nvim and nfnl)
./scripts/setup-test-deps

# Run all tests
./scripts/test
```

### Running Specific Tests

```bash
# Run a single test file
nvim --headless -u .test/init.lua \
  -c "PlenaryBustedFile lua/longway-spec/config_spec.lua"

# Run tests matching a pattern (via grep on output)
./scripts/test 2>&1 | grep -A5 "slug"
```

### Using Make

```bash
make test-deps  # Install dependencies
make test       # Run tests
make compile    # Compile Fennel files
make clean      # Remove test artifacts
```

### Using mise (optional)

If you have [mise](https://mise.jdx.dev/) installed:

```bash
mise run test        # Run tests
mise run test-watch  # Run tests on file changes
mise run compile     # Compile all Fennel files
```

## Writing Tests

Tests are written in Fennel and located in `fnl/longway-spec/`. They use [Plenary.busted](https://github.com/nvim-lua/plenary.nvim) for the test framework.

### Test File Template

```fennel
;; fnl/longway-spec/module_name_spec.fnl

(local t (require :longway-spec.init))
(local module (require :longway.module_name))

(describe "longway.module_name"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "function-name"
      (fn []
        (it "does something expected"
          (fn []
            (assert.equals expected (module.function-name input))))

        (it "handles edge cases"
          (fn []
            (assert.is_nil (module.function-name nil))))))))
```

### Test Utilities

The `longway-spec.init` module provides helpers:

```fennel
(local t (require :longway-spec.init))

;; Setup test config with defaults
(t.setup-test-config {})

;; Setup with overrides
(t.setup-test-config {:debug true})

;; Create mock data
(t.make-story {:id 12345 :name "Test"})
(t.make-task {:description "Do something"})
(t.make-comment {:text "A comment"})
(t.make-parsed-comment {:author "John Doe" :text "A parsed comment"})
(t.make-api-comment {:text "Raw API comment" :author_id "uuid-1"})

;; Get sample markdown
(t.sample-markdown)
```

### Custom Assertions

Custom assertions are available in `longway-spec.assertions`:

```fennel
(require :longway-spec.assertions)

;; Check substring
(assert.has_substring "hello world" "world")

;; Validate slug format
(assert.is_valid_slug "my-story-title")

;; Validate hash format
(assert.is_valid_hash "abc12345")

;; Check frontmatter presence
(assert.has_frontmatter content)

;; Check sync section presence
(assert.has_sync_section content "description")
```

## Code Style

### Fennel

- Use 2-space indentation
- Prefer descriptive names over abbreviations
- Keep functions focused and small
- Add docstrings to public functions

### Commit Messages

- Use conventional commits format: `type: description`
- Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`
- Keep the first line under 72 characters
- Reference issues when applicable: `fix: handle nil config (#123)`

## Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes
4. Run tests: `./scripts/test`
5. Commit with a descriptive message
6. Push and open a pull request

### PR Checklist

- [ ] Tests pass locally
- [ ] New functionality has tests
- [ ] Fennel files compile without errors
- [ ] Commit messages follow conventions
- [ ] PR description explains the changes

## CI/CD

Tests run automatically on every pull request via GitHub Actions:

- **Platforms**: Ubuntu, macOS
- **Neovim versions**: v0.10.4, stable, nightly

All checks must pass before merging.

## Architecture Notes

### Module Patterns

- **Exports:** Each module defines `(local M {})` and returns `M` at the end
- **Error handling:** Functions return `{:ok bool :data value :error string}` tuples
- **Config access:** Use `(config.get)` for the current configuration table
- **Naming:** kebab-case for Fennel identifiers (e.g., `push-story`, `task-changed?`)

### Task Sync Flow

The task sync system works through several cooperating modules:

1. **Parsing:** `markdown/tasks.fnl` parses `- [x] ... <!-- task:ID -->` lines
2. **Diffing:** `sync/tasks.fnl` compares local vs remote to find created/updated/deleted
3. **Pushing:** `sync/push.fnl` orchestrates the push, including confirmation prompts
4. **Rendering:** `markdown/tasks.fnl` is the single source of truth for formatting API tasks
5. **Hashing:** `util/hash.fnl` computes `tasks_hash` for change detection

### Comment Sync Flow

The comment sync system follows the same pattern as tasks:

1. **Parsing:** `markdown/comments.fnl` parses `**Author** · timestamp <!-- comment:ID -->` blocks
2. **Diffing:** `sync/comments.fnl` compares local vs remote to find created, deleted, and edited
3. **Pushing:** `sync/push.fnl` orchestrates the push, including confirmation prompts and edit warnings
4. **Rendering:** `markdown/comments.fnl` is the single source of truth for formatting API comments
5. **Hashing:** `util/hash.fnl` computes `comments_hash` for change detection
6. **Author resolution:** `markdown/comments.fnl` resolves `author_id` UUIDs to display names via `api/members.fnl`

**Key difference from tasks:** There is no "update" path. Editing an existing comment's text locally triggers a warning notification, not an API call (Shortcut doesn't support comment editing).

### Single Source of Truth

- `markdown/tasks.fnl` owns all task parsing (`parse-line`, `parse-section`) and formatting (`format-api-tasks`, `render-task`)
- `markdown/comments.fnl` owns all comment parsing (`parse-block`, `parse-section`) and formatting (`format-api-comments`, `render-comment`)
- `markdown/parser.fnl` delegates to `tasks-md.parse-section` and `comments-md.parse-section` for extraction
- `markdown/renderer.fnl` delegates to `tasks-md` and `comments-md` for rendering
- `sync/tasks.fnl` delegates to `tasks-md.format-api-tasks` for pull formatting
- `sync/comments.fnl` delegates to `comments-md.format-api-comments` for pull formatting

## Documentation

- Update README.md for user-facing changes
- Update docs/PRD.md for roadmap changes
- Add inline documentation for complex logic
- Test specifications serve as executable documentation

## Getting Help

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Reference the [PRD](docs/PRD.md) for planned features

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
