#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="$DIR/config/mise/config.toml"

# Create config.toml if it doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "📦 Creating mise config.toml..."
  cat > "$CONFIG_FILE" << 'EOF'
# This file is gitignored - it contains machine-specific tool versions.
#
# Versioned configuration lives in conf.d/:
#   - path.toml:     PATH additions (~/.bun/bin, ~/.cargo/bin, etc.)
#   - dotfiles.toml: Tools managed by dotfiles (fnox, goss, hk, pkl)
#
# Add your language runtimes below. Example:
#
#   [tools]
#   node = "lts"
#   ruby = "3.4"
#   python = "3.12"
#   go = "latest"

[tools]

[settings]
EOF
  echo "✅ Created $CONFIG_FILE"
  echo "   Edit it to add your language runtimes."
else
  echo "📦 mise config.toml already exists"
fi
