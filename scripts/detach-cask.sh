#!/usr/bin/env bash
# Make Homebrew forget app casks without deleting the apps.
#
# Hardened Homebrew (ADR 0058) refuses to run while Caskroom holds app casks,
# and `brew uninstall --cask` would delete the app itself. This removes the
# cask's Caskroom entry and the symlinks brew made for it (binaries,
# completions, manpages), leaving the .app in place to update itself.
#
# Run only while Homebrew is NOT hardened (you must own the prefix).
#
# Usage:
#   scripts/detach-cask.sh [--yes] <cask>...
#
# Without --yes, prints what would be removed and changes nothing.

set -euo pipefail

prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
apply=0
if [ "${1:-}" = "--yes" ]; then
  apply=1
  shift
fi
if [ $# -eq 0 ]; then
  echo "usage: $0 [--yes] <cask>..." >&2
  exit 2
fi

# Check for flags in non-first position
for arg in "$@"; do
  if [[ "$arg" =~ ^- ]]; then
    echo "usage: $0 [--yes] <cask>..." >&2
    exit 2
  fi
done

# Validate all tokens before any deletion
for token in "$@"; do
  if [ "$token" = "." ] || [ "$token" = ".." ] || ! [[ "$token" =~ ^[a-z0-9][a-z0-9@+._-]*$ ]]; then
    echo "invalid cask name: '$token'" >&2
    exit 2
  fi
done

# Helper function to escape glob characters for use in find -lname
escape_glob_pattern() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\*/\\*}"
  s="${s//\?/\\?}"
  s="${s//\[/\\[}"
  s="${s//\]/\\]}"
  printf '%s\n' "$s"
}

for token in "$@"; do
  caskroom="$prefix/Caskroom/$token"
  if [ ! -d "$caskroom" ]; then
    echo "skip $token: not in $prefix/Caskroom"
    continue
  fi

  # Match links into the Caskroom entry, plus links into the cask's app
  # bundles (e.g. Hammerspoon's `hs` points inside the .app).
  find_args=(-lname "*/Caskroom/$token/*")
  receipt="$caskroom/.metadata/INSTALL_RECEIPT.json"

  # Handle receipt: missing, jq unavailable, or malformed
  if [ ! -f "$receipt" ]; then
    echo "skip $token: cannot read $receipt (file not found)" >&2
    continue
  fi

  if ! command -v jq > /dev/null 2>&1; then
    echo "skip $token: cannot read $receipt (jq not found)" >&2
    continue
  fi

  jq_out=$(jq -r '.uninstall_artifacts[]? | select(type == "object" and has("app")) | .app[] | strings' "$receipt" 2>&1) || {
    echo "skip $token: cannot read $receipt (jq failed)" >&2
    continue
  }

  while IFS= read -r app; do
    if [ -n "$app" ]; then
      escaped_app=$(escape_glob_pattern "$app")
      find_args+=(-o -lname "*/$escaped_app/*")
    fi
  done <<< "$jq_out"

  links="$(find "$prefix/bin" "$prefix/sbin" "$prefix/share" -type l \( "${find_args[@]}" \) 2> /dev/null || true)"

  echo "$token:"
  if [ -n "$links" ]; then
    while IFS= read -r link; do
      echo "  link $link"
    done <<< "$links"
  fi
  echo "  caskroom $caskroom"

  if [ "$apply" -eq 1 ]; then
    if [ -n "$links" ]; then
      while IFS= read -r link; do
        rm -f "$link"
      done <<< "$links"
    fi
    rm -rf "$caskroom"
    echo "  detached"
  fi
done

[ "$apply" -eq 1 ] || echo "(dry run; pass --yes to remove)"
