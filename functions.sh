#!/usr/bin/env bash

running_macos() {
  [ "$(uname)" == Darwin ]
  return $?
}

running_arm64_macos() {
  running_macos && [ "$(uname -m)" = "arm64" ]
}

running_home_role() {
  [ "${DOTPICKLES_ROLE:-home}" = "home" ]
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
  # sshconfig.sh handles config/1password's role-aware agent.toml symlink).
  # config/herdr is file-linked by symlinks.sh: herdr keeps live sockets,
  # session.json, and logs in ~/.config/herdr, which must not land in the repo.
  local -a skip=(config home config/fish config/1password config/herdr)
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

# Detect ~/Library/LaunchAgents symlinks that are dangling because their repo
# plist moved (e.g. a platform-gating move like LaunchAgents/foo.plist ->
# LaunchAgents/arm64-macos/foo.plist). Repoint them and force launchd to
# reload, since launchd runs an already-loaded job from memory and won't
# notice the plist moved until the next full re-scan (reboot).
repoint_dangling_launchagents() {
  local agents_dir="$HOME/Library/LaunchAgents"
  [ -d "$agents_dir" ] || return 0

  for target in "$agents_dir"/*.plist; do
    [ -e "$target" ] && continue # not dangling (valid symlink, real file, or no match)
    [ -L "$target" ] || continue # unmatched glob literal / not a symlink at all

    local name
    local current_repo_path=""
    name="$(basename "$target")"

    if running_arm64_macos && [ -d "$DIR/LaunchAgents/arm64-macos" ]; then
      current_repo_path="$(find "$DIR/LaunchAgents/arm64-macos" -maxdepth 1 -name "$name" -type f)"
    fi
    if [ -z "$current_repo_path" ]; then
      current_repo_path="$(find "$DIR/LaunchAgents" -maxdepth 1 -name "$name" -type f)"
    fi

    if [ -z "$current_repo_path" ]; then
      echo "⚠️  $target -> dangling, no applicable repo plist found (skipping)"
      continue
    fi

    local relative="${current_repo_path#"$DIR"/}"
    echo "🔧 $target -> dangling, repo plist now at $relative"
    link "$relative" "$target"

    if [ "$(readlink "$target")" = "$current_repo_path" ]; then
      echo "🔄 reloading $name"
      launchctl unload "$target" 2> /dev/null || true
      launchctl load "$target" 2> /dev/null || true
    fi
  done
}

# Print "<kind> <name>" for each live tap/brew/cask line in the given
# Brewfiles, in order. Comments, blank lines, other directives, and missing
# files are skipped.
brewfile_entries() {
  local file
  for file in "$@"; do
    [ -f "$file" ] || continue
    sed -nE "s/^[[:space:]]*(tap|brew|cask)[[:space:]]+['\"]([^'\"]+)['\"].*/\1 \2/p" "$file"
  done
}

# Print the names (one per line) of the given formulae or casks that aren't
# installed. `brew info` resolves aliases (gpg -> gnupg, nvim -> neovim) the
# same way brew does, so installed aliases don't look missing forever. Without
# jq (fresh machine), print every name and let `brew install` skip the rest.
missing_brew_packages() {
  local kind="$1"
  shift
  [ $# -gt 0 ] || return 0

  if ! command_available jq; then
    printf '%s\n' "$@"
    return 0
  fi

  local json filter
  if [ "$kind" = formula ]; then
    filter='.formulae[] | select(.installed | length == 0) | .full_name'
  else
    filter='.casks[] | select(.installed == null) | .full_token'
  fi
  # Don't let one unresolvable name (or a brew failure) abort the caller, which
  # may be running under `set -e`: fall back to treating everything as missing.
  if ! json="$(brew info --json=v2 "--$kind" "$@")" || ! jq -r "$filter" <<< "$json"; then
    echo "  → warning: brew info failed for $kind entries; installing all of them" >&2
    printf '%s\n' "$@"
  fi
}

# Install what Brewfile + Brewfile.$DOTPICKLES_ROLE declare. Replaces
# `brew bundle`, which hardened Homebrew refuses to run (ADR 0058). Missing
# formulae and casks each go in a single `brew install` so the approval prompt
# fires at most once per kind.
brew_install_brewfiles() {
  echo "🍻 installing Brewfile packages"
  local entries
  entries="$(brewfile_entries Brewfile "Brewfile.${DOTPICKLES_ROLE}")"

  # Taps to ensure: explicit `tap` lines plus the user/repo prefix of any
  # tap-qualified name (user/repo/name). Brew lowercases tap names.
  local installed_taps tap out rc=0
  installed_taps="$(brew tap)"
  for tap in $(awk '
    $1 == "tap" { print $2 }
    $1 != "tap" { n = split($2, p, "/"); if (n == 3) print p[1] "/" p[2] }
  ' <<< "$entries" | awk '!seen[tolower($0)]++'); do
    if ! grep -qxiF "$tap" <<< "$installed_taps"; then
      out="$(brew tap "$tap" 2>&1)" || echo "  → warning: brew tap $tap failed"
      [ -z "$out" ] || sed 's/^/  → /' <<< "$out"
    fi
  done

  # Brewfile keyword for each kind: `brew 'x'` is a formula, `cask 'x'` a cask.
  local kind word names missing
  for kind in formula cask; do
    word=brew
    [ "$kind" = cask ] && word=cask
    # shellcheck disable=SC2207
    names=($(awk -v k="$word" '$1 == k { print $2 }' <<< "$entries"))
    missing="$(missing_brew_packages "$kind" ${names[@]+"${names[@]}"})"
    if [ -n "$missing" ]; then
      # shellcheck disable=SC2086
      out="$(brew install "--$kind" $missing 2>&1)" && ok=1 || ok=0
      [ -z "$out" ] || sed 's/^/  → /' <<< "$out"
      if [ "$ok" = 0 ]; then
        echo "  → warning: brew install --$kind failed (see above)"
        rc=1
      fi
    else
      echo "  → all ${kind} entries installed"
    fi
  done
  echo
  return "$rc"
}

vim_plugins() {
  echo "⌨️️ configuring vim"
  vim +PlugInstall +qall
  echo
}

# make sure op is logged in
op_ensure_signed_in() {
  if ! which op > /dev/null 2> /dev/null; then
    # 1password-cli is a cask; hardened brew pins bare installs to --formula.
    brew install --cask 1password-cli
  fi

  if ! op whoami > /dev/null 2>&1; then
    op signin
  fi
}

# Detect and export DOTPICKLES_ROLE if it isn't already set. This is the single
# source of truth for the install/setup scripts: any script that sources
# functions.sh gets the role without re-implementing the hostname check, so a
# standalone run (e.g. ./gitconfig.sh) can't fall through to "Unexpected role".
# The interactive shells set it themselves (home/.zshenv,
# config/fish/conf.d/dotpickles-role.fish) because they can't source bash.
# Canonical names: home / work / container / claude-code-remote. See ADR 0035, 0040.
# Precedence: claude-code-remote (cloud is also a container, so it must win) ->
# container -> work (hostname) -> home.
dotpickles_detect_role() {
  if [ -n "${DOTPICKLES_ROLE:-}" ]; then
    return
  fi

  local detected_hostname
  detected_hostname=$(hostnamectl hostname 2> /dev/null || hostname)

  if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
    DOTPICKLES_ROLE=claude-code-remote
  elif [ -f /.dockerenv ] || grep -q 'docker\|lxc\|containerd' /proc/1/cgroup 2> /dev/null || [ -n "${DOCKER_BUILD:-}" ]; then
    DOTPICKLES_ROLE=container
  elif [[ "$detected_hostname" =~ ^josh-nichols- ]]; then
    DOTPICKLES_ROLE=work
  else
    DOTPICKLES_ROLE=home
  fi
  export DOTPICKLES_ROLE
}

# Run at source time so DOTPICKLES_ROLE is guaranteed set for every consumer.
dotpickles_detect_role

# Read a JSON or JSONC file to stdout, stripping comments and trailing commas.
# Shared by claudeconfig.sh, cloud-project-setup.sh, and local-project-setup.sh.
#
# Uses a single python3 parser rather than the node path it once had. The node
# path stripped comments with regexes that were not string-aware, so a glob like
# "~/Vaults/x/**/*.md" got its "/**/" eaten as an empty /* */ block comment,
# silently corrupting real permission values. python3 is present on both macOS
# and Ubuntu noble, and one string-aware implementation removes the whole class
# of "two parsers that disagree" bug. See bin/test-read-json.
read_json() {
  local file="$1"
  if ! command -v python3 > /dev/null 2>&1; then
    echo "read_json: python3 is required to parse $file" >&2
    return 1
  fi
  python3 - "$file" << 'PYEOF'
import json
import sys


def strip_comments(text):
    """Remove // and /* */ comments, but never inside string literals, so a
    URL like "http://x" or a glob like "a/**/b" survives untouched."""
    out = []
    i, n = 0, len(text)
    in_string = False
    while i < n:
        c = text[i]
        if in_string:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if c == '"':
                in_string = False
            i += 1
            continue
        if c == '"':
            in_string = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            i += 2
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def strip_trailing_commas(text):
    """Remove a comma that is followed (after whitespace) by } or ]. Runs on
    already comment-free text, so a comment can never sit between the comma and
    the closing brace and hide it. Still string-aware, so a comma inside a
    string value is left alone."""
    out = []
    i, n = 0, len(text)
    in_string = False
    while i < n:
        c = text[i]
        if in_string:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if c == '"':
                in_string = False
            i += 1
            continue
        if c == '"':
            in_string = True
            out.append(c)
            i += 1
            continue
        if c == ",":
            j = i + 1
            while j < n and text[j] in " \t\r\n":
                j += 1
            if j < n and text[j] in "}]":
                i += 1
                continue
            out.append(c)
            i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


file = sys.argv[1]
with open(file, "r") as f:
    content = f.read()

stripped = strip_trailing_commas(strip_comments(content))

try:
    data = json.loads(stripped)
except json.JSONDecodeError as e:
    sys.stderr.write("Error parsing " + file + ": " + str(e) + "\n")
    sys.exit(1)

print(json.dumps(data, separators=(",", ":")))
PYEOF
}
