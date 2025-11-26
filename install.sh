#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DIR

if [[ -f .env ]]; then
  source .env
fi

# shellcheck source=./functions.sh
source ./functions.sh

if [[ -z "${DOTPICKLES_ROLE}" ]]; then
  DOTPICKLES_ROLE=$(detect_role)
fi

echo "role: $DOTPICKLES_ROLE"

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

if running_macos; then
  # Prevent sleeping during script execution, as long as the machine is on AC power
  caffeinate -s -w $$ &
fi

# only setup submodules if running in a git repo. doesn't apply to devcontainer which copies files in
if [ -d .git ]; then
  git submodule init
  git submodule update || {
    echo "Warning: Some submodules failed to initialize (this is non-fatal)"
    true # Ensure we don't exit with error code
  }
fi

./symlinks.sh

echo

./gitconfig.sh

# Setup Claude Code configuration
if command_available claude; then
  echo "Configuring Claude Code..."
  bash "$DIR/claudeconfig.sh"
else
  echo "Claude Code not installed, skipping configuration"
fi

setup_claude_plugin

if running_macos; then
  load_brew_shellenv

  if ! brew_available; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew_shellenv
  fi

  brew_bundle

  echo "🍎 configuring macOS defaults"
  ~/.macos
  echo

  echo "🔐 configuring SSH to use keychain"
  ssh-add --apple-load-keychain

  # ./gh-shorthand.sh
fi

if ! running_codespaces; then
  #  ./vim.sh
  ./tmux.sh
  ./fish.sh
  ./bash.sh
fi

echo "✅ Done"
