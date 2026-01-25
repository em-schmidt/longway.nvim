#!/bin/bash
# .claude/hooks/setup-env.sh
# SessionStart hook for longway.nvim development environment
# Runs in both local and cloud environments, but only installs tools in cloud

set -e

# Only run setup in cloud/remote environments
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

echo "=== Setting up longway.nvim development environment ==="

# Install mise if not present
if ! command -v mise &> /dev/null; then
  curl https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

# Install tools defined in .mise.toml
cd "$CLAUDE_PROJECT_DIR"
mise trust .mise.toml
mise install

# Activate mise environment
eval "$(mise activate bash)"

# Install fennel via luarocks (now available via mise)
luarocks install fennel --local

# Clone nfnl for development
NFNL_DIR="$HOME/.local/share/nvim/site/pack/nfnl/start/nfnl"
if [ ! -d "$NFNL_DIR" ]; then
  mkdir -p "$(dirname "$NFNL_DIR")"
  git clone --depth 1 https://github.com/Olical/nfnl.git "$NFNL_DIR"
  echo "nfnl installed to $NFNL_DIR"
fi

# Persist environment for subsequent bash commands
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
  echo 'eval "$(mise activate bash)"' >> "$CLAUDE_ENV_FILE"
  echo 'export PATH="$HOME/.luarocks/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
fi

echo "=== Environment ready ==="
echo "  - neovim: $(nvim --version | head -1)"
echo "  - lua: $(lua -v)"
echo "  - fennel: $(fennel --version 2>/dev/null || echo 'installed via luarocks')"
echo "  - nfnl: $NFNL_DIR"
