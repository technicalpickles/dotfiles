# Claude Code Configuration Management Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Automate Claude Code configuration with role-based settings, permissions, and plugin management using generated settings.json.

**Architecture:** Follow existing gitconfig.sh pattern - generator script merges JSON fragments (base + role-specific) while preserving local-only settings. Idempotent marketplace/plugin installation integrated into generation script.

**Tech Stack:** Bash, jq, Claude CLI

---

## Task 1: Create Base Settings Configuration

**Files:**

- Create: `claude/settings.base.json`

**Step 1: Create claude directory**

```bash
mkdir -p claude
```

**Step 2: Create base settings file**

Create `claude/settings.base.json` with shared settings:

```json
{
  "statusLine": {
    "type": "command",
    "command": "npx -y @owloops/claude-powerline@latest --style=capsule"
  },
  "includeCoAuthoredBy": false,
  "alwaysThinkingEnabled": false,
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "elements-of-style@superpowers-marketplace": true,
    "superpowers-developing-for-claude-code@superpowers-marketplace": true,
    "git-workflows@technicalpickles-marketplace": true,
    "working-in-monorepos@technicalpickles-marketplace": true,
    "ci-cd-tools@technicalpickles-marketplace": true,
    "debugging-tools@technicalpickles-marketplace": true,
    "dev-tools@technicalpickles-marketplace": true,
    "document-skills@anthropic-agent-skills": true,
    "claude-notifications-go@claude-notifications-go": true
  }
}
```

**Step 3: Verify JSON syntax**

```bash
jq empty claude/settings.base.json
```

Expected: No output (valid JSON)

**Step 4: Commit**

```bash
git add claude/settings.base.json
git commit -m "feat: add base Claude Code settings"
```

---

## Task 2: Create Role-Specific Settings Files

**Files:**

- Create: `claude/settings.personal.json`
- Create: `claude/settings.work.json`

**Step 1: Create personal settings file**

Create `claude/settings.personal.json` (initially empty overrides):

```json
{}
```

**Step 2: Create work settings file**

Create `claude/settings.work.json` (initially empty overrides):

```json
{}
```

**Step 3: Verify JSON syntax**

```bash
jq empty claude/settings.personal.json
jq empty claude/settings.work.json
```

Expected: No output (valid JSON)

**Step 4: Commit**

```bash
git add claude/settings.personal.json claude/settings.work.json
git commit -m "feat: add role-specific Claude Code settings placeholders"
```

---

## Task 3: Create Base Permissions Configuration

**Files:**

- Create: `claude/permissions.json`

**Step 1: Extract common permissions from current settings**

Review `~/.claude/settings.json` and identify common permissions that apply to all environments.

**Step 2: Create permissions.json**

Create `claude/permissions.json`:

```json
[
  "Bash(gh pr list:*)",
  "Bash(gh pr view:*)",
  "Bash(git worktree:*)",
  "Bash(tree:*)",
  "mcp__MCPProxy__call_tool",
  "mcp__MCPProxy__retrieve_tools",
  "Read(~/.claude/plugins/cache/dev-tools/skills/working-in-scratch-areas/**)",
  "Read(~/.claude/plugins/cache/elements-of-style/skills/writing-clearly-and-concisely/**)",
  "Read(~/.claude/plugins/cache/superpowers-developing-for-claude-code/skills/working-with-claude-code/**)",
  "Read(~/.claude/plugins/cache/superpowers/skills/brainstorming/**)",
  "Read(~/.claude/plugins/cache/superpowers/skills/executing-plans/**)",
  "Read(~/.claude/plugins/cache/superpowers/skills/finishing-a-development-branch/**)",
  "Read(~/.claude/plugins/cache/superpowers/skills/receiving-code-review/**)",
  "Read(~/.claude/plugins/cache/superpowers/skills/subagent-driven-development/**)",
  "Read(~/.claude/plugins/cache/superpowers/skills/systematic-debugging/**)",
  "Read(~/.claude/plugins/cache/superpowers/skills/using-git-worktrees/**)",
  "Read(~/.claude/plugins/cache/superpowers/skills/using-superpowers/**)",
  "Read(~/.claude/plugins/cache/superpowers/skills/writing-plans/**)",
  "Read(~/.claude/plugins/cache/superpowers/skills/writing-skills/**)",
  "Read(~/.claude/plugins/cache/working-in-monorepos/skills/working-in-monorepos/**)",
  "Skill(dev-tools:working-in-scratch-areas)",
  "Skill(elements-of-style:writing-clearly-and-concisely)",
  "Skill(superpowers-developing-for-claude-code:working-with-claude-code)",
  "Skill(superpowers:brainstorming)",
  "Skill(superpowers:executing-plans)",
  "Skill(superpowers:finishing-a-development-branch)",
  "Skill(superpowers:receiving-code-review)",
  "Skill(superpowers:subagent-driven-development)",
  "Skill(superpowers:systematic-debugging)",
  "Skill(superpowers:using-git-worktrees)",
  "Skill(superpowers:using-superpowers)",
  "Skill(superpowers:writing-plans)",
  "Skill(superpowers:writing-skills)",
  "Skill(working-in-monorepos:working-in-monorepos)",
  "WebFetch(domain:aquasecurity.github.io)",
  "WebFetch(domain:code.claude.com)",
  "WebFetch(domain:github.com)",
  "WebFetch(domain:karafka.io)",
  "WebFetch(domain:trivy.dev)",
  "WebFetch(domain:www.reddit.com)"
]
```

**Step 3: Verify JSON syntax**

```bash
jq empty claude/permissions.json
```

Expected: No output (valid JSON)

**Step 4: Commit**

```bash
git add claude/permissions.json
git commit -m "feat: add base Claude Code permissions"
```

---

## Task 4: Create Role-Specific Permissions Files

**Files:**

- Create: `claude/permissions.personal.json`
- Create: `claude/permissions.work.json`

**Step 1: Create personal permissions file**

Create `claude/permissions.personal.json` (initially empty):

```json
[]
```

**Step 2: Create work permissions file**

Create `claude/permissions.work.json` with work-specific Ruby/Rails permissions:

```json
[
  "Bash(bin/rspec:*)",
  "Bash(bin/rubocop:*)",
  "Bash(bundle exec rspec:*)",
  "Bash(bundle exec rubocop:*)",
  "Bash(bundle install)"
]
```

**Step 3: Verify JSON syntax**

```bash
jq empty claude/permissions.personal.json
jq empty claude/permissions.work.json
```

Expected: No output (valid JSON)

**Step 4: Commit**

```bash
git add claude/permissions.personal.json claude/permissions.work.json
git commit -m "feat: add role-specific Claude Code permissions"
```

---

## Task 5: Create claudeconfig.sh Script (Part 1: Setup and Validation)

**Files:**

- Create: `claudeconfig.sh`

**Step 1: Create script with shebang and source functions**

Create `claudeconfig.sh`:

```bash
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
```

**Step 2: Make script executable**

```bash
chmod +x claudeconfig.sh
```

**Step 3: Test prerequisite checks**

```bash
./claudeconfig.sh
```

Expected: Should print role detection message (if claude and jq are available)

**Step 4: Commit**

```bash
git add claudeconfig.sh
git commit -m "feat: add claudeconfig.sh with prerequisites and role detection"
```

---

## Task 6: Create claudeconfig.sh Script (Part 2: Marketplace Installation)

**Files:**

- Modify: `claudeconfig.sh`

**Step 1: Add marketplace installation function**

Add after role detection in `claudeconfig.sh`:

```bash
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
    if claude marketplace list 2> /dev/null | grep -q "$marketplace"; then
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
```

**Step 2: Test marketplace installation**

```bash
./claudeconfig.sh
```

Expected: Should check/add marketplaces idempotently

**Step 3: Commit**

```bash
git add claudeconfig.sh
git commit -m "feat: add marketplace installation to claudeconfig.sh"
```

---

## Task 7: Create claudeconfig.sh Script (Part 3: Plugin Installation)

**Files:**

- Modify: `claudeconfig.sh`

**Step 1: Add plugin installation function**

Add after marketplace installation in `claudeconfig.sh`:

```bash
# Install plugins (idempotent)
install_plugins() {
  echo "Installing plugins..."

  local plugins=(
    "superpowers@superpowers-marketplace"
    "elements-of-style@superpowers-marketplace"
    "superpowers-developing-for-claude-code@superpowers-marketplace"
    "git-workflows@technicalpickles-marketplace"
    "working-in-monorepos@technicalpickles-marketplace"
    "ci-cd-tools@technicalpickles-marketplace"
    "debugging-tools@technicalpickles-marketplace"
    "dev-tools@technicalpickles-marketplace"
    "document-skills@anthropic-agent-skills"
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
```

**Step 2: Test plugin installation**

```bash
./claudeconfig.sh
```

Expected: Should check/install plugins idempotently

**Step 3: Commit**

```bash
git add claudeconfig.sh
git commit -m "feat: add plugin installation to claudeconfig.sh"
```

---

## Task 8: Create claudeconfig.sh Script (Part 4: Settings Generation)

**Files:**

- Modify: `claudeconfig.sh`

**Step 1: Add settings generation function**

Add after plugin installation in `claudeconfig.sh`:

```bash
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
```

**Step 2: Test settings generation**

```bash
./claudeconfig.sh
```

Expected: Should generate `~/.claude/settings.json` with merged configuration

**Step 3: Verify generated settings**

```bash
jq empty ~/.claude/settings.json
jq keys ~/.claude/settings.json
```

Expected: Valid JSON with expected keys (statusLine, includeCoAuthoredBy, permissions, etc.)

**Step 4: Commit**

```bash
git add claudeconfig.sh
git commit -m "feat: add settings generation to claudeconfig.sh"
```

---

## Task 9: Create claudeconfig.sh Script (Part 5: Completion Message)

**Files:**

- Modify: `claudeconfig.sh`

**Step 1: Add completion message**

Add at the end of `claudeconfig.sh`:

```bash
echo ""
echo "✓ Claude Code configuration complete"
echo "  Settings: $HOME/.claude/settings.json"
echo "  Role: $ROLE"
```

**Step 2: Test full script**

```bash
./claudeconfig.sh
```

Expected: Should run all steps and print completion message

**Step 3: Commit**

```bash
git add claudeconfig.sh
git commit -m "feat: add completion message to claudeconfig.sh"
```

---

## Task 10: Integrate claudeconfig.sh into install.sh

**Files:**

- Modify: `install.sh`

**Step 1: Find gitconfig.sh call location**

```bash
grep -n "gitconfig.sh" install.sh
```

Expected: Should find line where gitconfig.sh is called

**Step 2: Add claudeconfig.sh call after gitconfig.sh**

Add after the gitconfig.sh section in `install.sh`:

```bash
# Setup Claude Code configuration
if command_available claude; then
  echo "Configuring Claude Code..."
  bash "$DIR/claudeconfig.sh"
else
  echo "Claude Code not installed, skipping configuration"
fi
```

**Step 3: Verify integration**

```bash
grep -A3 "Configuring Claude Code" install.sh
```

Expected: Should show the added section

**Step 4: Commit**

```bash
git add install.sh
git commit -m "feat: integrate claudeconfig.sh into install.sh"
```

---

## Task 11: Update CLAUDE.md Documentation

**Files:**

- Modify: `CLAUDE.md`

**Step 1: Add Claude Code Configuration section**

Add new section to `CLAUDE.md` after the "Custom Binaries" section:

````markdown
## Claude Code Configuration

Claude Code settings are managed using a role-based configuration system similar to git configuration.

### Configuration Files

```bash
claude/
├── settings.base.json        # Core settings (statusLine, alwaysThinkingEnabled, etc.)
├── settings.personal.json    # Personal role overrides
├── settings.work.json        # Work role overrides
├── permissions.json          # Base permissions (common tools/skills)
├── permissions.personal.json # Personal-specific permissions
└── permissions.work.json     # Work-specific permissions
```
````

### Generation and Installation

```bash
# Generate settings.json from configuration fragments
./claudeconfig.sh

# Or regenerate during installation
./install.sh
```

The script:

1. Installs marketplaces (idempotent)
2. Installs plugins (idempotent)
3. Merges base + role-specific settings
4. Merges base + role-specific permissions
5. Preserves local-only settings (AWS credentials, etc.)
6. Generates `~/.claude/settings.json`

### Local-Only Settings

Settings like `awsAuthRefresh` and `env` are considered local-only and are preserved across regenerations. Add these manually to `~/.claude/settings.json` after running `claudeconfig.sh`.

### Adding New Permissions

1. For common permissions: Add to `claude/permissions.json`
2. For role-specific permissions: Add to `claude/permissions.personal.json` or `claude/permissions.work.json`
3. Regenerate: `./claudeconfig.sh`

### Adding New Plugins

1. Add marketplace to `marketplaces` array in `claudeconfig.sh`
2. Add plugin to `plugins` array in `claudeconfig.sh`
3. Add to `enabledPlugins` in `claude/settings.base.json` (or role-specific settings)
4. Regenerate: `./claudeconfig.sh`

````

**Step 2: Verify documentation clarity**

```bash
cat CLAUDE.md | grep -A20 "Claude Code Configuration"
````

Expected: Should show the added documentation

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add Claude Code configuration documentation to CLAUDE.md"
```

---

## Task 12: Create Architecture Decision Record

**Files:**

- Create: `doc/adr/0013-claude-code-configuration-management.md`

**Step 1: Create ADR using adr tool**

```bash
bin/adr new "Claude Code Configuration Management"
```

Expected: Creates new ADR file

**Step 2: Edit ADR with decision details**

Update the ADR file:

```markdown
# 13. Claude Code Configuration Management

Date: 2025-11-25

## Status

Accepted

## Context

Claude Code configuration includes settings (statusLine, co-authored, thinking mode), permissions (tool allowlists), marketplace setup, and plugin installation. This configuration needs to be:

- Reproducible across machines
- Role-aware (personal vs work environments)
- Version controlled (except sensitive data)
- Easy to regenerate and keep in sync

The existing dotfiles repository already uses:

- Role-based configuration (`$DOTPICKLES_ROLE`)
- Generated configs (gitconfig.sh builds .gitconfig.local)
- Symlinked files (home/ → $HOME)

We needed a way to manage Claude Code configuration that:

1. Doesn't commit sensitive data (AWS credentials)
2. Supports role-specific overrides
3. Handles idempotent marketplace/plugin installation
4. Works with manual additions (local-only settings)

## Decision

Implement Claude Code configuration management following the gitconfig.sh pattern:

### Configuration Structure
```

claude/
├── settings.base.json # Core settings
├── settings.$ROLE.json      # Role overrides
├── permissions.json         # Base permissions
└── permissions.$ROLE.json # Role-specific permissions

```

### Generation Script

`claudeconfig.sh` (similar to gitconfig.sh):
1. Installs marketplaces idempotently (checks before adding)
2. Installs plugins idempotently (checks before installing)
3. Merges settings: base + role-specific
4. Merges permissions: base + role-specific
5. Preserves local-only keys (awsAuthRefresh, env)
6. Generates `~/.claude/settings.json` atomically

### Integration

- `install.sh` runs `claudeconfig.sh` after gitconfig setup
- Manual regeneration: `./claudeconfig.sh`
- Marketplace/plugin lists hardcoded in script (like Fish configs)

### Alternatives Considered

1. **Template + manual merge**: Track settings.template.json, document manual copying
   - Rejected: Error-prone, not automated, doesn't support role-based config

2. **Modular JSON fragments**: Separate files per concern (plugins.json, statusline.json)
   - Rejected: Over-engineered for current needs, harder to understand structure

3. **Native settings.local.json**: Rely on Claude Code supporting local file merging
   - Rejected: Claude Code doesn't support this (confirmed via documentation check)

4. **Environment variable substitution**: Template with $AWS_PROFILE placeholders
   - Rejected: Doesn't handle complex nested JSON (env object), less flexible

5. **Separate marketplace/plugin scripts**: Individual files for each concern
   - Rejected: User wanted single file, following Fish pattern

## Consequences

### Positive

- **Consistent with existing patterns**: Uses same approach as gitconfig.sh
- **Role-aware**: Automatically adapts to personal/work environments
- **Idempotent**: Safe to run multiple times, no duplicate installations
- **Preserves manual additions**: Local-only settings survive regeneration
- **Automated setup**: Fresh machines get complete config via install.sh
- **Version controlled**: All configuration tracked except sensitive data

### Negative

- **Manual local settings**: AWS credentials must be added manually after generation
- **No validation of marketplace/plugin names**: Typos won't be caught until runtime
- **Hardcoded lists**: Adding plugins requires editing script (not separate config file)
- **Assumes jq available**: Requires jq for JSON merging (added to prerequisites)

### Maintenance

- **Adding permissions**: Edit claude/permissions.json or claude/permissions.$ROLE.json
- **Adding plugins**: Update both `plugins` array in claudeconfig.sh AND `enabledPlugins` in settings files
- **Adding settings**: Update claude/settings.base.json or role-specific files
- **Regeneration**: Run `./claudeconfig.sh` after any configuration changes
```

**Step 3: Verify ADR content**

```bash
cat doc/adr/0013-claude-code-configuration-management.md
```

Expected: Should show complete ADR

**Step 4: Commit**

```bash
git add doc/adr/0013-claude-code-configuration-management.md
git commit -m "docs: add ADR for Claude Code configuration management"
```

---

## Task 13: Test Full Workflow in Devcontainer

**Files:**

- None (testing only)

**Step 1: Backup current settings**

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.pretest
```

**Step 2: Run claudeconfig.sh**

```bash
./claudeconfig.sh
```

Expected: Should complete successfully with all steps

**Step 3: Verify generated settings**

```bash
# Check file exists and is valid JSON
jq empty ~/.claude/settings.json

# Check expected keys present
jq 'has("statusLine") and has("includeCoAuthoredBy") and has("alwaysThinkingEnabled") and has("enabledPlugins") and has("permissions")' ~/.claude/settings.json
```

Expected: Should output `true`

**Step 4: Check local settings preserved**

```bash
# If you had AWS settings before
jq 'has("awsAuthRefresh") or has("env")' ~/.claude/settings.json
```

Expected: Should show true if those keys existed in original file

**Step 5: Verify idempotency - run again**

```bash
./claudeconfig.sh
```

Expected: Should show "already added/installed" for marketplaces/plugins

**Step 6: Restore backup if needed**

```bash
# If something went wrong
cp ~/.claude/settings.json.pretest ~/.claude/settings.json
```

---

## Task 14: Run Linting and Format Check

**Files:**

- None (verification only)

**Step 1: Run TypeScript type check**

```bash
npm run typecheck
```

Expected: No errors (no TypeScript files were modified)

**Step 2: Run format check**

```bash
npm run format:check
```

Expected: All files properly formatted

**Step 3: Fix formatting if needed**

```bash
npm run format
```

**Step 4: Verify tests pass**

```bash
npm test
```

Expected: All checks pass

---

## Task 15: Final Commit and Summary

**Files:**

- Modify: `docs/plans/2025-11-25-claude-code-configuration-design.md`

**Step 1: Update design document status**

Update the design document to mark it as implemented:

```bash
# Add implementation note to design doc
sed -i.bak '3s/Validated/Implemented/' docs/plans/2025-11-25-claude-code-configuration-design.md
```

**Step 2: Review all changes**

```bash
git log --oneline feature/claude-code-config ^main
```

Expected: Should show all commits made during implementation

**Step 3: Verify branch is clean**

```bash
git status
```

Expected: No uncommitted changes

**Step 4: Create summary of implementation**

The implementation includes:

- 6 JSON configuration files (base + role-specific settings and permissions)
- 1 generator script (claudeconfig.sh with 5 major sections)
- Integration into install.sh
- Updated CLAUDE.md documentation
- ADR documenting the architectural decision
- Full testing in current environment

All files follow existing dotfiles patterns and conventions.

---

## Execution Complete

Once all tasks are complete, use `superpowers:finishing-a-development-branch` to handle PR creation or merge.
