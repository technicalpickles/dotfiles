# Claude Code Configuration

This directory contains the configuration templates for Claude Code settings and permissions. The configuration uses a **layered merging system** that combines base settings with role-specific and ecosystem-specific permissions.

## Architecture

```
claude/
├── settings.base.json         # Core settings (all roles)
├── settings.personal.json     # Personal role overrides
├── settings.work.json         # Work role overrides
├── permissions.json           # Base permissions (deny rules)
├── permissions.personal.json  # Personal-specific permissions
├── permissions.work.json      # Work-specific permissions
├── permissions.skills.json    # Skill permissions (cross-project)
├── permissions.node.json      # Node.js ecosystem (npm, yarn, npx)
├── permissions.ruby.json      # Ruby ecosystem (bundle, rake, rspec)
├── permissions.python.json    # Python ecosystem (pip, pytest, uv)
├── permissions.go.json        # Go ecosystem (go build, go test)
├── permissions.rust.json      # Rust ecosystem (cargo)
├── permissions.shell.json     # Shell utilities (jq, fd, rg, etc.)
├── permissions.github.json    # GitHub CLI (gh pr, gh issue, etc.)
├── permissions.docker.json    # Docker/container commands
├── permissions.git.jsonc      # Git commands
├── permissions.mise.json      # mise version manager
├── permissions.mcp.json       # MCP-related permissions
└── permissions.web.json       # Web fetching domains
```

## How Merging Works

When you run `./claudeconfig.sh`:

1. **Settings**: `settings.base.json` + `settings.$ROLE.json` are deep-merged
2. **Permissions**: All `permissions.*.json` files are concatenated:
   - `permissions.json` (base deny rules)
   - `permissions.$ROLE.json` (role-specific)
   - All ecosystem files (`permissions.node.json`, `permissions.ruby.json`, etc.)
3. **Deduplication**: Allow/deny lists are sorted and deduplicated
4. **Local preservation**: Keys like `awsAuthRefresh` and `env` are preserved from existing `~/.claude/settings.json`

## Common Tasks

### Add a frequently-used skill permission

If you keep getting prompted for a skill across multiple projects:

1. Add to `permissions.skills.json`:

   ```json
   {
     "allow": ["Skill(existing:skill)", "Skill(new-plugin:new-skill)"]
   }
   ```

2. Regenerate global settings:

   ```bash
   ./claudeconfig.sh
   ```

3. Clean up project-local duplicates:
   ```bash
   claude-permissions cleanup         # Preview changes
   claude-permissions cleanup --force # Apply changes
   ```

### Add a new ecosystem permission file

1. Create `claude/permissions.neweco.json`:

   ```json
   {
     "allow": ["Bash(newtool:*)", "Bash(newtool build:*)"],
     "deny": []
   }
   ```

2. Regenerate: `./claudeconfig.sh`

The filename pattern `permissions.*.json` is auto-discovered (excluding base, personal, and work files).

### Add an "always ask" rule

Use `ask` for commands that should always prompt for confirmation (useful for destructive but sometimes-needed operations):

```json
{
  "allow": ["Bash(cleanup-tool)"],
  "ask": ["Bash(cleanup-tool --force)"],
  "deny": []
}
```

### Add a deny rule

Add to `permissions.json` (applies to all roles):

```json
{
  "allow": [],
  "deny": ["Bash(dangerous-command:*)"]
}
```

### Check current permissions state

```bash
# Summary view
claude-permissions

# See all skills specifically
claude-permissions --aggregate | grep Skill

# Full JSON for scripting
claude-permissions --json

# See what's in each file
claude-permissions --raw
```

### Find and clean up duplicates

The `claude-permissions cleanup` command removes project-local permissions that duplicate global settings:

```bash
# Preview what would be removed
claude-permissions cleanup

# Example output:
#  -12  my-project       3 left
#   -8  other-project    empty
# Would remove: 20 entries from 2 files

# Apply the cleanup
claude-permissions cleanup --force
```

## Permission Syntax

### Permission Lists

| List    | Behavior                                                            |
| ------- | ------------------------------------------------------------------- |
| `allow` | Always permitted without prompting                                  |
| `ask`   | Always prompts for confirmation (useful for destructive operations) |
| `deny`  | Always blocked                                                      |

### Permission Format

| Type     | Example                        | Description                 |
| -------- | ------------------------------ | --------------------------- |
| Bash     | `Bash(npm run:*)`              | Allow npm run with any args |
| Bash     | `Bash(gh pr create:*)`         | Allow gh pr create          |
| Skill    | `Skill(plugin:skill-name)`     | Allow invoking a skill      |
| WebFetch | `WebFetch(domain:example.com)` | Allow fetching from domain  |
| MCP      | `mcp__servername__toolname`    | Allow MCP tool              |

Wildcards:

- `*` matches any arguments
- `Bash(npm:*)` allows `npm` with any subcommand/args

## Workflow: Promoting Project Permissions to Global

When you notice you're repeatedly approving the same permission across projects:

1. **Audit current state**:

   ```bash
   claude-permissions --aggregate | grep "2x\|3x\|4x"
   ```

2. **Identify candidates**: Permissions appearing 2+ times are good candidates

3. **Add to appropriate file**:

   - Skills → `permissions.skills.json`
   - Language tools → `permissions.{lang}.json`
   - General tools → `permissions.shell.json`

4. **Regenerate and clean up**:

   ```bash
   ./claudeconfig.sh
   claude-permissions cleanup --force
   ```

5. **Commit changes** to dotfiles

## Files NOT to Edit

- `~/.claude/settings.json` - Generated by `claudeconfig.sh`, will be overwritten
- Exception: `awsAuthRefresh` and `env` keys are preserved across regenerations

## Debugging

If permissions aren't working as expected:

```bash
# Check what's actually in global settings
jq '.permissions' ~/.claude/settings.json

# Check specific permission type
jq '.permissions.allow[]' ~/.claude/settings.json | grep -i skill

# Verify claudeconfig.sh output
./claudeconfig.sh # Watch for "Merging X permissions" messages
```
