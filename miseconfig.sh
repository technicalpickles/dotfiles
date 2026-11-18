#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DIR/functions.sh"

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

# Home-role-only tools live in config/mise/home/ and get linked into conf.d/
# (gitignored) so mise picks them up. Elsewhere, drop a stale link left over
# from a role change.
for tool_file in "$DIR"/config/mise/home/*.toml; do
  [ -f "$tool_file" ] || continue
  link_path="$DIR/config/mise/conf.d/$(basename "$tool_file")"
  if running_home_role; then
    echo "📦 linking home-role mise tools: $(basename "$tool_file")"
    ln -sfn "../home/$(basename "$tool_file")" "$link_path"
  elif [ -L "$link_path" ]; then
    echo "📦 removing home-only mise tools link: $(basename "$tool_file")"
    rm "$link_path"
  fi
done
