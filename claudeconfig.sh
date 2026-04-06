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

# Read a JSON or JSONC file, stripping comments and trailing commas
# Uses node if available for robust JSONC parsing, falls back to sed
read_json() {
  local file="$1"
  if command -v node > /dev/null 2>&1; then
    # Node handles JSONC natively with JSON5-like parsing
    node -e "
      const fs = require('fs');
      const content = fs.readFileSync('$file', 'utf8');
      // Strip comments and trailing commas
      const stripped = content
        .replace(/\/\/.*$/gm, '')           // Remove // comments
        .replace(/\/\*[\s\S]*?\*\//g, '')   // Remove /* */ comments
        .replace(/,(\s*[}\]])/g, '\$1');    // Remove trailing commas
      console.log(JSON.stringify(JSON.parse(stripped)));
    "
  else
    # Fallback: simple sed-based stripping (less robust)
    sed -E 's|//[^"]*$||g' < "$file" \
      | tr '\n' '\f' \
      | sed -E 's|,([[:space:]\f]*[}\]])|\1|g' \
      | tr '\f' '\n' \
      | jq '.'
  fi
}

# Detect role (uses existing DOTPICKLES_ROLE from environment)
ROLE="${DOTPICKLES_ROLE:-personal}"
echo "Configuring Claude Code for role: $ROLE"

# Ensure ~/.claude exists and symlink managed files
setup_claude_directory() {
  echo "Setting up ~/.claude directory..."

  mkdir -p "$HOME/.claude"
  mkdir -p "$HOME/.claude/skills"

  # Symlink CLAUDE.md (user's global instructions)
  local claude_md="$DIR/claude/CLAUDE.md"
  local claude_md_target="$HOME/.claude/CLAUDE.md"
  if [ -L "$claude_md_target" ]; then
    echo "  ✓ CLAUDE.md already symlinked"
  elif [ -f "$claude_md_target" ]; then
    echo "  ⚠ CLAUDE.md exists as regular file, skipping (remove manually to symlink)"
  else
    ln -s "$claude_md" "$claude_md_target"
    echo "  ✓ CLAUDE.md symlinked"
  fi
}

setup_claude_directory

# Generate settings.json from roles/ + stacks/
generate_settings() {
  echo "Generating settings.json..."

  local settings_file="$HOME/.claude/settings.json"
  local temp_file="$(mktemp)"

  # Local-only keys preserved from existing settings across regenerations
  local local_keys=("model" "enabledPlugins" "extraKnownMarketplaces")

  # Extract local-only settings from existing file
  local local_settings="{}"
  if [ -f "$settings_file" ]; then
    for key in "${local_keys[@]}"; do
      if jq -e ".$key" "$settings_file" > /dev/null 2>&1; then
        local_settings=$(echo "$local_settings" | jq --argjson val "$(jq ".$key" "$settings_file")" ". + {\"$key\": \$val}")
      fi
    done
  fi

  # --- Load base role ---
  local base_role="$DIR/claude/roles/base.jsonc"
  if [ ! -f "$base_role" ]; then
    echo "Error: $base_role not found"
    exit 1
  fi

  local base_json
  base_json=$(read_json "$base_role")

  # Extract settings (everything except permissions and sandbox)
  local merged_settings
  merged_settings=$(echo "$base_json" | jq 'del(.permissions, .sandbox)')

  # Extract permissions arrays from base
  local merged_allow merged_ask merged_deny
  merged_allow=$(echo "$base_json" | jq '.permissions.allow // []')
  merged_ask=$(echo "$base_json" | jq '.permissions.ask // []')
  merged_deny=$(echo "$base_json" | jq '.permissions.deny // []')

  # Extract sandbox from base (scalars + arrays)
  local sandbox_scalars sandbox_hosts sandbox_write_paths
  sandbox_scalars=$(echo "$base_json" | jq '.sandbox // {} | del(.network.allowedHosts, .filesystem.allowWrite, .filesystem, .network) + (if .network then {network: (.network | del(.allowedHosts))} else {} end) | del(.network | nulls) | del(.filesystem | nulls)')
  sandbox_hosts=$(echo "$base_json" | jq '.sandbox.network.allowedHosts // []')
  sandbox_write_paths=$(echo "$base_json" | jq '.sandbox.filesystem.allowWrite // []')

  echo "  + Loaded base role"

  # --- Load active role (if not base) ---
  local role_file="$DIR/claude/roles/$ROLE.jsonc"
  if [ -f "$role_file" ] && [ "$ROLE" != "base" ]; then
    local role_json
    role_json=$(read_json "$role_file")

    # Deep merge settings keys (role overrides base)
    local role_settings
    role_settings=$(echo "$role_json" | jq 'del(.permissions, .sandbox)')
    merged_settings=$(echo "$merged_settings" | jq --argjson role "$role_settings" '. * $role')

    # Concat permissions arrays (not deep merge, which would replace)
    merged_allow=$(echo "$merged_allow" | jq --argjson r "$(echo "$role_json" | jq '.permissions.allow // []')" '. + $r')
    merged_ask=$(echo "$merged_ask" | jq --argjson r "$(echo "$role_json" | jq '.permissions.ask // []')" '. + $r')
    merged_deny=$(echo "$merged_deny" | jq --argjson r "$(echo "$role_json" | jq '.permissions.deny // []')" '. + $r')

    # Merge sandbox scalars from role (role overrides base)
    local role_sandbox_scalars
    role_sandbox_scalars=$(echo "$role_json" | jq '.sandbox // {} | del(.network.allowedHosts, .filesystem.allowWrite, .filesystem, .network) + (if .network then {network: (.network | del(.allowedHosts))} else {} end) | del(.network | nulls) | del(.filesystem | nulls)')
    sandbox_scalars=$(echo "$sandbox_scalars" | jq --argjson r "$role_sandbox_scalars" '. * $r')

    # Concat sandbox arrays
    sandbox_hosts=$(echo "$sandbox_hosts" | jq --argjson r "$(echo "$role_json" | jq '.sandbox.network.allowedHosts // []')" '. + $r')
    sandbox_write_paths=$(echo "$sandbox_write_paths" | jq --argjson r "$(echo "$role_json" | jq '.sandbox.filesystem.allowWrite // []')" '. + $r')

    echo "  + Loaded $ROLE role"
  fi

  # --- Load stacks (sorted for determinism) ---
  for stack_file in "$DIR"/claude/stacks/*.jsonc; do
    [ -f "$stack_file" ] || continue
    local stack_name
    stack_name=$(basename "$stack_file" .jsonc)
    local stack_json
    stack_json=$(read_json "$stack_file")

    # Concat permissions
    merged_allow=$(echo "$merged_allow" | jq --argjson s "$(echo "$stack_json" | jq '.permissions.allow // []')" '. + $s')
    merged_ask=$(echo "$merged_ask" | jq --argjson s "$(echo "$stack_json" | jq '.permissions.ask // []')" '. + $s')
    merged_deny=$(echo "$merged_deny" | jq --argjson s "$(echo "$stack_json" | jq '.permissions.deny // []')" '. + $s')

    # Concat sandbox arrays
    sandbox_hosts=$(echo "$sandbox_hosts" | jq --argjson s "$(echo "$stack_json" | jq '.sandbox.network.allowedHosts // []')" '. + $s')
    sandbox_write_paths=$(echo "$sandbox_write_paths" | jq --argjson s "$(echo "$stack_json" | jq '.sandbox.filesystem.allowWrite // []')" '. + $s')

    echo "  + Merged $stack_name stack"
  done

  # Deduplicate and sort all arrays
  merged_allow=$(echo "$merged_allow" | jq 'unique | sort')
  merged_ask=$(echo "$merged_ask" | jq 'unique | sort')
  merged_deny=$(echo "$merged_deny" | jq 'unique | sort')
  sandbox_hosts=$(echo "$sandbox_hosts" | jq 'unique | sort')
  sandbox_write_paths=$(echo "$sandbox_write_paths" | jq 'unique | sort')

  # Assemble final JSON: settings + permissions + sandbox
  local final_settings
  final_settings=$(echo "$merged_settings" | jq \
    --argjson allow "$merged_allow" \
    --argjson ask "$merged_ask" \
    --argjson deny "$merged_deny" \
    --argjson sandbox_scalars "$sandbox_scalars" \
    --argjson hosts "$sandbox_hosts" \
    --argjson write_paths "$sandbox_write_paths" \
    '. + {
      permissions: {allow: $allow, ask: $ask, deny: $deny},
      sandbox: ($sandbox_scalars + {
        network: ($sandbox_scalars.network // {} | . + {allowedHosts: $hosts}),
        filesystem: {allowWrite: $write_paths}
      })
    }')

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
echo "Note: Global skills are restored from ~/.agents/.skill-lock.json via skills.sh"
