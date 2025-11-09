#!/usr/bin/env bash
set -euo pipefail
set -x
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

# Remove fish_variables to prevent macOS paths from being used
echo "🧹 Removing fish_variables with host-specific paths..."
rm -f /home/vscode/.pickles/config/fish/fish_variables
echo "✓ Removed fish_variables"
echo

# Re-run installation to regenerate configs
echo "📦 Re-running dotfiles installation..."
cd /home/vscode/.pickles
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
echo "✓ Git configuration complete"
echo

echo "✓ Post-create setup complete!"
echo "Ready to develop! 🚀"
