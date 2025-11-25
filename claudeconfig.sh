#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/functions.sh"

# Prerequisite checks
if ! command_available claude; then
  echo "Error: claude command not found. Install Claude Code first."
  exit 1
fi

if ! command_available jq; then
  echo "Error: jq required for JSON merging. Install with: brew install jq"
  exit 1
fi

# Detect role (uses existing DOTPICKLES_ROLE from environment)
ROLE="${DOTPICKLES_ROLE:-personal}"
echo "Configuring Claude Code for role: $ROLE"

# Install marketplaces (idempotent)
install_marketplaces() {
  echo "Installing marketplaces..."

  local marketplaces=(
    "superpowers-marketplace"
    "anthropic-agent-skills"
    "technicalpickles-marketplace"
    "claude-notifications-go"
  )

  for marketplace in "${marketplaces[@]}"; do
    if claude marketplace list 2> /dev/null | grep -q "$marketplace"; then
      echo "  ✓ $marketplace (already added)"
    else
      echo "  + Adding $marketplace..."
      if claude marketplace add "$marketplace"; then
        echo "    ✓ Added successfully"
      else
        echo "    ✗ Failed to add (continuing anyway)"
      fi
    fi
  done
}

install_marketplaces

# Install plugins (idempotent)
install_plugins() {
  echo "Installing plugins..."

  local plugins=(
    "superpowers@superpowers-marketplace"
    "elements-of-style@superpowers-marketplace"
    "superpowers-developing-for-claude-code@superpowers-marketplace"
    "git-workflows@technicalpickles-marketplace"
    "working-in-monorepos@technicalpickles-marketplace"
    "ci-cd-tools@technicalpickles-marketplace"
    "debugging-tools@technicalpickles-marketplace"
    "dev-tools@technicalpickles-marketplace"
    "document-skills@anthropic-agent-skills"
    "claude-notifications-go@claude-notifications-go"
  )

  for plugin in "${plugins[@]}"; do
    if claude plugin list 2> /dev/null | grep -q "$plugin"; then
      echo "  ✓ $plugin (already installed)"
    else
      echo "  + Installing $plugin..."
      if claude plugin install "$plugin"; then
        echo "    ✓ Installed successfully"
      else
        echo "    ✗ Failed to install (continuing anyway)"
      fi
    fi
  done
}

install_plugins
