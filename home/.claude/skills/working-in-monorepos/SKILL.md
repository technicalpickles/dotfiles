---
name: working-in-monorepos
description: Use when working in repositories with multiple subprojects (monorepos) where commands need to run from specific directories - prevents directory confusion, redundant cd commands, and ensures commands execute from correct locations
---

# Working in Monorepos

## Overview

Helps Claude work effectively in monorepo environments by ensuring commands always execute from the correct location using absolute paths.

**Core principle:** Bash shell state is not guaranteed between commands. Always use absolute paths.

**Announce at start:** "I'm using the working-in-monorepos skill."

## When to Use

Use this skill when:

- Repository contains multiple subprojects (ruby/, cli/, components/\*, etc.)
- Commands must run from specific directories
- Working across multiple subprojects in one session

Don't use for:

- Single-project repositories
- Repositories where all commands run from root

## The Iron Rule: Always Use Absolute Paths

When executing ANY command in a monorepo subproject:

✅ **CORRECT:**

```bash
cd /Users/josh/workspace/schemaflow/ruby && bundle exec rspec
cd /Users/josh/workspace/schemaflow/cli && npm test
```

❌ **WRONG:**

```bash
# Relative paths (assumes current directory)
cd ruby && bundle exec rspec

# No cd prefix (assumes location)
bundle exec rspec

# Chaining cd (compounds errors)
cd ruby && cd ruby && rspec
```

**Why:** You cannot rely on shell state. Absolute paths guarantee correct execution location regardless of where the shell currently is.

## Constructing Absolute Paths

### With .monorepo.json Config

If `.monorepo.json` exists at repo root:

1. Read `root` field for absolute repo path
2. Read subproject `path` from `subprojects` map
3. Construct: `cd {root}/{path} && command`

Example:

```json
{
  "root": "/Users/josh/workspace/schemaflow",
  "subprojects": { "ruby": { "path": "ruby" } }
}
```

→ `cd /Users/josh/workspace/schemaflow/ruby && bundle exec rspec`

### Without Config

Use git to find repo root dynamically:

```bash
cd $(git rev-parse --show-toplevel)/ruby && bundle exec rspec
```

## Setup Workflow (No Config Present)

When skill activates in a repo without `.monorepo.json`:

1. **Detect:** "I notice this appears to be a monorepo without a .monorepo.json config."
2. **Offer:** "I can run ~/.claude/skills/working-in-monorepos/scripts/monorepo-init to auto-detect subprojects and generate config. Would you like me to?"
3. **User accepts:** Run `~/.claude/skills/working-in-monorepos/scripts/monorepo-init --dry-run`, show output, ask for approval, then `~/.claude/skills/working-in-monorepos/scripts/monorepo-init --write`
4. **User declines:** "No problem. I'll use git to find the repo root for each command."
5. **User wants custom:** "You can also create .monorepo.json manually. See example below."

**Helper Script Philosophy:**

The `monorepo-init` script is designed as a **black-box tool**:

- **Always run with `--help` first** to see usage
- **DO NOT read the script source** unless absolutely necessary - it pollutes your context window
- The script exists to be called directly, not analyzed
- All necessary usage information is in the help output

```bash
~/.claude/skills/working-in-monorepos/scripts/monorepo-init --help
```

## Command Execution Rules (With Config)

If `.monorepo.json` defines command rules:

```json
{
  "commands": {
    "rubocop": { "location": "root" },
    "rspec": {
      "location": "subproject",
      "command": "bundle exec rspec",
      "overrides": { "root": { "command": "bin/rspec" } }
    }
  }
}
```

**Check rules before executing:**

1. Look up command in `commands` map
2. Check `location`: "root" | "subproject"
3. Check for `command` override
4. Check for context-specific `overrides`

**Example:**

- rubocop: Always run from repo root
- rspec in ruby/: Use `bundle exec rspec`
- rspec in root project: Use `bin/rspec`

## Common Mistakes to Prevent

❌ **"I just used cd, so I'm in the right directory"**
Reality: You cannot track shell state reliably. Always use absolute paths.

❌ **"The shell remembers where I am"**
Reality: Shell state is not guaranteed between commands. Always use absolute paths.

❌ **"It's wasteful to cd every time"**
Reality: Explicitness prevents bugs. Always use absolute paths.

❌ **"Relative paths are simpler"**
Reality: They break when assumptions are wrong. Always use absolute paths.

## Quick Reference

| Task                    | Command Pattern                                                                             |
| ----------------------- | ------------------------------------------------------------------------------------------- |
| Run tests in subproject | `cd $(git rev-parse --show-toplevel)/subproject && test-command`                            |
| With config             | `cd {root}/{subproject.path} && command`                                                    |
| Check for config        | `test -f .monorepo.json`                                                                    |
| Generate config         | `~/.claude/skills/working-in-monorepos/scripts/monorepo-init --dry-run` then with `--write` |
| Always rule             | Use absolute path + cd prefix for EVERY command                                             |

## Configuration Schema

`.monorepo.json` at repository root:

```json
{
  "root": "/absolute/path/to/repo",
  "subprojects": {
    "subproject-id": {
      "path": "relative/path",
      "type": "ruby|node|go|python|rust|java",
      "description": "Optional"
    }
  },
  "commands": {
    "command-name": {
      "location": "root|subproject",
      "command": "optional override",
      "overrides": {
        "context": { "command": "context-specific" }
      }
    }
  }
}
```

**Minimal example:**

```json
{
  "root": "/Users/josh/workspace/schemaflow",
  "subprojects": {
    "ruby": { "path": "ruby", "type": "ruby" },
    "cli": { "path": "cli", "type": "node" }
  }
}
```
