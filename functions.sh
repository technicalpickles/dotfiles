#!/usr/bin/env bash

running_macos() {
  [ "$(uname)" == Darwin ]
  return $?
}

running_arm64_macos() {
  running_macos && [ "$(uname -m)" = "arm64" ]
}

running_codespaces() {
  [ "$CODESPACES" = true ]
  return $?
}

command_available() {
  which "$1" > /dev/null 2>&1
}

fzf_available() {
  command_available fzf
}

fish_available() {
  command_available fish
}

brew_available() {
  command_available brew
}

load_brew_shellenv() {
  if test -x /opt/homebrew/bin/brew; then
    brew=/opt/homebrew/bin/brew
  elif test -x /usr/local/bin/brew; then
    brew=/usr/local/bin/brew
  fi

  if test -n "${brew}"; then
    eval "$($brew shellenv)"
  fi
}

vscode_command() {
  if command_available code-insiders; then
    code="code-insiders"
  elif command_available code; then
    code="code"
  fi

  echo "$code"
}

find_targets() {
  local directory="$1"
  # only get the top level files/directories
  # also exclude the directory itself
  find "$directory" -mindepth 1 -maxdepth 1
}

link_directory_contents() {
  local directory="$1"
  # Items managed by their own installer scripts (e.g. fish.sh handles config/fish,
  # sshconfig.sh handles config/1password's role-aware agent.toml symlink)
  local -a skip=(config home config/fish config/1password)
  for linkable in $(find_targets "${directory}"); do
    local should_skip=false
    for s in "${skip[@]}"; do
      if [[ "$linkable" = "$s" ]]; then
        should_skip=true
        break
      fi
    done
    if $should_skip; then
      continue
    fi

    if [ "$directory" = "home" ]; then
      target="$HOME/$(basename "$linkable")"
    elif [ "${directory}" = "config" ]; then
      target="$HOME/.config/$(basename "$linkable")"
    else
      echo "don't know where to put ${directory} links"
      return 1
    fi

    link "$linkable" "$target"
  done
}

# Ask a y/N question. Returns 0 for yes, 1 for no.
# In auto-yes mode, always returns 0. Scripts guard against
# non-interactive use at startup, so this always has a tty or --yes.
confirm() {
  local prompt="$1"
  if [ "${DOTPICKLES_YES:-}" = "1" ]; then
    return 0
  fi
  read -p "$prompt " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

backup_path() {
  local target="$1"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local backup="${target}.backup.${timestamp}"
  local counter=2
  while [ -e "$backup" ]; do
    backup="${target}.backup.${timestamp}-${counter}"
    counter=$((counter + 1))
  done
  echo "$backup"
}

link() {
  local linkable="$1"
  local target="$2"
  local display_target="${target/$HOME/~}"
  local source="${DIR}/${linkable}"

  if [ -L "$target" ]; then
    # Target is a symlink
    if [ "$(readlink "$target")" = "$source" ]; then
      echo "🔗 $display_target -> already linked"
    elif confirm "🔗 $display_target -> linked to $(readlink "$target"). Repoint to ${linkable}? [y/N]"; then
      echo "🔗 $display_target -> linking from $linkable"
      ln -Ff -s "$source" "$target"
    else
      echo "🔗 $display_target -> skipped (wrong symlink)"
    fi
  elif [ -e "$target" ]; then
    # Target exists as real file or directory
    local filetype="file"
    [ -d "$target" ] && filetype="directory"

    if confirm "🔗 $display_target -> exists as $filetype. Replace with symlink to ${linkable}? [y/N]"; then
      local backup
      backup="$(backup_path "$target")"
      echo "🔗 $display_target -> backing up to ${backup##*/}"
      mv "$target" "$backup"
      echo "🔗 $display_target -> linking from $linkable"
      ln -s "$source" "$target"
    else
      echo "🔗 $display_target -> skipped ($filetype exists)"
    fi
  else
    # Target doesn't exist
    echo "🔗 $display_target -> linking from $linkable"
    ln -s "$source" "$target"
  fi
}

brew_bundle() {
  echo "🍻 running brew bundle"
  cat Brewfile "Brewfile.${DOTPICKLES_ROLE}" 2> /dev/null | brew bundle --file=- 2>&1 | sed 's/^/  → /'
  echo
}

vim_plugins() {
  echo "⌨️️ configuring vim"
  vim +PlugInstall +qall
  echo
}

# make sure op is logged in
op_ensure_signed_in() {
  if ! which op > /dev/null 2> /dev/null; then
    brew install 1password-cli
  fi

  if ! op whoami > /dev/null 2>&1; then
    op signin
  fi
}

# Read a JSON or JSONC file to stdout, stripping comments and trailing commas.
# Uses node if available for robust JSONC parsing, falls back to sed + jq.
# Shared by claudeconfig.sh and claude-project-setup.sh.
read_json() {
  local file="$1"
  if command -v node > /dev/null 2>&1; then
    # Node handles JSONC natively with JSON5-like parsing
    node -e "
      const fs = require('fs');
      const file = '$file';
      const content = fs.readFileSync(file, 'utf8');
      // Strip comments and trailing commas
      const stripped = content
        .replace(/\/\/.*$/gm, '')           // Remove // comments
        .replace(/\/\*[\s\S]*?\*\//g, '')   // Remove /* */ comments
        .replace(/,(\s*[}\]])/g, '\$1');    // Remove trailing commas
      try {
        console.log(JSON.stringify(JSON.parse(stripped)));
      } catch (e) {
        process.stderr.write('Error parsing ' + file + ': ' + e.message + '\n');
        process.exit(1);
      }
    "
  else
    # Fallback: simple sed-based stripping (less robust)
    sed -E 's|//[^"]*$||g' < "$file" \
      | tr '\n' '\f' \
      | sed -E 's|,([[:space:]\f]*[}\]])|\1|g' \
      | tr '\f' '\n' \
      | jq '.'
  fi
}
