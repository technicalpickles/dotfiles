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
