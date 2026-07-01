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

# Args. SKIP_SSH_CHECK (flag or env) skips only the final agent SSH key
# validation, leaving config apply intact -- for offline runs and fresh setup,
# where the key isn't registered/SSO-authorized on GitHub yet.
SKIP_SSH_CHECK="${SKIP_SSH_CHECK:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-ssh-check)
      SKIP_SSH_CHECK=1
      shift
      ;;
    -h | --help)
      echo "Usage: claudeconfig.sh [--skip-ssh-check]"
      echo
      echo "Applies Claude config for \$DOTPICKLES_ROLE (settings.json, marketplaces,"
      echo "symlinks), then validates the active role's agent SSH key (fail-loud)."
      echo
      echo "  --skip-ssh-check  apply config but skip agent SSH key validation"
      echo "                    (also: SKIP_SSH_CHECK=1). Use offline or mid-setup."
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      echo "Run 'claudeconfig.sh --help' for usage." >&2
      exit 2
      ;;
  esac
done

# read_json (JSONC parser) now lives in functions.sh, shared with
# claude-project-setup.sh.

# Detect role (uses existing DOTPICKLES_ROLE from environment)
ROLE="${DOTPICKLES_ROLE:-home}"
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

# Pre-create sandbox cache directories that tools can't create themselves.
# Sandbox allowWrite permits writes UNDER an allowed path, but creating the
# directory itself requires write access to its parent, which isn't allowed.
# Without this, pip emits "cache disabled" and falls back to no-cache mode.
setup_sandbox_dirs() {
  echo "Pre-creating sandbox cache directories..."
  mkdir -p "$HOME/Library/Caches/pip"
  echo "  ✓ ~/Library/Caches/pip"
  # plannotator writes ~/.plannotator/sessions/<pid>.json; allowWrite covers
  # writes under ~/.plannotator but not creating the dir itself (needs ~/).
  mkdir -p "$HOME/.plannotator"
  echo "  ✓ ~/.plannotator"
}

setup_sandbox_dirs

# Generate settings.json from roles/ + stacks/
generate_settings() {
  echo "Generating settings.json..."

  local settings_file="$HOME/.claude/settings.json"
  local temp_file="$(mktemp)"

  # Local-only keys preserved from existing settings across regenerations
  local local_keys=("enabledPlugins" "extraKnownMarketplaces")

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

  # Extract permissions scalars (e.g. defaultMode) from base
  local permissions_scalars
  permissions_scalars=$(echo "$base_json" | jq '.permissions // {} | del(.allow, .ask, .deny)')

  # Extract sandbox from base (scalars + arrays)
  local sandbox_scalars sandbox_hosts sandbox_write_paths
  sandbox_scalars=$(echo "$base_json" | jq '.sandbox // {} | del(.network.allowedHosts, .filesystem.allowWrite, .filesystem, .network) + (if .network then {network: (.network | del(.allowedHosts))} else {} end) | del(.network | nulls) | del(.filesystem | nulls)')
  sandbox_hosts=$(echo "$base_json" | jq '.sandbox.network.allowedHosts // []')
  sandbox_write_paths=$(echo "$base_json" | jq '.sandbox.filesystem.allowWrite // []')

  echo "  + Loaded base role"

  # --- Load active role (if not base) ---
  local role_file="$DIR/claude/roles/$ROLE.jsonc"
  # Loud guard: a missing role file silently drops all role-specific settings
  # (env like GIT_CONFIG_GLOBAL, sandbox rules). That used to fail quietly when
  # DOTPICKLES_ROLE and the role filenames drifted apart. See ADR 0031.
  if [ "$ROLE" != "base" ] && [ ! -f "$role_file" ]; then
    echo "  ⚠️  WARNING: role '$ROLE' has no role file ($role_file)." >&2
    echo "     No role-specific env (e.g. GIT_CONFIG_GLOBAL) or sandbox rules will apply." >&2
    echo "     Check DOTPICKLES_ROLE and claude/roles/ for a name mismatch." >&2
  fi
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

    # Merge permissions scalars from role (role overrides base)
    local role_permissions_scalars
    role_permissions_scalars=$(echo "$role_json" | jq '.permissions // {} | del(.allow, .ask, .deny)')
    permissions_scalars=$(echo "$permissions_scalars" | jq --argjson r "$role_permissions_scalars" '. * $r')

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
    --argjson perm_scalars "$permissions_scalars" \
    --argjson sandbox_scalars "$sandbox_scalars" \
    --argjson hosts "$sandbox_hosts" \
    --argjson write_paths "$sandbox_write_paths" \
    '. + {
      permissions: ($perm_scalars + {allow: $allow, ask: $ask, deny: $deny}),
      sandbox: ($sandbox_scalars + {
        network: ($sandbox_scalars.network // {} | . + {allowedHosts: $hosts}),
        filesystem: {allowWrite: $write_paths}
      })
    }')

  # Merge in local-only settings
  final_settings=$(echo "$final_settings" | jq --argjson local "$local_settings" '. * $local')

  # Expand leading ~/ in .env string values. GIT_CONFIG_GLOBAL and similar
  # don't expand ~, so JSONC stays portable and we resolve to absolute paths
  # here before writing settings.json.
  final_settings=$(echo "$final_settings" | jq --arg home "$HOME" '
    if .env then
      .env |= with_entries(
        if (.value | type) == "string" and (.value | startswith("~/"))
        then .value = ($home + (.value | ltrimstr("~")))
        else .
        end
      )
    else . end
  ')

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

  # Marketplaces come from the shared manifest (single source of truth, also
  # read by claude-project-setup.sh). Format per line: "marketplace-id:owner/repo".
  local manifest="$DIR/claude/marketplaces.jsonc"
  if [ ! -f "$manifest" ]; then
    echo "Error: $manifest not found"
    exit 1
  fi
  local marketplaces=()
  while IFS= read -r entry; do
    marketplaces+=("$entry")
  done < <(read_json "$manifest" | jq -r '.marketplaces | to_entries[] | "\(.key):\(.value.repo)"')

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

# Register MCP servers into ~/.claude.json (user scope) from the shared
# manifest. Claude owns ~/.claude.json's format, so we drive the `claude mcp`
# CLI rather than hand-editing the file. Add-if-missing (idempotent), matching
# configure_marketplaces. To change an existing server, remove it first
# (`claude mcp remove <name> -s user`) and re-run.
configure_mcp_servers() {
  echo "Configuring MCP servers..."

  local manifest="$DIR/claude/mcp-servers.jsonc"
  if [ ! -f "$manifest" ]; then
    echo "Error: $manifest not found"
    exit 1
  fi

  local servers_json
  servers_json=$(read_json "$manifest" | jq -c '.servers // {}')

  local names
  names=$(echo "$servers_json" | jq -r 'keys[]')
  if [ -z "$names" ]; then
    echo "  ℹ no MCP servers declared"
    return 0
  fi

  local name
  while IFS= read -r name; do
    if claude mcp get "$name" > /dev/null 2>&1; then
      echo "  ✓ $name (already registered)"
      continue
    fi

    local transport url
    transport=$(echo "$servers_json" | jq -r --arg n "$name" '.[$n].transport // "http"')
    url=$(echo "$servers_json" | jq -r --arg n "$name" '.[$n].url // ""')

    case "$transport" in
      http | sse)
        if [ -z "$url" ]; then
          echo "  ✗ $name: transport '$transport' requires a url; skipping" >&2
          continue
        fi
        echo "  + Registering $name ($transport -> $url)..."
        if claude mcp add --transport "$transport" "$name" "$url" --scope user > /dev/null 2>&1; then
          echo "    ✓ Added to user config"
        else
          echo "    ✗ Failed to register $name (continuing anyway)" >&2
        fi
        ;;
      *)
        echo "  ✗ $name: unsupported transport '$transport' (only http/sse); skipping" >&2
        ;;
    esac
  done <<< "$names"
}

configure_mcp_servers

# Validate the active role's agent SSH identity (fail loud). Apply has already
# completed above, so this only affects the exit code -- config is never left
# half-written. Delegates to bin/check-agent-ssh-key, which validates local key
# files, Keychain, GitHub registration, live SSH auth, and (work role) per-org
# SAML SSO. The agent email is read from the role's gitconfig include so there's
# one source of truth. Skipped when the role has no agent identity, or when
# --skip-ssh-check / SKIP_SSH_CHECK=1 is set.
validate_agent_ssh_key() {
  echo "Validating agent SSH key..."

  if [ -n "$SKIP_SSH_CHECK" ]; then
    echo "  ⏭  skipped (--skip-ssh-check)"
    return 0
  fi

  local agent_include="$DIR/home/.gitconfig.d/claude-agent-$ROLE"
  if [ ! -f "$agent_include" ]; then
    echo "  ⏭  role '$ROLE' has no agent identity ($agent_include); nothing to validate"
    return 0
  fi

  local agent_email
  agent_email=$(git config --file "$agent_include" user.email 2> /dev/null || true)
  if [ -z "$agent_email" ]; then
    echo "  ✗ $agent_include has no user.email; cannot determine the agent identity to validate" >&2
    exit 1
  fi

  # The agent key path comes from the same include (signingkey), since the
  # identity name can differ from the role (e.g. home -> personal). This keeps
  # the gitconfig include the one source of truth; without it check-agent-ssh-key
  # would guess ~/.ssh/agents/$ROLE and miss the real key. See ADR 0035.
  local agent_key
  agent_key=$(git config --file "$agent_include" user.signingkey 2> /dev/null || true)

  echo "  Role '$ROLE' agent identity: $agent_email"
  local -a check_args=("$ROLE" --email "$agent_email")
  if [ -n "$agent_key" ]; then
    check_args+=(--key "$agent_key")
  fi
  if ! "$DIR/bin/check-agent-ssh-key" "${check_args[@]}"; then
    echo >&2
    echo "✗ Agent SSH key validation failed (see above)." >&2
    echo "  Fix the reported issue, or re-run with --skip-ssh-check to apply without validating." >&2
    exit 1
  fi
}

validate_agent_ssh_key

echo ""
echo "✓ Claude Code configuration complete"
echo "  Settings: $HOME/.claude/settings.json"
echo "  Role: $ROLE"
echo ""
echo "Note: Global skills are restored from ~/.agents/.skill-lock.json via skills.sh"
