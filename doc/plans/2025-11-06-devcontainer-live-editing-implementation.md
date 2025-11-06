# Devcontainer Live Editing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enable live-editing of dotfiles in devcontainer by swapping installed directory with symlink to workspace during post-create.

**Architecture:** Remove `/home/vscode/.pickles` created during Dockerfile build, symlink it to the mounted workspace, then re-run `install.sh` to regenerate configs. This preserves all existing symlinks while making workspace edits immediately visible.

**Tech Stack:** Bash, Git, devcontainer lifecycle hooks

---

## Task 1: Implement post-create.sh Script

**Files:**

- Modify: `.devcontainer/post-create.sh`

**Step 1: Uncomment and update post-create.sh with swap logic**

Replace the commented-out content in [.devcontainer/post-create.sh](.devcontainer/post-create.sh) with:

```bash
#!/usr/bin/env bash
# Post-create script for devcontainer
# Runs after the container is created but before it's ready for use

set -euo pipefail

echo "Running post-create setup..."

# Determine workspace directory
WORKSPACE_DIR="${PWD}"
echo "Workspace: $WORKSPACE_DIR"
echo

# Swap ~/.pickles to point to workspace
echo "🔄 Swapping ~/.pickles to workspace..."
rm -rf /home/vscode/.pickles
ln -sf "$WORKSPACE_DIR" /home/vscode/.pickles
echo "✓ ~/.pickles now points to $WORKSPACE_DIR"
echo

# Re-run installation to regenerate configs
echo "📦 Re-running dotfiles installation..."
cd /home/vscode/.pickles
bash install.sh
echo "✓ Dotfiles installation complete"
echo

# Install npm dependencies
if [ -f "$WORKSPACE_DIR/package.json" ]; then
  echo "📦 Installing npm dependencies..."
  cd "$WORKSPACE_DIR"
  npm install
  echo "✓ npm dependencies installed"
  echo
fi

# Configure git
echo "🔧 Configuring git for container..."
git config --global --add safe.directory "$WORKSPACE_DIR"
echo "✓ Git configuration complete"
echo

echo "✓ Post-create setup complete!"
echo "Ready to develop! 🚀"
```

**Step 2: Verify script syntax**

Run: `bash -n .devcontainer/post-create.sh`
Expected: No output (syntax valid)

**Step 3: Commit the changes**

```bash
git add .devcontainer/post-create.sh
git commit -m "feat: implement devcontainer live editing via post-create swap

Replace installed ~/.pickles with symlink to workspace, then re-run
install.sh to regenerate configs. Enables immediate visibility of
workspace changes.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2: Update CLAUDE.md Documentation

**Files:**

- Modify: `CLAUDE.md`

**Step 1: Add devcontainer section to CLAUDE.md**

Add a new section after the "Development Commands" section (around line 45):

````markdown
### Devcontainer Development

The devcontainer provides a consistent Linux environment for developing dotfiles:

**Live Editing:** Changes to files in the workspace are immediately visible at `~/.pickles` via symlink created during post-create. Most changes (shell configs, scripts) take effect when you restart the terminal or source configs.

**When to re-run install.sh:** Structural changes that affect symlinks or generated configs may require running:

```bash
bash ~/.pickles/install.sh
```
````

**How it works:**

1. Dockerfile builds image and installs dotfiles to `/home/vscode/.pickles`
2. Container starts, workspace mounts to `/workspaces/dotfiles`
3. `post-create.sh` swaps the directory: `~/.pickles` → symlink to `/workspaces/dotfiles`
4. `install.sh` runs again to regenerate configs like `~/.gitconfig.local`

See [doc/plans/2025-11-06-devcontainer-live-editing.md](doc/plans/2025-11-06-devcontainer-live-editing.md) for design details.

````

**Step 2: Verify markdown formatting**

Run: `npm run format:check`
Expected: No errors for CLAUDE.md

**Step 3: Format if needed**

Run: `npm run format`

**Step 4: Commit the documentation**

```bash
git add CLAUDE.md
git commit -m "docs: document devcontainer live editing workflow

Add explanation of how post-create swap enables live editing and when
to re-run install.sh.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
````

---

## Task 3: Verification Testing

**Step 1: Test script in current environment (dry run)**

Since we can't actually test in a devcontainer from this environment, verify the logic manually:

Run: `cat .devcontainer/post-create.sh`
Expected: Script matches the implementation with proper error handling (`set -euo pipefail`)

**Step 2: Verify devcontainer configuration references post-create**

Run: `grep -A2 "postCreateCommand" .devcontainer/devcontainer.json`
Expected: Shows `"postCreateCommand": "bash .devcontainer/post-create.sh"`

**Step 3: Verify design document is included**

Run: `test -f doc/plans/2025-11-06-devcontainer-live-editing.md && echo "Design doc exists"`
Expected: "Design doc exists"

**Step 4: Run full test suite**

Run: `npm test`
Expected: All tests pass (typecheck + format check)

**Step 5: Commit any formatting fixes**

If formatting was needed:

```bash
git add -A
git commit -m "chore: apply prettier formatting

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4: Final Integration Check

**Step 1: Review all changes**

Run: `git log --oneline origin/devcontainer..HEAD`
Expected: Shows commits for post-create implementation and documentation

**Step 2: Check git status**

Run: `git status`
Expected: "nothing to commit, working tree clean"

**Step 3: Verify files are staged correctly**

Run: `git diff origin/devcontainer..HEAD --stat`
Expected: Shows modifications to:

- `.devcontainer/post-create.sh`
- `CLAUDE.md`
- Possibly formatting changes

**Step 4: Document testing requirements**

The actual testing must happen by:

1. Building the devcontainer: `bin/devcontainer-build` (or rebuild in IDE)
2. Running the devcontainer: `bin/devcontainer-run` (or start in IDE)
3. Verifying `~/.pickles` is a symlink: `ls -la ~/.pickles`
4. Verifying it points to workspace: `readlink ~/.pickles`
5. Making a test edit to workspace file and seeing it reflected at `~/.pickles`
6. Restarting terminal and verifying config changes take effect

**Step 5: Add note to commit message about testing needs**

This is already captured in the design document, no additional commit needed.

---

## Post-Implementation Notes

**Testing in devcontainer:**
The implementation cannot be fully tested until the devcontainer is rebuilt with these changes. The manual testing steps are:

1. Commit and push changes to branch
2. Rebuild devcontainer (or open in fresh container)
3. Verify symlink: `ls -la ~/.pickles` should show symlink to `/workspaces/dotfiles`
4. Edit a fish config file in workspace
5. Restart terminal and verify change is visible
6. Run `bash ~/.pickles/install.sh` to test regeneration works

**Expected behavior:**

- Symlinks like `~/.bashrc` → `~/.pickles/home/.bashrc` continue working
- Workspace edits immediately visible at `~/.pickles/*`
- Shell config changes: restart terminal
- Structural changes: re-run `install.sh`

**Rollback if needed:**
If the swap breaks something, the Dockerfile installation is preserved in the image layers. Simply rebuild the devcontainer from the previous commit.
