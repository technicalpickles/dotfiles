#!/usr/bin/env bash
set -euo pipefail

echo "Installing dotfiles-setup feature..."

# Feature options are passed as environment variables
INSTALL_DOTFILES="${INSTALLDOTFILES:-true}"
ROLE="${ROLE:-personal}"

echo "Configuration:"
echo "  Install dotfiles: $INSTALL_DOTFILES"
echo "  Role: $ROLE"

# Set the role environment variable for the installation
export DOTPICKLES_ROLE="$ROLE"

curl -sS https://starship.rs/install.sh > /tmp/starship-install.sh
sh /tmp/starship-install.sh --force
rm /tmp/starship-install.sh

if [ "$INSTALL_DOTFILES" = "true" ]; then
  echo "Running dotfiles installation..."

  # The workspace is mounted at /workspaces/<repo-name>
  # In a devcontainer, we're already in the workspace
  WORKSPACE_DIR="${PWD}"

  if [ -f "$WORKSPACE_DIR/install.sh" ]; then
    echo "Found install.sh at $WORKSPACE_DIR/install.sh"
    cd "$WORKSPACE_DIR"
    bash install.sh
  else
    echo "Warning: install.sh not found in workspace. Skipping dotfiles installation."
  fi
else
  echo "Skipping dotfiles installation (disabled via feature option)"
fi

echo "✓ dotfiles-setup feature installed successfully"
