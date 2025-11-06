# Devcontainer Live Editing Design

**Date:** 2025-11-06
**Status:** Approved

## Problem

The devcontainer Dockerfile copies the dotfiles repository to `/home/vscode/.pickles` and runs the installer during build. This means:

- Editing dotfiles in the workspace doesn't affect the running container
- Changes require rebuilding the entire devcontainer to see effects
- Development workflow is slow and cumbersome

We want most changes (especially shell configs) to take effect immediately by restarting the shell or sourcing configs.

## Solution

Swap the installed dotfiles directory with a symlink to the workspace during `post-create.sh`, then re-run `install.sh` to regenerate any needed files.

## Design

### Architecture Flow

1. **Dockerfile (build time):**

   - Copies repository to `/home/vscode/.pickles`
   - Runs `install.sh` which creates symlinks like `~/.bashrc` → `~/.pickles/home/.bashrc`

2. **Container start:**

   - Workspace mounts to `/workspaces/dotfiles`

3. **post-create.sh (after container creation):**
   - Removes `/home/vscode/.pickles` directory
   - Creates symlink: `/home/vscode/.pickles` → `/workspaces/dotfiles`
   - Runs `install.sh` again from the workspace to regenerate configs

**Key insight:** All existing symlinks (like `~/.bashrc` → `~/.pickles/home/.bashrc`) continue to work because they reference `~/.pickles`, which now points to the workspace.

### Implementation: post-create.sh

```bash
#!/usr/bin/env bash
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

### What Gets Regenerated

Running `install.sh` after the swap regenerates:

- Git submodules (if any)
- All symlinks from `home/` and `config/` (redundant but harmless)
- `~/.gitconfig.local` (dynamically generated)
- Any other generated configuration files

### Developer Workflow

**Making changes:**

1. Edit files in workspace (VSCode editor)
2. Changes are immediately visible at `~/.pickles/*` (via symlink)
3. For shell configs: restart terminal or `source ~/.config/fish/config.fish`
4. For complex changes needing install.sh: run `bash ~/.pickles/install.sh` manually

**If something breaks:**

- Rebuild devcontainer (runs Dockerfile installation fresh, then post-create swap)
- Or manually run `bash ~/.pickles/install.sh` to regenerate configs

## Trade-offs

### Advantages

- ✅ Simple implementation (just 2 commands for the swap)
- ✅ Most changes take effect immediately (restart shell)
- ✅ Can always regenerate by running install.sh manually
- ✅ All existing symlinks continue to work seamlessly

### Disadvantages

- ⚠️ First container startup takes slightly longer (runs install.sh twice)
- ⚠️ Need to remember to run install.sh for certain structural changes

### Rejected Alternatives

**Approach 2: Backup and Swap** - Move installed directory to `~/.pickles.installed` before symlinking. Rejected because treating breakages as bugs is simpler than maintaining backup directories.

**Approach 3: Conditional Swap with Safety Check** - Add validation that workspace looks like dotfiles repo before swapping. Rejected as unnecessary complexity; devcontainer mount failures would be obvious anyway.

## Decision Rationale

We treat any post-swap breakages as bugs to fix in the installation process, rather than designing defensive mechanisms around them. This keeps the implementation minimal and forces us to ensure `install.sh` is truly idempotent and workspace-location agnostic.

The double installation (once in Dockerfile, once in post-create) is acceptable because:

1. Dockerfile installation validates the base image setup works
2. Post-create installation adapts to the workspace mount
3. The time cost is minimal (seconds) compared to development iteration speed gains
