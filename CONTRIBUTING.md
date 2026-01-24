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
│   ├── api/              # Shortcut API modules
│   ├── sync/             # Sync operations
│   ├── markdown/         # Markdown parsing/rendering
│   ├── ui/               # UI helpers
│   └── util/             # Utilities
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
