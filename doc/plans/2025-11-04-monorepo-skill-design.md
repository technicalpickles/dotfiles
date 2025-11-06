# Monorepo Skill Design

## Overview

A skill to help Claude work effectively in monorepo environments by maintaining directory context awareness and ensuring commands execute from the correct locations using absolute paths.

## Problem Statement

When working in repositories with multiple subprojects (monorepos), Claude frequently:

- Loses track of which directory it's in
- Uses redundant `cd` commands (e.g., `cd ruby && cd ruby && rspec`)
- Assumes current directory without verification
- Fails to run commands from the correct location

**Root cause:** Bash shell state is not guaranteed between command invocations. Claude cannot reliably know the current working directory.

## Solution: Skill + Init Script Pattern

### Architecture

**Skill:** `home/.claude/skills/working-in-monorepos/SKILL.md`

- Enforces methodology: Always use absolute paths with explicit cd
- Provides setup workflow for config generation
- Works with or without configuration

**Init Script:** `bin/monorepo-init`

- Auto-detects subprojects via package manager artifacts
- Generates `.monorepo.json` configuration
- Implemented in bash using `fd` and `jq`

**Config File:** `.monorepo.json` at repo root

- Single source of truth for subproject locations
- Optional command execution rules
- User-customizable

### Why This Architecture

1. **Testable:** Clear rule to verify/violate ("always use absolute paths")
2. **Minimal skill size:** Methodology separate from detection logic
3. **Reusable tooling:** Init script works outside Claude sessions
4. **Flexible:** Works with or without config file

## Skill Structure

### Frontmatter

```yaml
---
name: working-in-monorepos
description: Use when working in repositories with multiple subprojects (monorepos) where commands need to run from specific directories - prevents directory confusion, redundant cd commands, and ensures commands execute from correct locations
---
```

### Core Rule: Always Use Absolute Paths

**Correct:**

```bash
cd /Users/josh/workspace/schemaflow/ruby && bundle exec rspec
cd /Users/josh/workspace/schemaflow/cli && npm test
```

**Wrong:**

```bash
cd ruby && bundle exec rspec # Relative path
bundle exec rspec            # No cd
cd ruby && cd ruby && rspec  # Chaining cd
```

### Subproject Context Awareness

Before executing commands:

1. Identify target subproject
2. Check `.monorepo.json` for command rules (if exists)
3. Construct absolute path: `root` + subproject `path`
4. Use explicit cd prefix

### Setup Workflow (No Config)

When skill activates without `.monorepo.json`:

1. Announce detection of monorepo without config
2. Offer to run `bin/monorepo-init` for auto-detection
3. User options:
   - Accept: Run script, review, approve before writing
   - Decline: Continue without config (use git to find root)
   - Customize: Manual config creation

### Command Execution Rules (With Config)

If `.monorepo.json` defines command rules:

- Check `location` field: "root" | "subproject"
- Check for `command` override
- Check for `overrides` for specific contexts

**Example:** rubocop always from root, rspec from subproject except root project uses `bin/rspec`

## Configuration Schema

### File Location

`.monorepo.json` at repository root

### Schema

```json
{
  "root": "/absolute/path/to/repo",
  "subprojects": {
    "subproject-id": {
      "path": "relative/path",
      "type": "ruby|node|go|python|rust|java",
      "description": "Optional human description"
    }
  },
  "commands": {
    "command-name": {
      "location": "root|subproject|either",
      "command": "optional override",
      "overrides": {
        "context": {
          "command": "context-specific command"
        }
      }
    }
  }
}
```

### Minimal Example (schemaflow)

```json
{
  "root": "/Users/josh/workspace/schemaflow",
  "subprojects": {
    "ruby": { "path": "ruby", "type": "ruby" },
    "cli": { "path": "cli", "type": "node" }
  }
}
```

### Complex Example (zenpayroll)

```json
{
  "root": "/Users/josh/workspace/zenpayroll",
  "subprojects": {
    "root": { "path": ".", "type": "ruby" },
    "gusto-deprecation": {
      "path": "components/gusto-deprecation",
      "type": "ruby"
    }
  },
  "commands": {
    "rubocop": {
      "location": "root"
    },
    "rspec": {
      "location": "subproject",
      "command": "bundle exec rspec",
      "overrides": {
        "root": {
          "command": "bin/rspec"
        }
      }
    }
  }
}
```

## Init Script Design

### Purpose

Auto-detect subprojects and generate `.monorepo.json`

### Detection Heuristics

Scan for package manager artifacts:

- `package.json` (Node/npm)
- `Gemfile` (Ruby/bundler)
- `go.mod` (Go)
- `pyproject.toml`, `setup.py`, `requirements.txt` (Python)
- `Cargo.toml` (Rust)
- `build.gradle`, `pom.xml` (Java)

### Script Behavior

1. Find repo root: `git rev-parse --show-toplevel`
2. Scan for artifacts using `fd`
3. Group by directory (directories with artifacts = subprojects)
4. Detect type based on artifact
5. Generate JSON structure
6. Output to stdout or write to file

### Usage

```bash
# Preview detection
bin/monorepo-init --dry-run

# Generate and write
bin/monorepo-init --write

# Output to stdout (for editing)
bin/monorepo-init
```

### Implementation

- Language: Bash
- Dependencies: `fd`, `jq`, `git` (already in Brewfile)

## Rationalizations to Prevent

The skill must explicitly counter these rationalizations:

- "I just used cd, so I'm already in the right directory"
- "The shell remembers where I am"
- "It's wasteful to cd every time"
- "I can track directory state mentally"
- "Relative paths are simpler"

## Testing Strategy (TDD for Skills)

### RED Phase: Baseline Testing

Run scenarios WITHOUT skill, document failures:

**Pressure scenario:**

```
You're working in ~/workspace/schemaflow/ruby.
You just ran: cd ruby && bundle install
Now run rspec.

What command do you execute?
```

Expected baseline failures:

- `cd ruby && bundle exec rspec` (compounds cd)
- `bundle exec rspec` (assumes location)
- `cd ruby && rspec` (still wrong, compounded)

### GREEN Phase: Write Skill

Write skill addressing baseline failures.
Re-test scenarios - agent should now use absolute paths.

### REFACTOR Phase: Close Loopholes

Identify new rationalizations, add explicit counters:

- "But I know where I am" → Add to rationalization table
- "Absolute paths are verbose" → Explain why consistency matters
- "I can use $PWD" → Explain why that still depends on state

## File Structure

```
home/.claude/skills/working-in-monorepos/
  SKILL.md                 # Main skill document
bin/
  monorepo-init            # Detection and config generation script
```

The skill directory gets symlinked via existing dotfiles infrastructure:
`home/.claude/skills/` → `~/.claude/skills/`

## Success Criteria

**Skill is successful when:**

1. Claude consistently uses absolute paths for all commands
2. Claude offers config generation when entering new monorepos
3. Claude respects command execution rules from config
4. No more `cd ruby && cd ruby` errors
5. Commands execute from correct locations under pressure

## Implementation Plan (Next Steps)

Following the writing-skills methodology:

1. Create RED phase test scenarios
2. Run baseline tests (without skill)
3. Write minimal skill addressing failures
4. Run GREEN phase tests (with skill)
5. Implement init script
6. REFACTOR phase: close loopholes
7. Commit skill and script to dotfiles repo
