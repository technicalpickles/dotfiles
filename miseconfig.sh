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
# Versioned configuration lives in conf.d/ and installs everywhere:
#   - path.toml:     PATH additions (~/.cargo/bin, etc.)
#   - dotfiles.toml: shared tools (fnox, go, hk, pkl, node, python, uv, etc.)
#
# Add machine-specific overrides or extras below. Example:
#
#   [tools]
#   ruby = "3.4"
#   bun = "latest"

[tools]

[settings]
EOF
  echo "✅ Created $CONFIG_FILE"
  echo "   Edit it to add your language runtimes."
else
  echo "📦 mise config.toml already exists"
fi
