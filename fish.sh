#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./functions.sh
source ./functions.sh

if ! which fish > /dev/null 2> /dev/null; then
  echo "missing fish :("
  exit 1
fi

echo "🐟 configuring fish"
fish_path=$(which fish)
if test -f /etc/shells && ! grep -q "$fish_path" /etc/shells; then
  sudo bash -c "which fish >> /etc/shells"
fi

if running_macos; then
  if ! dscl . -read "$HOME" UserShell | grep -q "$fish_path"; then
    chsh -s "$fish_path"
  fi
fi

if ! fish -c "type fisher >/dev/null 2>/dev/null"; then
  echo "installing fisher"
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi

# Read core plugins from file (skip comments and blank lines)
core_plugins=()
core_plugins_file="$DIR/config/fish/core_plugins"
if [[ -f "$core_plugins_file" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and blank lines
    [[ "$line" =~ ^#.*$ || -z "${line// /}" ]] && continue
    core_plugins+=("$line")
  done < "$core_plugins_file"
else
  echo "Warning: $core_plugins_file not found, using empty core list"
fi

# Apply conditionals - add plugins that depend on available commands
if command_available fzf; then
  core_plugins+=(patrickf1/fzf.fish)
fi

if command_available direnv; then
  core_plugins+=(halostatue/fish-direnv)
fi

# Normalize plugin names to lowercase for comparison
normalize_plugin() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Read current fish_plugins if it exists
current_plugins=()
fish_plugins_file="$HOME/.config/fish/fish_plugins"
if [[ -f "$fish_plugins_file" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line// /}" ]] && continue
    current_plugins+=("$line")
  done < "$fish_plugins_file"
fi

# Find extra plugins (in current but not in core)
extra_plugins=()
for current in "${current_plugins[@]}"; do
  current_normalized=$(normalize_plugin "$current")
  is_core=false
  for core in "${core_plugins[@]}"; do
    core_normalized=$(normalize_plugin "$core")
    if [[ "$current_normalized" == "$core_normalized" ]]; then
      is_core=true
      break
    fi
  done
  if [[ "$is_core" == false ]]; then
    extra_plugins+=("$current")
  fi
done

# Display core plugins
echo
echo "Core plugins (${#core_plugins[@]}):"
for plugin in "${core_plugins[@]}"; do
  echo "  $plugin"
done

# Handle drift
preserve_extras=()
if [[ ${#extra_plugins[@]} -gt 0 ]]; then
  echo
  echo "Extra plugins found (${#extra_plugins[@]}):"
  for plugin in "${extra_plugins[@]}"; do
    echo "  $plugin"
  done

  if [[ -t 0 ]]; then
    # Interactive - prompt user
    echo
    read -r -p "Keep extra plugins? [Y/n] " response
    case "$response" in
      [nN] | [nN][oO])
        echo "Dropping extra plugins"
        ;;
      *)
        echo "Keeping extra plugins"
        preserve_extras=("${extra_plugins[@]}")
        ;;
    esac
  else
    # Non-interactive - auto-preserve
    echo
    echo "Non-interactive mode, auto-preserving extra plugins"
    preserve_extras=("${extra_plugins[@]}")
  fi
fi

# Determine plugins to remove (extras not being preserved)
plugins_to_remove=()
for extra in "${extra_plugins[@]}"; do
  extra_normalized=$(normalize_plugin "$extra")
  should_keep=false
  for preserve in "${preserve_extras[@]}"; do
    preserve_normalized=$(normalize_plugin "$preserve")
    if [[ "$extra_normalized" == "$preserve_normalized" ]]; then
      should_keep=true
      break
    fi
  done
  if [[ "$should_keep" == false ]]; then
    plugins_to_remove+=("$extra")
  fi
done

# Remove plugins that are not being preserved
if [[ ${#plugins_to_remove[@]} -gt 0 ]]; then
  echo
  echo "Removing plugins..."
  for plugin in "${plugins_to_remove[@]}"; do
    echo "  Removing $plugin"
    fish -c "fisher remove $plugin" 2> /dev/null || true
  done
fi

# Build list of all desired plugins (excluding fisher, handled separately)
desired_plugins=()
for plugin in "${core_plugins[@]}" "${preserve_extras[@]}"; do
  if [[ "$(normalize_plugin "$plugin")" != "jorgebucaran/fisher" ]]; then
    desired_plugins+=("$plugin")
  fi
done

echo
echo "Installing/updating plugins..."

# Ensure fisher is installed first (don't remove it!)
fish -c "fisher install jorgebucaran/fisher 2>/dev/null || true"

# Install or update all other desired plugins
# Remove first to handle orphaned files, then install fresh
for plugin in "${desired_plugins[@]}"; do
  fish -c "fisher remove $plugin 2>/dev/null; fisher install $plugin"
done

echo
