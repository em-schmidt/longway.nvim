# longway.nvim

Bidirectional synchronization between [Shortcut](https://shortcut.com) and local markdown files for Neovim.

Pull stories and epics from Shortcut, edit them as markdown in your favorite editor, and push changes back.

## Current Status: Phase 1 (v0.1.0)

Phase 1 provides core functionality:
- Pull stories by ID from Shortcut
- Edit story descriptions as markdown
- Push description changes back to Shortcut
- Basic frontmatter with story metadata

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
| `:LongwayPush` | Push current buffer's description to Shortcut |
| `:LongwayRefresh` | Refresh current buffer from Shortcut |
| `:LongwayOpen` | Open current story in browser |
| `:LongwayStatus` | Show sync status of current file |
| `:LongwayInfo` | Show plugin configuration info |

### Example Workflow

```vim
" Pull story #12345 from Shortcut
:LongwayPull 12345

" Edit the description in the markdown file...
" The description is between sync markers

" Push your changes back to Shortcut
:LongwayPush

" Or refresh to get latest from Shortcut
:LongwayRefresh
```

### Lua API

```lua
local longway = require("longway")

-- Pull a story
longway.pull(12345)

-- Push current buffer
longway.push()

-- Refresh current buffer
longway.refresh()

-- Open in browser
longway.open()

-- Check configuration
local info = longway.get_info()
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
---

# Story Title

## Description

<!-- BEGIN SHORTCUT SYNC:description -->
This content syncs with Shortcut.

Edit here and use :LongwayPush to update Shortcut.
<!-- END SHORTCUT SYNC:description -->

## Local Notes

<!-- This section is NOT synced to Shortcut -->
Your personal notes go here.
```

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
├── lua/longway/           # Compiled Lua (committed for distribution)
├── plugin/longway.lua     # Plugin entry point
└── docs/
    ├── PRD.md            # Product requirements
    └── IMPLEMENTATION_PLAN.md
```

### Building

If you have [nfnl](https://github.com/Olical/nfnl) installed, Fennel files compile automatically on save.

## License

MIT

## Contributing

Contributions are welcome! Please see the [PRD](docs/PRD.md) and [Implementation Plan](docs/IMPLEMENTATION_PLAN.md) for planned features.
