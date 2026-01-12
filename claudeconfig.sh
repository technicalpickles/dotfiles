#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/functions.sh"

# Prerequisite checks
if ! command_available claude; then
  echo "Error: claude command not found. Install Claude Code first."
  exit 1
fi

if ! command_available jq; then
  echo "Error: jq required for JSON merging. Install with: brew install jq"
  exit 1
fi

# Detect role (uses existing DOTPICKLES_ROLE from environment)
ROLE="${DOTPICKLES_ROLE:-personal}"
echo "Configuring Claude Code for role: $ROLE"

# Generate settings.json
generate_settings() {
  echo "Generating settings.json..."

  local settings_file="$HOME/.claude/settings.json"
  local temp_file="$(mktemp)"

  # Define local-only keys to preserve
  local local_keys=("awsAuthRefresh" "env")

  # Extract local-only settings from existing file
  local local_settings="{}"
  if [ -f "$settings_file" ]; then
    for key in "${local_keys[@]}"; do
      if jq -e ".$key" "$settings_file" > /dev/null 2>&1; then
        local_settings=$(echo "$local_settings" | jq --argjson val "$(jq ".$key" "$settings_file")" ". + {\"$key\": \$val}")
      fi
    done
  fi

  # Merge base + role-specific settings
  local base_settings="$DIR/claude/settings.base.json"
  local role_settings="$DIR/claude/settings.$ROLE.json"

  if [ ! -f "$base_settings" ]; then
    echo "Error: $base_settings not found"
    exit 1
  fi

  local merged_settings
  if [ -f "$role_settings" ]; then
    merged_settings=$(jq -s '.[0] * .[1]' "$base_settings" "$role_settings")
  else
    merged_settings=$(cat "$base_settings")
  fi

  # Merge permissions
  local base_permissions="$DIR/claude/permissions.json"
  local role_permissions="$DIR/claude/permissions.$ROLE.json"

  if [ ! -f "$base_permissions" ]; then
    echo "Error: $base_permissions not found"
    exit 1
  fi

  local merged_permissions
  if [ -f "$role_permissions" ]; then
    merged_permissions=$(jq -s '.[0] + .[1]' "$base_permissions" "$role_permissions")
  else
    merged_permissions=$(cat "$base_permissions")
  fi

  # Combine settings + permissions
  local final_settings=$(echo "$merged_settings" | jq --argjson perms "$merged_permissions" '. + {permissions: {allow: $perms}}')

  # Merge in local-only settings
  final_settings=$(echo "$final_settings" | jq --argjson local "$local_settings" '. * $local')

  # Write to temp file and validate
  echo "$final_settings" > "$temp_file"
  if ! jq empty "$temp_file" 2> /dev/null; then
    echo "Error: Generated invalid JSON"
    rm "$temp_file"
    exit 1
  fi

  # Backup existing settings (first time only)
  if [ -f "$settings_file" ] && [ ! -f "$settings_file.backup" ]; then
    cp "$settings_file" "$settings_file.backup"
    echo "  ℹ Backed up existing settings to $settings_file.backup"
  fi

  # Move temp file to final location
  mv "$temp_file" "$settings_file"
  echo "  ✓ Settings generated successfully"
}

generate_settings

# Install marketplaces (idempotent)
install_marketplaces() {
  echo "Installing marketplaces..."

  local marketplaces=(
    "superpowers-marketplace"
    "anthropic-agent-skills"
    "technicalpickles-marketplace"
    "claude-notifications-go"
  )

  for marketplace in "${marketplaces[@]}"; do
    if claude plugin marketplace list 2> /dev/null | grep -q "$marketplace"; then
      echo "  ✓ $marketplace (already added)"
    else
      echo "  + Adding $marketplace..."
      if claude marketplace add "$marketplace"; then
        echo "    ✓ Added successfully"
      else
        echo "    ✗ Failed to add (continuing anyway)"
      fi
    fi
  done
}

install_marketplaces

# Install plugins (idempotent)
install_plugins() {
  echo "Installing plugins..."

  local plugins=(
    "tool-routing@technicalpickles-marketplace"
    "claude-notifications-go@claude-notifications-go"
  )
  for plugin in "${plugins[@]}"; do
    if claude plugin list 2> /dev/null | grep -q "$plugin"; then
      echo "  ✓ $plugin (already installed)"
    else
      echo "  + Installing $plugin..."
      if claude plugin install "$plugin"; then
        echo "    ✓ Installed successfully"
      else
        echo "    ✗ Failed to install (continuing anyway)"
      fi
    fi
  done
}

install_plugins

echo ""
echo "✓ Claude Code configuration complete"
echo "  Settings: $HOME/.claude/settings.json"
echo "  Role: $ROLE"
echo ""
echo "Note: Skills are now installed per-project via craftdesk."
echo "  Run 'craftdesk-setup' in a project to configure skills."
