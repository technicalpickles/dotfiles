# Claude Code Configuration

This directory contains the configuration templates for Claude Code settings and permissions. The configuration uses a **layered merging system** that combines roles (base settings + safety rules) with stacks (per-topic permissions and sandbox config).

## Architecture

```
claude/
├── marketplaces.jsonc     # Shared marketplaces + plugin profiles (see below)
├── mcp-servers.jsonc      # MCP servers registered into ~/.claude.json (see below)
├── roles/
│   ├── base.jsonc                # Core settings, base permissions, sandbox scalars
│   ├── home.jsonc                # Home role: agent git identity env, sandbox rules
│   ├── work.jsonc                # Work role: AWS/Bedrock env, work permissions
│   ├── container.jsonc           # Local container placeholder
│   └── claude-code-remote.jsonc  # Claude Code on the web: sandbox off, no agent id
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
├── rules/                 # Topic-specific global instructions (symlinked per-file to ~/.claude/rules/;
│                          #   role-scope one with a `dotpickles_role:` marker, see .claude/rules/claude-config.md)
│   ├── sandbox-paths.md
│   ├── taskwarrior.md
│   └── worktrees.md
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
      "allowedDomains": []
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
      "allowedDomains": [],
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

1. **Base role** (`roles/base.jsonc`): settings, permissions, sandbox, and `autoMode` extracted
2. **Active role** (`roles/$ROLE.jsonc`): settings deep-merged on top of base. Permissions, sandbox and `autoMode` arrays concatenated (not deep-merged, which would replace arrays)
3. **Stacks** (`stacks/*.jsonc`, sorted alphabetically): permissions, sandbox and `autoMode` arrays concatenated
4. **Private overlay** (`~/.config/dotpickles/roles/$ROLE.jsonc`, optional): a full role file kept outside this repo, merged last so it wins over everything above. See [Auto Mode Rules](#auto-mode-rules)
5. **Deduplication**: permissions and sandbox arrays sorted and deduplicated. `autoMode` arrays are deduplicated but **never sorted** -- order carries meaning there
6. **Local keys**: `enabledPlugins`, `extraKnownMarketplaces` preserved from existing `~/.claude/settings.json`
7. **Validation and write**

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
      "allowedDomains": ["foo.example.com"],
    },
    "filesystem": {
      "allowWrite": ["~/.foo"],
    },
  },
}
```

Then regenerate: `./claudeconfig.sh`

### Add a network host

Find the relevant stack file and add to `sandbox.network.allowedDomains`. For example, to allow a new npm registry:

Edit `claude/stacks/node.jsonc` and add to `allowedDomains`, then `./claudeconfig.sh`.

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

## Auto Mode Rules

The `autoMode` block feeds the LLM classifier that adjudicates tool calls while `defaultMode` is `auto`. It is generated like everything else, from `roles/` + `stacks/` + the private overlay. See [ADR 0056](../doc/adr/0056-auto-mode-classifier-rules-in-role-sources.md) for the full reasoning.

**It has to be generated into user settings.** Claude Code honours `autoMode` from user, `--settings` and managed settings only. Rules in a repo's `.claude/settings.json` are read, recognized, and deliberately ignored, because a cloned repo must not be able to talk the classifier into trusting it.

**`/auto-mode-setup` writes the wrong file.** It writes `~/.claude/settings.json`, which the next `./claudeconfig.sh` overwrites. So does `claude auto-mode reset`. Port anything you want to keep back into `roles/` or `stacks/`. Same contract as every other generated key, but this one has a CLI that invites you to edit it directly.

**Order matters, so these arrays are never sorted:**

- `$defaults` is a splice point. The shipped rules get inserted where that entry sits, so it stays first.
- An `allow`/`soft_deny`/`hard_deny` array without `$defaults` **replaces** the shipped rules instead of extending them. The generator prepends it if it is missing.
- `environment` is header-grouped: `### Org-wide` and `### User-specific`, each holding `**Label**: value` bullets from a fixed label list. The generator regroups by section after concatenating, and a later source's bullet **replaces** an earlier one with the same `**Label**`, in the earlier one's position.

**Where things go:**

| Content                                           | File                                     |
| ------------------------------------------------- | ---------------------------------------- |
| Role-invariant facts, `$defaults`, shipped labels | `roles/base.jsonc`                       |
| A tool's own carve-out                            | that tool's `stacks/*.jsonc`             |
| Home-only additions                               | `roles/home.jsonc`                       |
| Anything that can't be public                     | `~/.config/dotpickles/roles/$ROLE.jsonc` |

A role that needs the private overlay sets `"requiresPrivateOverlay": true` (stripped before writing settings). Without the overlay, `claudeconfig.sh` warns loudly rather than silently generating `base.jsonc`'s placeholder answers.

## Local Keys

These keys in `~/.claude/settings.json` are preserved across regenerations:

- `enabledPlugins`: plugin activation state
- `extraKnownMarketplaces`: managed by `configure_marketplaces()` in claudeconfig.sh

## Per-repo project setup

Two scripts stamp settings into an individual repo's `.claude/`, each solving
a different visibility problem: `cloud-project-setup.sh` writes what a _cloud_
session needs to see (so it must be committed), `local-project-setup.sh`
writes what only _this machine_ needs (so it must not be).

### Marketplaces and per-project plugins (cloud)

`marketplaces.jsonc` is the single source of truth for marketplaces (alias ->
GitHub repo) and named plugin `profiles` (`core`, `dev`; default `dev`). Two
consumers read it:

- `claudeconfig.sh` clones the marketplaces globally (`configure_marketplaces()`).
- `cloud-project-setup.sh [DIR] [--profile NAME] [--dry-run]` writes a repo's
  **committed** `.claude/settings.json` (`extraKnownMarketplaces` + `enabledPlugins`)
  so Claude Code on the web picks the plugins up. It merges into existing settings
  (permissions/hooks survive). See [ADR 0041](../doc/adr/0041-project-level-claude-plugin-bootstrap.md).

Plugin keys are `<plugin>@<marketplace-alias>`; the alias is the key in
`marketplaces`, and plugin names must match each repo's
`.claude-plugin/marketplace.json`.

### Cross-repo filesystem access (local)

`cross-repo-access.jsonc` maps a repo name to the sibling repos its sessions
routinely need to read/write directly (e.g. a `pickleclaw` session running
`git`/deploy commands against `picklehome`). The sandbox only auto-grants
write access to a session's own working directory, so without this, those
cross-repo commands fail with `Operation not permitted` and fall back to
`dangerouslyDisableSandbox`.

- `local-project-setup.sh [DIR] [--dry-run]` writes a repo's **gitignored**
  `.claude/settings.local.json` (`permissions.additionalDirectories`), listing
  each sibling as a directory alongside `DIR` (works under both
  `~/github.com/technicalpickles/` and pickled-coi's `~/projects/`). It merges
  into existing local settings the same way `cloud-project-setup.sh` merges
  into committed settings. See [ADR 0057](../doc/adr/0057-local-cross-repo-filesystem-access.md).

This one is deliberately the opposite of the cloud case: the paths are
machine-specific, so they belong in the gitignored `settings.local.json`, not
the committed `settings.json`. Since it's gitignored, re-run this script on
any other machine (or a fresh clone) where the same repo needs the same
cross-repo access.

## MCP servers

`mcp-servers.jsonc` is the single source of truth for MCP servers registered
into `~/.claude.json` (user scope, available in all projects). `claudeconfig.sh`
-> `configure_mcp_servers()` reads it and registers each via the `claude mcp`
CLI (Claude owns `~/.claude.json`'s format, so we drive the CLI instead of
hand-editing the file).

Registration is **add-if-missing** (idempotent), like marketplaces. Supported
transports: `http` and `sse` (both url-based).

```jsonc
"servers": {
  "qmd": { "transport": "http", "url": "http://localhost:8181/mcp" },
}
```

To change an existing server's url/transport, remove it first, then re-run:

```bash
claude mcp remove user < name > -s && ./claudeconfig.sh
```

(The qmd server itself is run by the `com.technicalpickles.qmd-mcp` LaunchAgent;
see `LaunchAgents/README.md`.)

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
jq '.sandbox.network.allowedDomains' ~/.claude/settings.json

# Check filesystem write paths
jq '.sandbox.filesystem.allowWrite' ~/.claude/settings.json

# Verify claudeconfig.sh output
./claudeconfig.sh # Watch for "Loaded base role", "Merged X stack" messages
```
