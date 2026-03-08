# Claude Skills Plugin Extraction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extract Claude Code skills from dotfiles repository into a standalone plugin repository with automated installation.

**Architecture:** Create new `technicalpickles` plugin repository following Claude Code plugin structure, copy all skills from dotfiles, update dotfiles install.sh to auto-clone and symlink the plugin, validate on multiple machines, then clean up old skill symlinks.

**Tech Stack:** Git, Bash, JSON, Markdown, Claude Code plugin system

---

## Prerequisites

- Current working directory: `/Users/josh.nichols/workspace/dotfiles`
- Skills currently at: `home/.claude/skills/`
- Target workspace: `~/workspace/`
- Plugin will be created at: `~/workspace/claude-skills/`

---

## Phase 1: Create Plugin Repository

### Task 1: Create Plugin Repository Structure

**Files:**

- Create: `~/workspace/claude-skills/` (new directory)
- Create: `~/workspace/claude-skills/.claude-plugin/`
- Create: `~/workspace/claude-skills/skills/`

**Step 1: Create directory structure**

```bash
cd ~/workspace
mkdir -p claude-skills/.claude-plugin
mkdir -p claude-skills/skills
```

**Step 2: Verify structure created**

Run: `ls -la ~/workspace/claude-skills/`
Expected: `.claude-plugin/` and `skills/` directories exist

**Step 3: Initialize git repository**

```bash
cd ~/workspace/claude-skills
git init
```

**Step 4: Verify git initialized**

Run: `git status`
Expected: "On branch main" or "On branch master", "No commits yet"

---

### Task 2: Create Plugin Metadata

**Files:**

- Create: `~/workspace/claude-skills/.claude-plugin/plugin.json`
- Create: `~/workspace/claude-skills/.claude-plugin/marketplace.json`

**Step 1: Create plugin.json**

File: `~/workspace/claude-skills/.claude-plugin/plugin.json`

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

**Step 2: Create marketplace.json**

File: `~/workspace/claude-skills/.claude-plugin/marketplace.json`

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

**Step 3: Verify JSON files are valid**

Run: `cat ~/workspace/claude-skills/.claude-plugin/plugin.json | jq .`
Expected: Formatted JSON output without errors

Run: `cat ~/workspace/claude-skills/.claude-plugin/marketplace.json | jq .`
Expected: Formatted JSON output without errors

**Step 4: Commit metadata files**

```bash
cd ~/workspace/claude-skills
git add .claude-plugin/
git commit -m "feat: add plugin metadata files"
```

---

### Task 3: Copy Skills from Dotfiles

**Files:**

- Source: `/Users/josh.nichols/workspace/dotfiles/home/.claude/skills/*`
- Destination: `~/workspace/claude-skills/skills/`

**Step 1: Copy all skills to plugin**

```bash
cd ~/workspace/dotfiles
cp -r home/.claude/skills/* ~/workspace/claude-skills/skills/
```

**Step 2: Verify skills copied**

Run: `ls -la ~/workspace/claude-skills/skills/`
Expected: All skills directories present (buildkite-status, scope, working-in-monorepos, working-in-scratch-areas, gh-pr.md, git-preferences-and-practices, mcpproxy-debug)

**Step 3: Remove symlinks if any were copied**

```bash
cd ~/workspace/claude-skills/skills
# Remove any accidentally copied symlinks
find . -type l -delete
```

**Step 4: Verify all skills are regular files/directories**

Run: `find ~/workspace/claude-skills/skills -type l`
Expected: No output (no symlinks found)

**Step 5: Commit skills**

```bash
cd ~/workspace/claude-skills
git add skills/
git commit -m "feat: add all skills from dotfiles

Includes:
- buildkite-status: Buildkite CI/CD workflow helpers
- scope: Scope environment management helpers
- working-in-monorepos: Monorepo navigation helpers
- working-in-scratch-areas: Scratch area management
- gh-pr.md: GitHub pull request workflows
- git-preferences-and-practices: Git workflow preferences
- mcpproxy-debug: MCPProxy debugging helpers"
```

---

### Task 4: Create README and Supporting Files

**Files:**

- Create: `~/workspace/claude-skills/README.md`
- Create: `~/workspace/claude-skills/LICENSE`
- Create: `~/workspace/claude-skills/.gitignore`

**Step 1: Create README.md**

File: `~/workspace/claude-skills/README.md`

````markdown
# technicalpickles Claude Skills

Personal collection of Claude Code skills for development workflows, CI/CD, and productivity.

## Installation

### Automatic (via technicalpickles/dotfiles)

If you use [technicalpickles/dotfiles](https://github.com/technicalpickles/dotfiles), the plugin is installed automatically via `install.sh`.

### Manual Installation

```bash
git clone https://github.com/technicalpickles/claude-skills ~/.claude/plugins/technicalpickles
```
````

## Skills Included

### General Development

- **working-in-monorepos**: Navigate and execute commands in monorepo subprojects with proper directory handling
- **working-in-scratch-areas**: Manage temporary work in persistent `.scratch` areas with organization patterns
- **git-preferences-and-practices**: Personal Git workflow preferences and best practices

### CI/CD & Infrastructure

- **buildkite-status**: Buildkite CI/CD workflow helpers for checking build status and debugging failures
- **scope**: Scope environment management tool helpers for debugging and configuration
- **mcpproxy-debug**: MCPProxy debugging and configuration helpers

### GitHub Workflows

- **gh-pr**: GitHub pull request creation and management workflows

## Usage

Skills are available in Claude Code via the Skill tool:

```
Use the technicalpickles:working-in-monorepos skill
```

Or reference them in custom skills:

```markdown
@technicalpickles:buildkite-status for checking CI status
```

## Development

To modify skills:

1. Edit files in `~/workspace/claude-skills/skills/`
2. Changes are immediately available to Claude (if installed via symlink)
3. Commit and push to share across machines

## Version History

- **1.0.0** (2025-11-12): Initial release with all personal skills

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

Josh Nichols ([@technicalpickles](https://github.com/technicalpickles))

```

**Step 2: Create LICENSE**

File: `~/workspace/claude-skills/LICENSE`

```

MIT License

Copyright (c) 2025 Josh Nichols

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

**Step 3: Create .gitignore**

File: `~/workspace/claude-skills/.gitignore`

```

# macOS

.DS_Store

# Editor directories

.vscode/
.idea/

# Temporary files

_.swp
_.swo
\*~

````

**Step 4: Commit supporting files**

```bash
cd ~/workspace/claude-skills
git add README.md LICENSE .gitignore
git commit -m "docs: add README, LICENSE, and gitignore"
````

---

### Task 5: Create GitHub Repository and Push

**Files:**

- Remote repository: `github.com/technicalpickles/claude-skills`

**Step 1: Create GitHub repository**

Run: `gh repo create technicalpickles/claude-skills --public --source=. --remote=origin --description="Personal collection of Claude Code skills for development workflows"`
Expected: "✓ Created repository technicalpickles/claude-skills on GitHub"

**Step 2: Push to GitHub**

```bash
cd ~/workspace/claude-skills
git push -u origin main
```

**Step 3: Verify push succeeded**

Run: `gh repo view technicalpickles/claude-skills --web`
Expected: Browser opens to GitHub repository showing all committed files

**Step 4: Add repository topics**

```bash
gh repo edit technicalpickles/claude-skills --add-topic claude-code --add-topic claude-skills --add-topic buildkite --add-topic monorepo --add-topic workflow
```

---

## Phase 2: Update Dotfiles

### Task 6: Add Plugin Setup Function to install.sh

**Files:**

- Modify: `/Users/josh.nichols/workspace/dotfiles/install.sh`

**Step 1: Read current install.sh to find insertion point**

Read: `/Users/josh.nichols/workspace/dotfiles/install.sh`
Location: Find where functions are defined (likely near the top, after sourcing functions.sh)

**Step 2: Add setup_claude_plugin function**

Add this function to `/Users/josh.nichols/workspace/dotfiles/install.sh` after other function definitions:

```bash
setup_claude_plugin() {
  local plugin_name="claude-skills"
  local plugin_repo="https://github.com/technicalpickles/claude-skills"
  local workspace_dir="${HOME}/workspace"
  local plugin_path="${workspace_dir}/${plugin_name}"
  local claude_plugins_dir="${HOME}/.claude/plugins"

  echo "Setting up Claude Code plugin..."

  # Ensure workspace directory exists
  if [ ! -d "${workspace_dir}" ]; then
    echo "Creating workspace directory: ${workspace_dir}"
    mkdir -p "${workspace_dir}"
  fi

  # Clone if not present
  if [ ! -d "${plugin_path}" ]; then
    echo "Cloning ${plugin_name} plugin..."
    if git clone "${plugin_repo}" "${plugin_path}"; then
      echo "✓ Plugin cloned successfully"
    else
      echo "✗ Failed to clone plugin repository"
      return 1
    fi
  else
    echo "Plugin already exists at ${plugin_path}"
    # Optionally pull latest changes
    echo "Pulling latest changes..."
    cd "${plugin_path}"
    git pull
    cd - > /dev/null
  fi

  # Create symlink
  mkdir -p "${claude_plugins_dir}"
  if [ -L "${claude_plugins_dir}/technicalpickles" ]; then
    echo "Symlink already exists"
  elif [ -e "${claude_plugins_dir}/technicalpickles" ]; then
    echo "Warning: ${claude_plugins_dir}/technicalpickles exists but is not a symlink"
    echo "Please remove it manually and run install.sh again"
    return 1
  else
    ln -sf "${plugin_path}" "${claude_plugins_dir}/technicalpickles"
    echo "✓ Created symlink to plugin"
  fi

  echo "✓ Claude plugin installed: technicalpickles"
}
```

**Step 3: Call setup_claude_plugin in main install flow**

Find the main execution section of install.sh (usually near the bottom) and add the call. Location depends on where other setup functions are called, but typically after git submodule init and before symlinks:

```bash
# Add this line in the appropriate place in install.sh
setup_claude_plugin
```

**Step 4: Verify syntax**

Run: `bash -n /Users/josh.nichols/workspace/dotfiles/install.sh`
Expected: No output (syntax is valid)

**Step 5: Commit changes to install.sh**

```bash
cd /Users/josh.nichols/workspace/dotfiles
git add install.sh
git commit -m "feat: add Claude plugin auto-installation

Automatically clones and symlinks technicalpickles/claude-skills
plugin during dotfiles installation"
```

---

## Phase 3: Validation

### Task 7: Test Plugin Installation on Local Machine

**Files:**

- Test location: `~/.claude/plugins/technicalpickles`

**Step 1: Remove existing plugin if present (for clean test)**

```bash
# Back up existing symlink if any
if [ -L ~/.claude/plugins/technicalpickles ]; then
  mv ~/.claude/plugins/technicalpickles ~/.claude/plugins/technicalpickles.backup
fi
```

**Step 2: Run dotfiles install.sh**

```bash
cd /Users/josh.nichols/workspace/dotfiles
bash install.sh
```

Expected: Should see "Setting up Claude Code plugin..." and "✓ Claude plugin installed: technicalpickles"

**Step 3: Verify plugin symlink exists**

Run: `ls -la ~/.claude/plugins/technicalpickles`
Expected: Symlink pointing to `~/workspace/claude-skills`

**Step 4: Verify skills are accessible**

Run: `ls ~/.claude/plugins/technicalpickles/skills/`
Expected: All skills directories listed

**Step 5: Test in Claude Code**

Open Claude Code and ask: "List available skills from the technicalpickles plugin"
Expected: Claude should list skills with `technicalpickles:` prefix

---

### Task 8: Document Skills in Dotfiles README

**Files:**

- Modify: `/Users/josh.nichols/workspace/dotfiles/CLAUDE.md`

**Step 1: Add section about Claude Code plugin**

Add this section to `/Users/josh.nichols/workspace/dotfiles/CLAUDE.md` after the "Custom Binaries" section:

```markdown
## Claude Code Skills Plugin

Personal Claude Code skills are maintained in a separate plugin repository: [technicalpickles/claude-skills](https://github.com/technicalpickles/claude-skills).

**Installation:** Automatic via `install.sh` - the plugin is cloned to `~/workspace/claude-skills/` and symlinked to `~/.claude/plugins/technicalpickles`.

**Skills included:**

- `technicalpickles:buildkite-status` - Buildkite CI/CD workflow helpers
- `technicalpickles:scope` - Scope environment management helpers
- `technicalpickles:working-in-monorepos` - Monorepo navigation helpers
- `technicalpickles:working-in-scratch-areas` - Scratch area management
- `technicalpickles:gh-pr` - GitHub pull request workflows
- `technicalpickles:git-preferences-and-practices` - Git workflow preferences
- `technicalpickles:mcpproxy-debug` - MCPProxy debugging helpers

**Development:** Skills are edited in `~/workspace/claude-skills/skills/` and changes are immediately available via the symlink.
```

**Step 2: Commit CLAUDE.md update**

```bash
cd /Users/josh.nichols/workspace/dotfiles
git add CLAUDE.md
git commit -m "docs: document Claude skills plugin"
```

---

### Task 9: Validate on Second Machine (Manual Step)

**Note:** This task requires access to a second machine or clean environment.

**Step 1: On second machine, clone dotfiles**

```bash
# On second machine
git clone https://github.com/technicalpickles/dotfiles ~/.pickles
```

**Step 2: Run install.sh**

```bash
cd ~/.pickles
bash install.sh
```

Expected: Should see plugin being cloned and symlinked automatically

**Step 3: Verify plugin is functional**

Run: `ls -la ~/.claude/plugins/technicalpickles/skills/`
Expected: All skills present

**Step 4: Test in Claude Code**

Open Claude Code and verify skills are available with `technicalpickles:` prefix

---

## Phase 4: Cleanup

### Task 10: Remove Old Skills from Dotfiles

**Files:**

- Remove: `/Users/josh.nichols/workspace/dotfiles/home/.claude/skills/` (entire directory)

**Step 1: Verify plugin is working before cleanup**

Run: `ls ~/.claude/plugins/technicalpickles/skills/`
Expected: All skills present and accessible

**Step 2: Remove skills directory from dotfiles**

```bash
cd /Users/josh.nichols/workspace/dotfiles
rm -rf home/.claude/skills/
```

**Step 3: Verify removal**

Run: `ls /Users/josh.nichols/workspace/dotfiles/home/.claude/`
Expected: No `skills/` directory

**Step 4: Check git status**

Run: `git status`
Expected: Shows `home/.claude/skills/` as deleted

**Step 5: Commit removal**

```bash
cd /Users/josh.nichols/workspace/dotfiles
git add -A
git commit -m "refactor: remove skills directory (moved to plugin)

Skills are now maintained in separate plugin repository:
https://github.com/technicalpickles/claude-skills"
```

---

### Task 11: Update symlinks.sh if Needed

**Files:**

- Possibly modify: `/Users/josh.nichols/workspace/dotfiles/symlinks.sh`

**Step 1: Check if symlinks.sh creates skill symlinks**

```bash
cd /Users/josh.nichols/workspace/dotfiles
grep -n "\.claude/skills" symlinks.sh
```

Expected: May show lines that symlink skills (or may be empty if skills were symlinked elsewhere)

**Step 2: If skills are referenced, remove those lines**

If grep found references to skills, edit `symlinks.sh` to remove the skill symlinking logic (specific lines depend on current implementation).

**Step 3: Verify syntax**

Run: `bash -n /Users/josh.nichols/workspace/dotfiles/symlinks.sh`
Expected: No output (syntax is valid)

**Step 4: Commit changes if any**

```bash
cd /Users/josh.nichols/workspace/dotfiles
git add symlinks.sh
git commit -m "refactor: remove skill symlinking (handled by plugin)"
```

**Step 5: If no changes needed, skip commit**

If grep found nothing, no changes needed - skills were not managed by symlinks.sh.

---

### Task 12: Remove Old Symlinks from ~/.claude/skills/

**Files:**

- Remove: `~/.claude/skills/*` (all skill symlinks)

**Step 1: List current skill symlinks**

Run: `ls -la ~/.claude/skills/`
Expected: List of symlinks to dotfiles skills (if any remain)

**Step 2: Remove old skills directory**

```bash
rm -rf ~/.claude/skills/
```

**Step 3: Verify removal**

Run: `ls ~/.claude/skills/`
Expected: "No such file or directory"

**Step 4: Verify plugin still works**

Run: `ls ~/.claude/plugins/technicalpickles/skills/`
Expected: All skills present and accessible

---

### Task 13: Push All Changes

**Files:**

- Push: dotfiles repository changes
- Push: claude-skills repository changes (already done)

**Step 1: Verify all dotfiles changes are committed**

```bash
cd /Users/josh.nichols/workspace/dotfiles
git status
```

Expected: "nothing to commit, working tree clean"

**Step 2: Push dotfiles changes**

```bash
cd /Users/josh.nichols/workspace/dotfiles
git push origin main
```

**Step 3: Verify push succeeded**

Run: `gh repo view technicalpickles/dotfiles --web`
Expected: Browser shows recent commits including plugin setup

**Step 4: Verify plugin repository is up to date**

```bash
cd ~/workspace/claude-skills
git status
```

Expected: "nothing to commit, working tree clean"

---

## Final Verification

### Task 14: Complete End-to-End Test

**Step 1: Test skill invocation in Claude Code**

Open Claude Code and test a skill:

- Ask: "Use the technicalpickles:working-in-monorepos skill"
- Verify: Skill loads and runs correctly

**Step 2: Test skill editing workflow**

```bash
# Make a small edit to a skill
echo "# Test edit" >> ~/workspace/claude-skills/skills/gh-pr.md
```

**Step 3: Verify change is immediately visible**

In Claude Code, verify the change appears without restarting

**Step 4: Revert test change**

```bash
cd ~/workspace/claude-skills
git checkout skills/gh-pr.md
```

**Step 5: Document success**

All tasks complete! Skills successfully extracted to plugin repository.

---

## Rollback Procedure (If Needed)

If something goes wrong, follow these steps to roll back:

### Rollback Step 1: Restore old skills in dotfiles

```bash
cd /Users/josh.nichols/workspace/dotfiles
git revert HEAD~<number-of-commits>  # Revert to before plugin changes
bash install.sh  # Reinstall with old symlinks
```

### Rollback Step 2: Remove plugin

```bash
rm -rf ~/.claude/plugins/technicalpickles
rm -rf ~/workspace/claude-skills
```

### Rollback Step 3: Verify old skills work

Check that skills are accessible via old `~/.claude/skills/` symlinks.

---

## Notes for Executor

- **Commit frequency**: After each major task (5-8 small steps)
- **Verification**: Always verify before moving to next task
- **Safety**: Keep old symlinks until Phase 4 - provides rollback safety
- **Testing**: Test on local machine before cleanup phase
- **Documentation**: Update README files to reflect new structure

## Success Criteria

- ✅ New plugin repository created and pushed to GitHub
- ✅ All skills copied to plugin with proper structure
- ✅ Dotfiles install.sh automatically sets up plugin
- ✅ Plugin works on local machine
- ✅ Old skills directory removed from dotfiles
- ✅ Documentation updated in both repositories
- ✅ Skills accessible via `technicalpickles:` prefix
