#!/usr/bin/env bash
# Registers and clones the marketplaces in claude/marketplaces.jsonc for
# $DOTPICKLES_ROLE (default: home), and applies any "pin". Called by
# claudeconfig.sh; also runnable on its own (e.g. from pickleton's
# scripts/coder-setup.sh on a workspace that has no dotfiles applied).
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/functions.sh"

if ! command_available jq; then
  echo "Error: jq required for JSON merging." >&2
  exit 1
fi

ROLE="${DOTPICKLES_ROLE:-home}"

configure_marketplaces() {
  echo "Configuring marketplaces..."

  local known_marketplaces_file="$HOME/.claude/plugins/known_marketplaces.json"
  local marketplaces_dir="$HOME/.claude/plugins/marketplaces"

  # Ensure directories exist
  mkdir -p "$marketplaces_dir"

  # Marketplaces come from the shared manifest (single source of truth, also
  # read by cloud-project-setup.sh). Format per line: "marketplace-id:owner/repo:autoUpdate".
  local manifest="$DIR/claude/marketplaces.jsonc"
  if [ ! -f "$manifest" ]; then
    echo "Error: $manifest not found"
    exit 1
  fi
  local manifest_json
  manifest_json=$(read_json "$manifest")
  local marketplaces=()
  while IFS= read -r entry; do
    marketplaces+=("$entry")
  done < <(echo "$manifest_json" | jq -r --arg role "$ROLE" '.marketplaces | to_entries[] | select((.value.excludeRoles // []) | index($role) | not) | "\(.key):\(.value.repo):\(.value.autoUpdate // false)"')

  # Read existing marketplaces or start with empty object
  local current_marketplaces="{}"
  if [ -f "$known_marketplaces_file" ]; then
    current_marketplaces=$(cat "$known_marketplaces_file")
  fi

  local updated=false

  for entry in "${marketplaces[@]}"; do
    IFS=':' read -r marketplace_id github_repo auto_update <<< "$entry"
    local install_location="$marketplaces_dir/$marketplace_id"

    # Check if marketplace already exists in JSON
    if echo "$current_marketplaces" | jq -e ".[\"$marketplace_id\"]" > /dev/null 2>&1; then
      echo "  ✓ $marketplace_id (already configured)"
      # Opt in to autoUpdate only when the key is absent, so a value set in
      # /plugin (including an explicit false) is never overwritten.
      if [ "$auto_update" = true ] && echo "$current_marketplaces" | jq -e --arg id "$marketplace_id" '.[$id] | has("autoUpdate") | not' > /dev/null; then
        current_marketplaces=$(echo "$current_marketplaces" | jq --arg id "$marketplace_id" '.[$id].autoUpdate = true')
        updated=true
        echo "    ✓ Enabled autoUpdate"
      fi
    else
      echo "  + Adding $marketplace_id..."

      # Add marketplace entry to JSON
      current_marketplaces=$(echo "$current_marketplaces" | jq \
        --arg id "$marketplace_id" \
        --arg repo "$github_repo" \
        --arg location "$install_location" \
        --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")" \
        --argjson auto "$auto_update" \
        '. + {($id): ({source: {source: "github", repo: $repo}, installLocation: $location, lastUpdated: $timestamp} + (if $auto then {autoUpdate: true} else {} end))}')

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

    # Pin a plugin to a commit by writing "sha" into its source in the clone's
    # marketplace.json (see "pin" in marketplaces.jsonc). Idempotent; only
    # touches the file when the sha differs.
    local pin_plugin pin_sha
    pin_plugin=$(echo "$manifest_json" | jq -r --arg id "$marketplace_id" '.marketplaces[$id].pin.plugin // empty')
    pin_sha=$(echo "$manifest_json" | jq -r --arg id "$marketplace_id" '.marketplaces[$id].pin.sha // empty')
    local clone_manifest="$install_location/.claude-plugin/marketplace.json"
    if [ -n "$pin_plugin" ] && [ -n "$pin_sha" ] && [ -f "$clone_manifest" ]; then
      if jq -e --arg p "$pin_plugin" --arg sha "$pin_sha" '.plugins[] | select(.name == $p) | .source.sha == $sha' "$clone_manifest" > /dev/null; then
        echo "  ✓ $pin_plugin already pinned to ${pin_sha:0:8}"
      else
        jq --arg p "$pin_plugin" --arg sha "$pin_sha" '(.plugins[] | select(.name == $p) | .source.sha) = $sha' "$clone_manifest" > "$clone_manifest.tmp" \
          && mv "$clone_manifest.tmp" "$clone_manifest"
        echo "  ✓ Pinned $pin_plugin to ${pin_sha:0:8}"
        # Already-installed copies only move on update; harmless if not installed.
        if command_available claude; then
          claude plugin update "$pin_plugin@$marketplace_id" > /dev/null 2>&1 || true
        fi
      fi
    fi
  done

  # Write updated marketplaces JSON if changes were made
  if [ "$updated" = true ]; then
    echo "$current_marketplaces" | jq '.' > "$known_marketplaces_file"
    echo "  ✓ Updated known_marketplaces.json"
  fi
}

# Disables plugins listed in "disabledPlugins" (marketplaces.jsonc) for this
# role. enabledPlugins is local-only state that claudeconfig.sh preserves, so
# this goes through the CLI rather than settings.json. Idempotent; a plugin
# that isn't installed is skipped with a note.
disable_plugins() {
  command_available claude || return 0

  local manifest_json plugin
  manifest_json=$(read_json "$DIR/claude/marketplaces.jsonc")
  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    local out
    if out=$(claude plugin disable "$plugin" --scope user 2>&1); then
      echo "  ✓ Disabled $plugin for role '$ROLE'"
    elif [[ "$out" == *"already disabled"* ]]; then
      echo "  ✓ $plugin already disabled"
    else
      echo "  - $plugin not disabled: ${out##*: }"
    fi
  done < <(echo "$manifest_json" | jq -r --arg role "$ROLE" '(.disabledPlugins // {}) | to_entries[] | select(.value | index($role)) | .key')
}

configure_marketplaces
disable_plugins
