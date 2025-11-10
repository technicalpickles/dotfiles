#!/usr/bin/env bash
set -euo pipefail
set -x
echo "Running post-create setup..."

# Source and destination directories
SOURCE_DIR="/workspaces/dotfiles-source"
WORKSPACE_DIR="/workspace/dotfiles"

echo "Source: $SOURCE_DIR"
echo "Workspace: $WORKSPACE_DIR"
echo

# Clone the workspace from source to working directory
if [ ! -d "$WORKSPACE_DIR/.git" ]; then
  echo "📋 Cloning workspace from source..."
  mkdir -p /workspace
  # Use git clone to create a fresh, independent copy with full git history
  # --no-hardlinks ensures files are copied, not hard-linked (required when cloning across filesystems)
  # This avoids any shared state (like fish_variables) between host and container
  git clone --no-hardlinks "$SOURCE_DIR" "$WORKSPACE_DIR"
  echo "✓ Workspace cloned to $WORKSPACE_DIR"
  echo
else
  echo "ℹ️  Workspace already exists at $WORKSPACE_DIR"
  echo
fi

# Point ~/.pickles to the cloned workspace
echo "🔄 Setting up ~/.pickles symlink..."
rm -rf /home/vscode/.pickles
ln -sf "$WORKSPACE_DIR" /home/vscode/.pickles
echo "✓ ~/.pickles now points to $WORKSPACE_DIR"
echo

# Remove fish_variables to ensure fresh container state
echo "🧹 Removing fish_variables..."
rm -f "$WORKSPACE_DIR/config/fish/fish_variables"
echo "✓ Removed fish_variables"
echo

# Run dotfiles installation
echo "📦 Running dotfiles installation..."
cd "$WORKSPACE_DIR"
export DOTPICKLES_ROLE=devcontainer
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
git config --global --add safe.directory "$SOURCE_DIR"
echo "✓ Git configuration complete"
echo

echo "✓ Post-create setup complete!"
echo "Ready to develop! 🚀"
echo
echo "NOTE: You are working in a cloned copy at $WORKSPACE_DIR"
echo "      The host workspace is mounted read-only at $SOURCE_DIR"
