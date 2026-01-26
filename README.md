# longway.nvim

Bidirectional synchronization between [Shortcut](https://shortcut.com) and local markdown files for Neovim.

Pull stories and epics from Shortcut, edit them as markdown in your favorite editor, and push changes back.

## Current Status: v0.3.0

- **Pull** stories and epics from Shortcut as markdown files
- **Edit** descriptions, tasks, and comments in your editor
- **Push** changes back to Shortcut with automatic sync
- **Task synchronization** -- checkboxes map to Shortcut tasks bidirectionally
- **Owner resolution** -- `@mentions` resolve to Shortcut member UUIDs
- **Change detection** -- hash-based tracking to know what changed
- **Confirmation prompts** -- destructive operations (task deletion) require confirmation
- **Preset-based sync** -- configure named filters to pull stories in bulk

See [docs/PRD.md](docs/PRD.md) for the full roadmap.

## Requirements

- Neovim >= 0.9.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (required for HTTP client)
- Shortcut API token

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "em-schmidt/longway.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("longway").setup({
      -- API token (or set SHORTCUT_API_TOKEN env var)
      -- token = "your-api-token",

      -- Workspace directory for synced files
      workspace_dir = vim.fn.expand("~/shortcut"),

      -- Enable debug logging
      debug = false,
    })
  end,
}
```

## Configuration

### API Token

Set your Shortcut API token using one of these methods (in priority order):

1. Pass directly in config: `token = "your-token"`
2. Use a token file: `token_file = "~/.config/longway/token"`
3. Set environment variable: `SHORTCUT_API_TOKEN`
4. Create default token file at `~/.config/longway/token`

### Full Configuration

```lua
require("longway").setup({
  -- Authentication
  token = nil,  -- API token (or use env var)
  token_file = nil,  -- Path to file containing token

  -- Workspace
  workspace_dir = vim.fn.expand("~/shortcut"),
  stories_subdir = "stories",
  epics_subdir = "epics",

  -- File format
  filename_template = "{id}-{slug}",
  slug_max_length = 50,

  -- Sync markers (for identifying synced sections)
  sync_start_marker = "<!-- BEGIN SHORTCUT SYNC:{section} -->",
  sync_end_marker = "<!-- END SHORTCUT SYNC:{section} -->",

  -- Section sync toggles
  sync_sections = {
    description = true,
    tasks = true,
    comments = true,
  },

  -- Task sync options
  tasks = {
    show_owners = true,             -- Display @mentions in task lines
    confirm_delete = true,          -- Prompt before deleting tasks from Shortcut
    auto_assign_on_complete = false, -- Auto-assign current user when completing
  },

  -- Sync behavior
  auto_push_on_save = false,  -- Push changes when saving buffer
  pull_on_open = false,       -- Pull latest when opening a managed file
  conflict_strategy = "prompt", -- How to handle conflicts: "prompt", "local", "remote"

  -- Filter presets for bulk sync
  presets = {
    my_work = {
      query = "owner:me state:started",
      description = "My in-progress stories",
    },
  },
  default_preset = nil,  -- Name of preset to use with :LongwaySync (no args)

  -- UI
  notify = true,  -- Show notifications
  notify_level = vim.log.levels.INFO,

  -- Debug
  debug = false,
})
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:LongwayPull {id}` | Pull a story by ID and open in buffer |
| `:LongwayPullEpic {id}` | Pull an epic and its stories |
| `:LongwayPush` | Push description and tasks to Shortcut |
| `:LongwayRefresh` | Refresh current buffer from Shortcut |
| `:LongwaySync [query]` | Sync stories matching a query or preset |
| `:LongwaySyncAll` | Sync all configured presets |
| `:LongwayOpen` | Open current story in browser |
| `:LongwayStatus` | Show sync status (description, tasks, hashes) |
| `:LongwayInfo` | Show plugin configuration info |
| `:LongwayCacheRefresh` | Refresh cached member/workflow data |
| `:LongwayCacheStatus` | Show cache status |

### Example Workflow

```vim
" Pull story #12345 from Shortcut
:LongwayPull 12345

" Edit the description between sync markers...
" Toggle task checkboxes, add new tasks, remove tasks...
" (see Markdown Format below for details)

" Push description and task changes back to Shortcut
:LongwayPush

" Refresh to get latest from Shortcut
:LongwayRefresh

" Check sync status (shows task counts and hash state)
:LongwayStatus
```

### Lua API

```lua
local longway = require("longway")

-- Pull a story
longway.pull(12345)

-- Pull an epic
longway.pull_epic(100)

-- Push current buffer (description + tasks)
longway.push()

-- Refresh current buffer
longway.refresh()

-- Sync stories by query or preset
longway.sync("owner:me state:started")
longway.sync("my_preset_name")

-- Open in browser
longway.open()

-- Check configuration
local info = longway.get_info()
print(info.version)     -- "0.3.0"
print(info.configured)  -- true if token is set
```

## Markdown Format

Stories are saved as markdown files with YAML frontmatter:

```markdown
---
shortcut_id: 12345
shortcut_type: story
shortcut_url: https://app.shortcut.com/workspace/story/12345
story_type: feature
state: In Progress
sync_hash: "a1b2c3d4"
tasks_hash: "e5f6g7h8"
---

# Story Title

## Description

<!-- BEGIN SHORTCUT SYNC:description -->
This content syncs with Shortcut.

Edit here and use :LongwayPush to update Shortcut.
<!-- END SHORTCUT SYNC:description -->

## Tasks

<!-- BEGIN SHORTCUT SYNC:tasks -->
- [x] Design authentication flow <!-- task:101 @eric complete:true -->
- [x] Set up database schema <!-- task:102 @eric complete:true -->
- [ ] Implement password hashing <!-- task:103 complete:false -->
- [ ] New task I added locally <!-- task:new -->
<!-- END SHORTCUT SYNC:tasks -->

## Comments

<!-- BEGIN SHORTCUT SYNC:comments -->
---
**John Doe** · 2026-01-18 10:30 <!-- comment:456 -->

This is a synced comment from Shortcut.
<!-- END SHORTCUT SYNC:comments -->

## Local Notes

<!-- This section is NOT synced to Shortcut -->
Your personal notes go here.
```

### Task Format

Each task line follows this format:

```
- [x] Task description <!-- task:{id} @{owner} complete:true -->
```

| Component | Required | Description |
|-----------|----------|-------------|
| `- [x]` / `- [ ]` | Yes | Checkbox state |
| Task description | Yes | The task text |
| `task:{id}` | Yes | Shortcut task ID or `new` for new tasks |
| `@{owner}` | No | Owner mention (resolved to Shortcut member) |
| `complete:{bool}` | Yes | Explicit completion state |

**Adding tasks:** Write a new checkbox line with `<!-- task:new -->` and `:LongwayPush` will create it in Shortcut.

**Completing tasks:** Toggle the checkbox from `[ ]` to `[x]` and push.

**Deleting tasks:** Remove the line and push. If `confirm_delete` is enabled, you'll be prompted before the API call.

## Development

This plugin is written in Fennel and compiled to Lua.

### Project Structure

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
├── lua/longway/           # Compiled Lua (committed for distribution)
├── lua/longway-spec/      # Compiled tests
├── scripts/               # Development scripts
├── plugin/longway.lua     # Plugin entry point
└── docs/
    ├── PRD.md            # Product requirements
    ├── IMPLEMENTATION_PLAN.md
    ├── TESTING_PRD.md    # Testing infrastructure
    └── PHASE3_PLAN.md    # Task sync design
```

### Building

If you have [nfnl](https://github.com/Olical/nfnl) installed, Fennel files compile automatically on save.

### Testing

```bash
# Install test dependencies (one-time)
./scripts/setup-test-deps

# Run all tests
./scripts/test

# Or use make
make test
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed testing instructions.

## License

MIT

## Contributing

Contributions are welcome! Please see:
- [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and testing
- [PRD](docs/PRD.md) for the product roadmap
- [Implementation Plan](docs/IMPLEMENTATION_PLAN.md) for planned features
