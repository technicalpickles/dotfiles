# Claude Skills Plugin Extraction Design

**Date:** 2025-11-12
**Status:** Design Complete, Ready for Implementation

## Overview

Extract Claude Code skills from the dotfiles repository into a standalone plugin repository (`technicalpickles`). This creates a clean separation of concerns while maintaining automated installation through dotfiles, enabling easier sharing and maintenance of skills across machines.

## Goals

- **Clean separation**: Dotfiles focuses on shell/system config; skills live in their own versioned repository
- **Easy maintenance**: Update skills in one place, sync across all machines via git
- **Discoverability**: Others can find and use the skills via public GitHub repository
- **Automated installation**: Dotfiles install.sh handles plugin setup automatically

## Non-Goals

- Building marketplace infrastructure beyond a GitHub repository
- Accepting contributions from multiple authors (initially)
- Official Claude Code marketplace submission (future possibility)

## Architecture

### Repository Structure

New repository: `github.com/technicalpickles/claude-skills`

```
claude-skills/
├── .claude-plugin/
│   ├── plugin.json          # Plugin metadata
│   └── marketplace.json     # Marketplace definition
├── skills/
│   ├── buildkite-status/    # Complex skill with subdirectories
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   └── references/
│   ├── scope/
│   ├── working-in-monorepos/
│   ├── working-in-scratch-areas/
│   ├── gh-pr.md             # Simple single-file skill
│   └── git-preferences-and-practices/
├── README.md
├── LICENSE
└── .gitignore
```

**Design decisions:**

- YAGNI: No `commands/`, `agents/`, or `hooks/` directories initially - add when needed
- Preserve existing skill structure: complex skills keep their subdirectories
- Simple skills go directly in `skills/` directory
- Standard open source repository layout

### Dotfiles Integration

**Directory layout on machine:**

```
~/workspace/
├── dotfiles/                 # Existing dotfiles repo
└── claude-skills/            # Plugin repo (auto-cloned by install.sh)

~/.claude/
└── plugins/
    └── technicalpickles -> ~/workspace/claude-skills/  # Symlink
```

**Integration approach:**

- Plugin repo cloned to `~/workspace/claude-skills/` during dotfiles installation
- Symlinked to `~/.claude/plugins/technicalpickles` for Claude Code discovery
- Dotfiles install.sh manages both clone and symlink automatically
- If plugin already exists, installation skips clone (idempotent)

**New function in install.sh:**

```bash
setup_claude_plugin() {
  local plugin_name="claude-skills"
  local plugin_repo="https://github.com/technicalpickles/claude-skills"
  local workspace_dir="${HOME}/workspace"
  local plugin_path="${workspace_dir}/${plugin_name}"
  local claude_plugins_dir="${HOME}/.claude/plugins"

  # Ensure workspace directory exists
  mkdir -p "${workspace_dir}"

  # Clone if not present
  if [ ! -d "${plugin_path}" ]; then
    echo "Cloning ${plugin_name} plugin..."
    git clone "${plugin_repo}" "${plugin_path}"
  fi

  # Create symlink
  mkdir -p "${claude_plugins_dir}"
  ln -sf "${plugin_path}" "${claude_plugins_dir}/technicalpickles"

  echo "✓ Claude plugin installed: technicalpickles"
}
```

### Plugin Metadata

**`.claude-plugin/plugin.json`:**

```json
{
  "name": "technicalpickles",
  "description": "Personal collection of Claude Code skills: Buildkite workflows, monorepo helpers, Git practices, and development tools",
  "version": "1.0.0",
  "author": {
    "name": "Josh Nichols",
    "email": "josh@technicalpickles.com"
  },
  "homepage": "https://github.com/technicalpickles/claude-skills",
  "repository": "https://github.com/technicalpickles/claude-skills",
  "license": "MIT",
  "keywords": ["buildkite", "monorepo", "git", "workflow", "development"]
}
```

**`.claude-plugin/marketplace.json`:**

```json
{
  "name": "technicalpickles-marketplace",
  "description": "Personal skills marketplace for Josh Nichols",
  "owner": {
    "name": "Josh Nichols",
    "email": "josh@technicalpickles.com"
  },
  "plugins": [
    {
      "name": "technicalpickles",
      "description": "Personal collection of Claude Code skills",
      "version": "1.0.0",
      "source": "./",
      "author": {
        "name": "Josh Nichols",
        "email": "josh@technicalpickles.com"
      }
    }
  ]
}
```

## Skill Access & Usage

### After Migration

**Plugin-based access (primary):**

- Skills discovered from `~/.claude/plugins/technicalpickles/skills/`
- Referenced as `technicalpickles:buildkite-status`, `technicalpickles:scope`, etc.
- Claude Code reads directly from plugin
- Updates via `git pull` in `~/workspace/claude-skills/`

**For other users:**

1. **Via dotfiles**: Clone both repos, run install.sh (fully automated)
2. **Manual installation**: `git clone https://github.com/technicalpickles/claude-skills ~/.claude/plugins/technicalpickles`
3. **Future possibility**: Native Claude Code plugin installation if added to official marketplace

### Development Workflow

1. Edit skills in `~/workspace/claude-skills/`
2. Changes immediately available (symlink is live)
3. Commit and push to share
4. Pull on other machines to sync

## Migration Plan

### Phase 1: Create Plugin Repository

1. Create new repo: `github.com/technicalpickles/claude-skills`
2. Set up plugin structure:
   - Create `.claude-plugin/plugin.json`
   - Create `.claude-plugin/marketplace.json`
   - Create `skills/` directory
3. Copy all skills from `dotfiles/home/.claude/skills/` to `claude-skills/skills/`
4. Write README.md with installation instructions
5. Add LICENSE (MIT)
6. Create `.gitignore`
7. Commit and push

### Phase 2: Update Dotfiles

1. Add `setup_claude_plugin()` function to `install.sh`
2. Call function during installation process
3. Test on local machine: verify plugin clones and symlinks correctly
4. **Keep old `home/.claude/skills/` symlinks temporarily for safety**

### Phase 3: Validation

1. Verify skills load: Check that Claude can see `technicalpickles:*` skills
2. Test several skills to ensure they work from plugin location
3. Test on second machine: Confirm `install.sh` auto-clones plugin
4. Verify backward compatibility: Old skill names still work via existing symlinks

### Phase 4: Cleanup

1. Remove `home/.claude/skills/` directory from dotfiles
2. Remove skill symlink creation from `symlinks.sh`
3. Update dotfiles README to mention plugin
4. Commit final cleanup to dotfiles
5. Remove old symlinks from `~/.claude/skills/` on all machines

### Rollback Safety

- Old symlinks stay until Phase 4 - skills continue working during migration
- Plugin and dotfiles are separate repos - can revert independently
- Can re-clone plugin if issues occur
- Git history preserves all changes

## Documentation

### Plugin README.md

Should include:

1. **Overview**: Description of skills collection
2. **Installation**:
   - For technicalpickles dotfiles users: Automatic
   - For others: Manual clone instructions
3. **Skills Catalog**: List of included skills with descriptions
4. **Usage**: How to invoke skills (Skill tool, namespacing)
5. **Contributing**: Personal collection, accepting improvements
6. **License**: MIT

### Dotfiles README.md Updates

Add section:

- Claude Code plugin managed separately
- Link to plugin repository
- Note that skills extracted to separate repo
- Installation handled automatically by install.sh

## Sharing & Discovery

**Distribution strategy:**

- Public GitHub repository with comprehensive README
- Topics/tags: `claude-code`, `claude-skills`, `buildkite`, `monorepo`
- GitHub profile showcases the plugin
- GitHub IS the marketplace - no special infrastructure needed
- Future: Consider official Claude marketplace submission when available

**Version management:**

- Start at `1.0.0` upon extraction
- Minor version bumps for new skills (1.1.0, 1.2.0)
- Patch version for fixes (1.0.1, 1.0.2)
- No breaking changes expected (skills are independent)

## Skills to Migrate

All current skills will be migrated:

- `buildkite-status/` - Buildkite CI/CD workflow helpers (work-specific but generalizable)
- `scope/` - Scope environment management tool helpers
- `working-in-monorepos/` - Monorepo navigation and command helpers
- `working-in-scratch-areas/` - Scratch area management for temporary work
- `gh-pr.md` - GitHub pull request workflows
- `git-preferences-and-practices/` - Personal Git workflow preferences
- `mcpproxy-debug/` - MCPProxy debugging helpers

## Success Criteria

- ✅ Skills repository is separate from dotfiles
- ✅ Dotfiles install.sh automatically sets up plugin
- ✅ Skills accessible to Claude Code on all machines
- ✅ Other users can discover and install the plugin
- ✅ Single source of truth for skill updates
- ✅ Clean separation of concerns (dotfiles vs Claude config)

## Future Enhancements

- Submit to official Claude Code marketplace (when available)
- Add slash commands if needed
- Add custom agents if needed
- Accept community contributions (PRs)
- Create additional plugins for different skill categories
- Add automated testing for skills
