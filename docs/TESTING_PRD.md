# Testing PRD: Automated Testing for longway.nvim

## Overview

This document outlines the plan for implementing automated testing infrastructure for longway.nvim, a Fennel-based Neovim plugin. The approach is modeled after [Conjure](https://github.com/Olical/conjure), a mature Fennel Neovim plugin with comprehensive testing.

## Goals

1. **Ensure code quality** - Catch bugs before they reach users
2. **Enable confident refactoring** - Tests provide safety net for changes
3. **Document expected behavior** - Tests serve as executable documentation
4. **Support CI/CD** - Automated testing on every push/PR
5. **Multi-version Neovim support** - Verify compatibility across Neovim versions

## Non-Goals

- Performance/benchmark testing (can be added later)
- End-to-end integration tests with live Shortcut API (too slow/flaky)
- 100% code coverage (focus on critical paths)

---

## Testing Framework

### Primary Tools

| Tool | Purpose | Justification |
|------|---------|---------------|
| **Plenary.busted** | Test framework | Standard for Neovim plugins; BDD-style syntax |
| **luassert** | Assertions | Built into Plenary; rich assertion library |
| **nfnl** | Fennel compilation | Already used by project; compiles test specs |
| **Plenary.nvim** | Test utilities | Provides test harness, mocks, async helpers |

### Why Plenary.busted?

1. **Neovim-native** - Designed specifically for Neovim plugin testing
2. **Fennel-compatible** - Works with compiled Lua from Fennel sources
3. **Proven approach** - Used by Conjure and many other major plugins
4. **Built-in mocks** - Supports mocking Neovim APIs for isolation
5. **Async support** - Handles Neovim's async patterns

---

## Test File Structure

### Directory Layout

```
longway.nvim/
├── fnl/
│   ├── longway/              # Source files (existing)
│   └── longway-spec/         # Test specifications (NEW)
│       ├── init.fnl          # Test utilities and helpers
│       ├── assertions.fnl    # Custom assertions
│       ├── mocks/
│       │   ├── api.fnl       # Mock Shortcut API responses
│       │   ├── curl.fnl      # Mock plenary.curl
│       │   └── notify.fnl    # Mock notification system
│       ├── config_spec.fnl
│       ├── core_spec.fnl
│       ├── api/
│       │   ├── client_spec.fnl
│       │   └── stories_spec.fnl
│       ├── sync/
│       │   ├── pull_spec.fnl
│       │   └── push_spec.fnl
│       ├── markdown/
│       │   ├── parser_spec.fnl
│       │   ├── renderer_spec.fnl
│       │   └── frontmatter_spec.fnl
│       └── util/
│           ├── slug_spec.fnl
│           └── hash_spec.fnl
├── lua/
│   ├── longway/              # Compiled source (existing)
│   └── longway-spec/         # Compiled tests (NEW)
├── scripts/
│   ├── setup-test-deps       # Install test dependencies
│   └── test                  # Run test suite
├── .github/
│   └── workflows/
│       └── test.yaml         # CI workflow
└── mise.toml                 # Task runner configuration (optional)
```

### Naming Conventions

- **Test files**: `*_spec.fnl` suffix (e.g., `parser_spec.fnl`)
- **Test directories**: Mirror source structure under `fnl/longway-spec/`
- **Mock files**: Descriptive names in `mocks/` directory
- **Helper modules**: No `_spec` suffix (e.g., `assertions.fnl`)

---

## Configuration Files

### 1. Update `.nfnl.fnl`

```fennel
;; Compile both source and test files
{:source-file-patterns ["fnl/**/*.fnl"]
 :fennel-macro-path "./fnl/?.fnl;./fnl/?/init-macros.fnl;./fnl/?/init.fnl"}
```

No change needed - the existing pattern `fnl/**/*.fnl` already covers `fnl/longway-spec/`.

### 2. Create `scripts/setup-test-deps`

```bash
#!/usr/bin/env bash
set -euo pipefail

TEST_DIR=".test"
PACK_DIR="$TEST_DIR/nvim/pack/test/start"

mkdir -p "$PACK_DIR"

# Clone plenary.nvim (required for testing)
if [[ ! -d "$PACK_DIR/plenary.nvim" ]]; then
    echo "Cloning plenary.nvim..."
    git clone --depth 1 https://github.com/nvim-lua/plenary.nvim "$PACK_DIR/plenary.nvim"
fi

# Clone nfnl (required for Fennel compilation)
if [[ ! -d "$PACK_DIR/nfnl" ]]; then
    echo "Cloning nfnl..."
    git clone --depth 1 https://github.com/Olical/nfnl "$PACK_DIR/nfnl"
fi

# Symlink the plugin itself
if [[ ! -L "$PACK_DIR/longway.nvim" ]]; then
    echo "Symlinking longway.nvim..."
    ln -sf "$(pwd)" "$PACK_DIR/longway.nvim"
fi

echo "Test dependencies ready!"
```

### 3. Create `scripts/test`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Isolate test environment from user config
export XDG_CONFIG_HOME=".test"
export XDG_DATA_HOME=".test"
export XDG_STATE_HOME=".test"

# Run tests in headless Neovim
nvim --headless \
    --noplugin \
    -u .test/init.lua \
    -c "PlenaryBustedDirectory lua/longway-spec { minimal_init = '.test/init.lua' }"
```

### 4. Create `.test/init.lua`

```lua
-- Minimal init for testing
-- This file sets up the Neovim environment for running tests

-- Add plugin paths to runtimepath (prepend for higher priority)
vim.opt.runtimepath:prepend(".")
vim.opt.runtimepath:prepend(".test/nvim/pack/test/start/plenary.nvim")

-- Disable swap files for testing
vim.opt.swapfile = false

-- Set up a mock config for testing (no real API token needed)
vim.g.longway_test_mode = true

-- Load plenary
local ok, _ = pcall(require, "plenary")
if not ok then
    print("ERROR: Could not load plenary.nvim")
    print("Run ./scripts/setup-test-deps first")
    vim.cmd("cq 1")
end
```

### 5. Create `.github/workflows/test.yaml`

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
        neovim-version: ['v0.10.4', 'stable', 'nightly']

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Neovim
        uses: rhysd/action-setup-vim@v1
        with:
          neovim: true
          version: ${{ matrix.neovim-version }}

      - name: Cache test dependencies
        uses: actions/cache@v4
        with:
          path: .test/nvim/pack
          key: test-deps-${{ runner.os }}-${{ hashFiles('scripts/setup-test-deps') }}
          restore-keys: |
            test-deps-${{ runner.os }}-

      - name: Setup test dependencies
        run: bash scripts/setup-test-deps

      - name: Run tests
        run: bash scripts/test
```

### 6. Create `mise.toml` (Optional)

```toml
[tasks.test]
description = "Run the test suite"
run = ["bash ./scripts/setup-test-deps", "bash ./scripts/test"]

[tasks.test-watch]
description = "Run tests on file changes"
run = "find fnl lua -name '*.fnl' -o -name '*.lua' | entr -c mise run test"

[tasks.compile]
description = "Compile all Fennel files"
run = "nvim --headless -c 'NfnlCompileAllFiles' -c 'qa'"
```

### 7. Update `.gitignore`

```gitignore
# Existing entries...

# Test artifacts
.test/
```

---

## Test Patterns and Examples

### Basic Test Structure

```fennel
;; fnl/longway-spec/util/slug_spec.fnl
(local slug (require :longway.util.slug))

(describe "longway.util.slug"
  (fn []
    (describe "generate"
      (fn []
        (it "converts story title to lowercase slug"
          (fn []
            (assert.equals "my-story-title"
                           (slug.generate "My Story Title"))))

        (it "handles special characters"
          (fn []
            (assert.equals "fix-bug-123"
                           (slug.generate "Fix Bug #123!"))))

        (it "truncates long titles"
          (fn []
            (let [long-title (string.rep "word " 20)
                  result (slug.generate long-title)]
              (assert.is_true (<= (length result) 50)))))))))
```

### Testing with Mocks

```fennel
;; fnl/longway-spec/api/client_spec.fnl
(local client (require :longway.api.client))
(local mock-curl (require :longway-spec.mocks.curl))

(describe "longway.api.client"
  (fn []
    (before_each (fn [] (mock-curl.reset)))

    (describe "get"
      (fn []
        (it "sends GET request with auth header"
          (fn []
            (mock-curl.setup-response {:status 200 :body "{}"})
            (client.get "/stories/123")
            (let [call (mock-curl.last-call)]
              (assert.equals "GET" call.method)
              (assert.has-header call "Shortcut-Token"))))

        (it "handles API errors gracefully"
          (fn []
            (mock-curl.setup-response {:status 404 :body "{\"message\":\"Not found\"}"})
            (let [result (client.get "/stories/999")]
              (assert.is_nil result.data)
              (assert.equals 404 result.status))))))))
```

### Testing Markdown Parser

```fennel
;; fnl/longway-spec/markdown/parser_spec.fnl
(local parser (require :longway.markdown.parser))

(describe "longway.markdown.parser"
  (fn []
    (describe "parse-frontmatter"
      (fn []
        (it "extracts YAML frontmatter from markdown"
          (fn []
            (let [content "---
id: 12345
title: Test Story
---
# Content here"
                  result (parser.parse-frontmatter content)]
              (assert.equals 12345 result.id)
              (assert.equals "Test Story" result.title))))

        (it "returns nil for invalid frontmatter"
          (fn []
            (let [result (parser.parse-frontmatter "No frontmatter here")]
              (assert.is_nil result))))))

    (describe "extract-sync-section"
      (fn []
        (it "extracts content between sync markers"
          (fn []
            (let [content "<!-- longway:description:start -->
Updated description
<!-- longway:description:end -->"
                  result (parser.extract-sync-section content :description)]
              (assert.equals "Updated description" (vim.trim result)))))))))
```

### Testing Async Operations

```fennel
;; fnl/longway-spec/sync/pull_spec.fnl
(local pull (require :longway.sync.pull))
(local mock-api (require :longway-spec.mocks.api))
(local async (require :plenary.async))

(describe "longway.sync.pull"
  (fn []
    (describe "pull-story"
      (fn []
        (it "fetches story and creates markdown file"
          (async.tests.it
            (fn []
              (mock-api.setup-story {:id 12345 :name "Test Story"})
              (let [result (pull.pull-story 12345)]
                (assert.is_not_nil result.filepath)
                (assert.is_true (vim.fn.filereadable result.filepath))))))))))
```

### Custom Assertions

```fennel
;; fnl/longway-spec/assertions.fnl
(local say (require :say))
(local assert (require :luassert))

;; Custom assertion: has-substring
(fn has-substring [state args]
  (let [[haystack needle] args]
    (not= nil (string.find haystack needle 1 true))))

(say:set "assertion.has_substring.positive"
         "Expected %s\nto contain: %s")
(say:set "assertion.has_substring.negative"
         "Expected %s\nto NOT contain: %s")

(assert:register "assertion" "has_substring"
                 has-substring
                 "assertion.has_substring.positive"
                 "assertion.has_substring.negative")

;; Custom assertion: is-valid-slug
(fn is-valid-slug [state args]
  (let [[slug] args]
    (and (= (type slug) :string)
         (not (string.find slug "[^a-z0-9-]"))
         (> (length slug) 0))))

(say:set "assertion.is_valid_slug.positive"
         "Expected %s\nto be a valid slug (lowercase alphanumeric with hyphens)")
(say:set "assertion.is_valid_slug.negative"
         "Expected %s\nto NOT be a valid slug")

(assert:register "assertion" "is_valid_slug"
                 is-valid-slug
                 "assertion.is_valid_slug.positive"
                 "assertion.is_valid_slug.negative")

{:has-substring has-substring
 :is-valid-slug is-valid-slug}
```

---

## Mock Implementations

### API Mock

```fennel
;; fnl/longway-spec/mocks/api.fnl
(var stories {})
(var call-log [])

(fn reset []
  (set stories {})
  (set call-log []))

(fn setup-story [story]
  (tset stories story.id story))

(fn get-story [id]
  (table.insert call-log {:method :get-story :id id})
  (. stories id))

(fn last-call []
  (. call-log (length call-log)))

{: reset
 : setup-story
 : get-story
 : last-call
 :call-log call-log}
```

### Curl Mock

```fennel
;; fnl/longway-spec/mocks/curl.fnl
(var response nil)
(var calls [])

(fn reset []
  (set response nil)
  (set calls []))

(fn setup-response [resp]
  (set response resp))

(fn request [opts]
  (table.insert calls opts)
  response)

(fn last-call []
  (. calls (length calls)))

(fn has-header [call header-name]
  (when call.headers
    (each [_ h (ipairs call.headers)]
      (when (string.find h header-name)
        (lua "return true"))))
  false)

{: reset
 : setup-response
 : request
 : last-call
 : has-header}
```

---

## Test Coverage Priorities

### Phase 1: Critical Path (Must Have)

| Module | Priority | Rationale |
|--------|----------|-----------|
| `util/hash.fnl` | High | Data integrity depends on correct hashing |
| `util/slug.fnl` | High | Filename generation must be reliable |
| `markdown/parser.fnl` | High | Core sync functionality depends on parsing |
| `markdown/frontmatter.fnl` | High | Metadata extraction is critical |
| `markdown/renderer.fnl` | High | Correct markdown generation |
| `config.fnl` | Medium | Configuration validation |

### Phase 2: API Layer

| Module | Priority | Rationale |
|--------|----------|-----------|
| `api/client.fnl` | High | HTTP error handling, auth |
| `api/stories.fnl` | Medium | API response processing |

### Phase 3: Sync Operations

| Module | Priority | Rationale |
|--------|----------|-----------|
| `sync/pull.fnl` | High | Primary user workflow |
| `sync/push.fnl` | High | Data modification - must be correct |
| `core.fnl` | Medium | Command orchestration |

---

## Implementation Plan

### Phase 1: Foundation (Week 1)

1. **Setup infrastructure**
   - Create `scripts/setup-test-deps`
   - Create `scripts/test`
   - Create `.test/init.lua`
   - Update `.gitignore`

2. **Create test utilities**
   - `fnl/longway-spec/init.fnl` - Common test helpers
   - `fnl/longway-spec/assertions.fnl` - Custom assertions

3. **First tests**
   - `fnl/longway-spec/util/slug_spec.fnl`
   - `fnl/longway-spec/util/hash_spec.fnl`

### Phase 2: CI Setup (Week 1-2)

1. **GitHub Actions**
   - Create `.github/workflows/test.yaml`
   - Test across Neovim versions (0.10.x, stable, nightly)
   - Test on Ubuntu and macOS

2. **Verify CI works**
   - Push test branch
   - Confirm tests run in CI
   - Fix any environment issues

### Phase 3: Core Tests (Week 2)

1. **Markdown tests**
   - `fnl/longway-spec/markdown/parser_spec.fnl`
   - `fnl/longway-spec/markdown/frontmatter_spec.fnl`
   - `fnl/longway-spec/markdown/renderer_spec.fnl`

2. **Config tests**
   - `fnl/longway-spec/config_spec.fnl`

### Phase 4: API & Sync Tests (Week 3)

1. **Mock infrastructure**
   - `fnl/longway-spec/mocks/curl.fnl`
   - `fnl/longway-spec/mocks/api.fnl`

2. **API tests**
   - `fnl/longway-spec/api/client_spec.fnl`
   - `fnl/longway-spec/api/stories_spec.fnl`

3. **Sync tests**
   - `fnl/longway-spec/sync/pull_spec.fnl`
   - `fnl/longway-spec/sync/push_spec.fnl`

### Phase 5: Integration Tests (Week 4)

1. **Core workflow tests**
   - `fnl/longway-spec/core_spec.fnl`
   - End-to-end pull/push with mocks

2. **Documentation**
   - Update README with testing instructions
   - Add CONTRIBUTING.md with test guidelines

---

## Running Tests

### Local Development

```bash
# One-time setup
./scripts/setup-test-deps

# Run all tests
./scripts/test

# Run specific test file (after compiling)
nvim --headless -c "PlenaryBustedFile lua/longway-spec/util/slug_spec.lua"

# With mise (if installed)
mise run test
```

### Continuous Integration

Tests run automatically on:
- Every push to `main`
- Every pull request targeting `main`

Matrix testing covers:
- **Operating Systems**: Ubuntu, macOS
- **Neovim Versions**: v0.10.4, stable, nightly

---

## Success Metrics

1. **All Phase 1 tests pass locally and in CI**
2. **Test coverage of critical modules** (hash, slug, parser, renderer)
3. **CI runs on every PR** with pass/fail status checks
4. **Tests complete in under 60 seconds**
5. **Zero flaky tests** (tests that sometimes pass/fail randomly)

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Plenary.busted API changes | Tests break | Pin plenary version in setup script |
| Neovim version incompatibility | CI failures | Matrix testing catches issues early |
| Slow test execution | Developer friction | Focus on unit tests; mock I/O |
| Flaky async tests | False failures | Use plenary.async test utilities properly |
| Mock drift from real API | False confidence | Periodic validation against real API |

---

## Future Enhancements

1. **Code coverage reporting** - Add coverage metrics to CI
2. **Benchmark suite** - Performance regression testing
3. **Integration test mode** - Optional live API tests with test Shortcut workspace
4. **Property-based testing** - Fuzzing for parser edge cases
5. **Snapshot testing** - For markdown renderer output

---

## References

- [Conjure Testing Setup](https://github.com/Olical/conjure) - Reference implementation
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Test framework
- [nfnl](https://github.com/Olical/nfnl) - Fennel compiler
- [GitHub Actions for Neovim](https://github.com/rhysd/action-setup-vim) - CI setup

---

## Appendix: Test File Template

```fennel
;; fnl/longway-spec/module_name_spec.fnl
;;
;; Tests for longway.module_name
;;

(local module (require :longway.module_name))

(describe "longway.module_name"
  (fn []
    ;; Setup/teardown hooks (optional)
    (before_each (fn []
      ;; Reset state before each test
      ))

    (after_each (fn []
      ;; Cleanup after each test
      ))

    (describe "function-name"
      (fn []
        (it "does something expected"
          (fn []
            (assert.equals expected (module.function-name input))))

        (it "handles edge case"
          (fn []
            (assert.is_nil (module.function-name nil))))))))
```
