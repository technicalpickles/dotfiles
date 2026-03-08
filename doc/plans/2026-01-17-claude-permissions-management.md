# Claude Code Permissions Management Plan

## Goal

Create a systematic approach to managing Claude Code permissions across:

- Global settings (`~/.claude/settings.json`)
- Project-local settings (`<project>/.claude/settings.local.json`)
- Dotfiles-managed base configs (`claude/permissions.json`, `claude/permissions.*.json`)

## Current State

### Discovery (2025-01-17)

- **1,743 total permission entries** across workspace projects
- **Zero denies, zero asks configured** - everything either allowed or prompts fresh
- **Permission locations:**
  - Global: `~/.claude/settings.json` (13 allows)
  - Per-project: `~/workspace/*/.claude/settings.local.json` (46 projects found)
  - Dotfiles templates: `~/workspace/dotfiles/claude/permissions*.json`

### Categorization Results

| Category      | Count | Risk Level |
| ------------- | ----- | ---------- |
| Read-only     | 217   | Safe       |
| Dev-safe      | 287   | Low        |
| Remote-write  | 84    | Medium     |
| Skills        | 58    | Low        |
| MCP tools     | 20    | Variable   |
| Dangerous     | 5     | High       |
| Uncategorized | 604   | Unknown    |

## Plan

### Phase 1: Query Tool ✅

Create `bin/claude-permissions` script that:

- [x] Finds all settings files deterministically
- [x] Extracts and aggregates permissions
- [x] Outputs in multiple formats for agent analysis:
  - `--json` - structured data for agents/scripts
  - `--aggregate` - deduplicated list with counts
  - `--raw` - permissions by source file
  - `--locations` - file paths only
  - (default) - human-readable summary

### Phase 2: Define Permission Tiers

#### Tier 1: Global Allow (safe everywhere)

Read-only operations that cannot cause harm:

```
# Git read operations
Bash(git status:*)
Bash(git log:*)
Bash(git show:*)
Bash(git diff:*)
Bash(git branch:*)
Bash(git rev-parse:*)
Bash(git check-ignore:*)
Bash(git remote:*)
Bash(git fetch:*)

# GitHub CLI read operations
Bash(gh pr view:*)
Bash(gh pr list:*)
Bash(gh pr diff:*)
Bash(gh pr checks:*)
Bash(gh issue list:*)
Bash(gh issue view:*)
Bash(gh api:*)
Bash(gh repo view:*)
Bash(gh run list:*)
Bash(gh run view:*)

# File system read operations
Bash(ls:*)
Bash(cat:*)
Bash(tree:*)
Bash(find:*)
Bash(fd:*)
Bash(grep:*)
Bash(head:*)
Bash(tail:*)
Bash(wc:*)

# Tool discovery
Bash(which:*)
Bash(command -v:*)
Bash(type:*)

# MCP read operations
mcp__MCPProxy__retrieve_tools
mcp__MCPProxy__call_tool_read

# Web fetch for docs
WebFetch(domain:github.com)
WebFetch(domain:code.claude.com)
WebFetch(domain:docs.github.com)
WebFetch(domain:raw.githubusercontent.com)
```

#### Tier 2: Global Allow (dev-safe)

Common development operations, low risk:

```
# Git local modifications
Bash(git add:*)
Bash(git commit:*)
Bash(git checkout:*)
Bash(git switch:*)
Bash(git stash:*)
Bash(git restore:*)
Bash(git worktree:*)

# File operations
Bash(mkdir:*)
Bash(chmod:*)
Bash(touch:*)

# Package managers (install only)
Bash(bundle install)
Bash(npm install)
Bash(yarn install)
Bash(pip install:*)

# Testing
Bash(bundle exec rspec:*)
Bash(bin/rspec:*)
Bash(npm test)
Bash(pytest:*)

# Linting
Bash(bundle exec rubocop:*)
Bash(bin/rubocop:*)
Bash(prettier:*)
Bash(eslint:*)
Bash(shellcheck:*)
```

#### Tier 3: Ask Every Time (remote-write)

Operations that affect remote state:

```
Bash(git push:*)
Bash(git pull:*)
Bash(git merge:*)
Bash(git rebase:*)
Bash(gh pr create:*)
Bash(gh pr edit:*)
Bash(gh pr merge:*)
Bash(gh issue create:*)
mcp__MCPProxy__call_tool_write
```

#### Tier 4: Deny (dangerous)

Operations that should never be auto-approved:

```
Bash(sudo:*)
Bash(rm -rf:*)
Bash(git push --force:*)
Bash(git push -f:*)
Bash(git reset --hard:*)
Bash(git clean -fd:*)
Bash(curl * | bash)
Bash(curl * | sh)
mcp__MCPProxy__call_tool_destructive
```

### Phase 3: Update Dotfiles Config

1. Update `claude/permissions.json` with Tier 1 + Tier 2 allows
2. Add `deny` list with Tier 4 patterns
3. Consider adding `askEveryTime` for Tier 3 (if Claude supports it)
4. Regenerate with `./claudeconfig.sh`

### Phase 4: Project Cleanup

1. Audit each project's `settings.local.json`
2. Remove permissions now covered by global config
3. Keep only project-specific permissions (custom scripts, project tools)

### Phase 5: Ongoing Maintenance

1. Run `bin/claude-permissions --recommendations` periodically
2. Review uncategorized permissions and update categorization rules
3. Consider adding new patterns to global config when they appear frequently

## Open Questions

1. Does Claude Code support `askEveryTime` list separate from `deny`?
2. Can we use glob patterns in permissions (e.g., `Bash(git *:*)`)?
3. Should we track permission grants in git history for auditing?

## Scripts

- `bin/claude-permissions` - Query permissions (use `--json` for agent prompts)
