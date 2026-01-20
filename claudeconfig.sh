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

  # Merge permissions (allow and deny lists)
  local base_permissions="$DIR/claude/permissions.json"
  local role_permissions="$DIR/claude/permissions.$ROLE.json"

  if [ ! -f "$base_permissions" ]; then
    echo "Error: $base_permissions not found"
    exit 1
  fi

  # Merge allow lists: base.allow + role.allow
  local merged_allow
  if [ -f "$role_permissions" ]; then
    merged_allow=$(jq -s '.[0].allow + .[1].allow' "$base_permissions" "$role_permissions")
  else
    merged_allow=$(jq '.allow' "$base_permissions")
  fi

  # Merge deny lists: base.deny + role.deny
  local merged_deny
  if [ -f "$role_permissions" ]; then
    merged_deny=$(jq -s '.[0].deny + .[1].deny' "$base_permissions" "$role_permissions")
  else
    merged_deny=$(jq '.deny' "$base_permissions")
  fi

  # Combine settings + permissions (with both allow and deny)
  local final_settings=$(echo "$merged_settings" | jq \
    --argjson allow "$merged_allow" \
    --argjson deny "$merged_deny" \
    '. + {permissions: {allow: $allow, deny: $deny}}')

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

# Configure marketplaces (non-interactive)
configure_marketplaces() {
  echo "Configuring marketplaces..."

  local known_marketplaces_file="$HOME/.claude/plugins/known_marketplaces.json"
  local marketplaces_dir="$HOME/.claude/plugins/marketplaces"

  # Ensure directories exist
  mkdir -p "$marketplaces_dir"

  # Define marketplaces with their GitHub repos
  # Format: "marketplace-id:github-repo"
  local marketplaces=(
    "pickled-claude-plugins:technicalpickles/pickled-claude-plugins"
    "superpowers-marketplace:obra/superpowers"
    "claude-notifications-go:777genius/claude-notifications-go"
  )

  # Read existing marketplaces or start with empty object
  local current_marketplaces="{}"
  if [ -f "$known_marketplaces_file" ]; then
    current_marketplaces=$(cat "$known_marketplaces_file")
  fi

  local updated=false

  for entry in "${marketplaces[@]}"; do
    IFS=':' read -r marketplace_id github_repo <<< "$entry"
    local install_location="$marketplaces_dir/$marketplace_id"

    # Check if marketplace already exists in JSON
    if echo "$current_marketplaces" | jq -e ".[\"$marketplace_id\"]" > /dev/null 2>&1; then
      echo "  ✓ $marketplace_id (already configured)"
    else
      echo "  + Adding $marketplace_id..."

      # Add marketplace entry to JSON
      current_marketplaces=$(echo "$current_marketplaces" | jq \
        --arg id "$marketplace_id" \
        --arg repo "$github_repo" \
        --arg location "$install_location" \
        --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")" \
        '. + {($id): {source: {source: "github", repo: $repo}, installLocation: $location, lastUpdated: $timestamp}}')

      updated=true
      echo "    ✓ Added to known_marketplaces.json"
    fi

    # Clone marketplace repo if not present
    if [ ! -d "$install_location" ]; then
      echo "  + Cloning $marketplace_id from $github_repo..."
      if git clone "https://github.com/$github_repo.git" "$install_location" 2> /dev/null; then
        echo "    ✓ Cloned successfully"
      else
        echo "    ✗ Failed to clone (continuing anyway)"
      fi
    else
      echo "  ✓ $marketplace_id repository exists"
    fi
  done

  # Write updated marketplaces JSON if changes were made
  if [ "$updated" = true ]; then
    echo "$current_marketplaces" | jq '.' > "$known_marketplaces_file"
    echo "  ✓ Updated known_marketplaces.json"
  fi
}

configure_marketplaces

echo ""
echo "✓ Claude Code configuration complete"
echo "  Settings: $HOME/.claude/settings.json"
echo "  Role: $ROLE"
echo ""
echo "Note: Skills are now installed per-project via craftdesk."
echo "  Run 'craftdesk-setup' in a project to configure skills."
