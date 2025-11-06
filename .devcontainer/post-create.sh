# #!/usr/bin/env bash
# # Post-create script for devcontainer
# # Runs after the container is created but before it's ready for use

# set -euo pipefail

# echo "Running post-create setup..."

# # Get the workspace directory (where the repo is mounted)
# WORKSPACE_DIR="${PWD}"

# echo "Workspace: $WORKSPACE_DIR"
# echo

# # Install npm dependencies
# if [ -f "$WORKSPACE_DIR/package.json" ]; then
#   echo "📦 Installing npm dependencies..."
#   npm install
#   echo "✓ npm dependencies installed"
#   echo
# fi

# # Set up git configuration for the container
# echo "🔧 Configuring git for container..."
# git config --global --add safe.directory "$WORKSPACE_DIR"
# echo "✓ Git configuration complete"
# echo

# # Optional: Run any additional setup commands here
# # Examples:
# # - Initialize mise/asdf tool versions
# # - Set up shell configurations
# # - Run any workspace-specific initialization

# echo "✓ Post-create setup complete!"
# echo
# echo "Ready to develop! 🚀"
