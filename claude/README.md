# Claude Code Configuration

This directory contains the configuration templates for Claude Code settings and permissions. The configuration uses a **layered merging system** that combines roles (base settings + safety rules) with stacks (per-topic permissions and sandbox config).

## Architecture

```
claude/
├── roles/
│   ├── base.jsonc         # Core settings, base permissions, sandbox scalars
│   ├── personal.jsonc     # Personal role overrides (empty placeholder)
│   └── work.jsonc         # Work role: AWS/Bedrock env, work permissions
├── stacks/
│   ├── beans.jsonc        # Beans issue tracker
│   ├── buildkite.jsonc    # Buildkite CI
│   ├── colima.jsonc       # Colima container runtime
│   ├── docker.jsonc       # Docker container management
│   ├── docs.jsonc         # Reference documentation sites
│   ├── git.jsonc          # Git operations
│   ├── github.jsonc       # GitHub CLI
│   ├── go.jsonc           # Go ecosystem
│   ├── mcp.jsonc          # MCP proxy tools
│   ├── mise.jsonc         # mise version manager
│   ├── node.jsonc         # Node.js ecosystem (npm, yarn, pnpm)
│   ├── python.jsonc       # Python ecosystem (pip, uv, pytest)
│   ├── ruby.jsonc         # Ruby ecosystem (bundle, rake, rspec)
│   ├── rust.jsonc         # Rust ecosystem (cargo, rustup)
│   ├── shell.jsonc        # Shell utilities (jq, fd, grep, etc.)
│   └── skills.jsonc       # Skill permissions
├── CLAUDE.md              # Claude Code instructions (symlinked to ~/.claude/)
└── README.md              # This file
```

## Schema

All files use JSONC (`.jsonc`), allowing `//` and `/* */` comments. Use comments to document provenance (e.g. `// source: agent-safehouse`).

### Role files

Role files hold settings, permissions, and sandbox config:

```jsonc
{
  // Settings (any Claude Code setting keys)
  "statusLine": { "..." },
  "includeCoAuthoredBy": true,

  // Permissions
  "permissions": {
    "allow": [],
    "ask": [],
    "deny": []
  },

  // Sandbox (scalars live in roles only)
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "enableWeakerNetworkIsolation": true,
    "network": {
      "allowAllUnixSockets": true,
      "allowedHosts": []
    }
  }
}
```

### Stack files

Stack files hold per-topic permissions and sandbox arrays (no scalars):

```jsonc
{
  "permissions": {
    "allow": [],
    "ask": [],
    "deny": [],
  },
  "sandbox": {
    "network": {
      "allowedHosts": [],
    },
    "filesystem": {
      "allowWrite": [],
    },
  },
}
```

All keys are optional. A stack can have only `permissions`, only `sandbox`, or both.

## How Merging Works

When you run `./claudeconfig.sh`:

1. **Base role** (`roles/base.jsonc`): settings, permissions, and sandbox extracted
2. **Active role** (`roles/$ROLE.jsonc`): settings deep-merged on top of base. Permissions and sandbox arrays concatenated (not deep-merged, which would replace arrays)
3. **Stacks** (`stacks/*.jsonc`, sorted alphabetically): permissions and sandbox arrays concatenated
4. **Deduplication**: all arrays sorted and deduplicated
5. **Local keys**: `enabledPlugins`, `extraKnownMarketplaces` preserved from existing `~/.claude/settings.json`
6. **Validation and write**

## Common Tasks

### Add a new stack

Create `claude/stacks/foo.jsonc`:

```jsonc
{
  // Foo tool
  "permissions": {
    "allow": ["Bash(foo:*)"],
  },
  // Optional: sandbox config
  "sandbox": {
    "network": {
      "allowedHosts": ["foo.example.com"],
    },
    "filesystem": {
      "allowWrite": ["~/.foo"],
    },
  },
}
```

Then regenerate: `./claudeconfig.sh`

### Add a network host

Find the relevant stack file and add to `sandbox.network.allowedHosts`. For example, to allow a new npm registry:

Edit `claude/stacks/node.jsonc` and add to `allowedHosts`, then `./claudeconfig.sh`.

### Add a filesystem write path

Same pattern: find the relevant stack and add to `sandbox.filesystem.allowWrite`.

### Add a skill permission

Edit `claude/stacks/skills.jsonc` and add to `permissions.allow`:

```jsonc
"Skill(plugin-name:skill-name)"
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

```bash
# Preview what would be removed
claude-permissions cleanup

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

1. **Audit**: `claude-permissions --aggregate | grep "2x\|3x\|4x"`
2. **Add to appropriate stack file**
3. **Regenerate**: `./claudeconfig.sh`
4. **Clean up**: `claude-permissions cleanup --force`
5. **Commit** to dotfiles

## Local Keys

These keys in `~/.claude/settings.json` are preserved across regenerations:

- `enabledPlugins`: plugin activation state (tracked in gt-1bil)
- `extraKnownMarketplaces`: managed by `configure_marketplaces()` in claudeconfig.sh

## Files NOT to Edit

- `~/.claude/settings.json`: generated by `claudeconfig.sh`, will be overwritten
- Exception: `enabledPlugins` and `extraKnownMarketplaces` are preserved

## Debugging

```bash
# Check what's actually in global settings
jq '.permissions' ~/.claude/settings.json

# Check specific permission type
jq '.permissions.allow[]' ~/.claude/settings.json | grep -i skill

# Check sandbox config
jq '.sandbox' ~/.claude/settings.json

# Check network hosts
jq '.sandbox.network.allowedHosts' ~/.claude/settings.json

# Check filesystem write paths
jq '.sandbox.filesystem.allowWrite' ~/.claude/settings.json

# Verify claudeconfig.sh output
./claudeconfig.sh # Watch for "Loaded base role", "Merged X stack" messages
```
