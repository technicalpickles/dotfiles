#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./functions.sh
source "$DIR/functions.sh"

MANIFEST="$DIR/claude/cross-repo-access.jsonc"

# Grants a repo's Claude Code sessions filesystem access to sibling repos it
# routinely reaches into directly (git add/commit/push, deploy scripts, etc.
# run against a different repo via `cd`/`git -C`). The sandbox only
# auto-grants write access to a session's own working directory, so without
# this, those cross-repo commands fail with "Operation not permitted" and
# fall back to dangerouslyDisableSandbox. See ADR 0057.
#
# Unlike cloud-project-setup.sh, this writes the repo's GITIGNORED
# .claude/settings.local.json, not the committed settings.json: sibling repo
# paths are machine-specific (~/github.com/technicalpickles/... here,
# ~/projects/... on pickled-coi), so committing them would be wrong on any
# other machine. Re-run this script on each machine where the repo needs the
# same cross-repo access -- it isn't propagated by git.
#
# Bootstrapping note: writing into TARGET_DIR is itself a cross-repo write if
# your current session isn't rooted in TARGET_DIR -- e.g. running this from a
# dotfiles session against ~/github.com/technicalpickles/pickleclaw hits the
# exact sandbox wall this script exists to fix, and needs
# dangerouslyDisableSandbox for that one-time bootstrap. Run it from inside
# TARGET_DIR itself to avoid that.

usage() {
  cat << 'EOF'
Usage: local-project-setup.sh [TARGET_DIR] [--dry-run]

Writes <TARGET_DIR>/.claude/settings.local.json with
permissions.additionalDirectories, listing the sibling repos TARGET_DIR is
declared to need (from claude/cross-repo-access.jsonc), each resolved as a
directory alongside TARGET_DIR. MERGES into any existing local settings
(other keys survive; additionalDirectories entries are unioned, not
replaced).

Arguments:
  TARGET_DIR    project directory to configure (default: current directory)

Options:
  --dry-run     print the merged settings.local.json without writing
  -h, --help    show this help
EOF
}

if ! command_available jq; then
  echo "Error: jq required. Install with: brew install jq" >&2
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "Error: manifest not found: $MANIFEST" >&2
  exit 1
fi

TARGET_DIR=""
DRY_RUN=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      echo "Run 'local-project-setup.sh --help' for usage." >&2
      exit 2
      ;;
    *)
      if [ -n "$TARGET_DIR" ]; then
        echo "Error: unexpected extra argument: $1" >&2
        exit 2
      fi
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

TARGET_DIR="${TARGET_DIR:-$(pwd)}"
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: target is not a directory: $TARGET_DIR" >&2
  exit 2
fi
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
REPO_NAME="$(basename "$TARGET_DIR")"
PARENT_DIR="$(dirname "$TARGET_DIR")"

echo "🔗 Configuring cross-repo access for: $TARGET_DIR"

manifest_json="$(read_json "$MANIFEST")"
siblings="$(echo "$manifest_json" | jq -r --arg repo "$REPO_NAME" '.[$repo] // [] | .[]')"

if [ -z "$siblings" ]; then
  echo "   No cross-repo access declared for '$REPO_NAME' in claude/cross-repo-access.jsonc -- nothing to do."
  exit 0
fi

# Resolve each declared sibling as a directory alongside TARGET_DIR, and warn
# (don't fail) if it isn't actually cloned there -- the entry might be for a
# machine that hasn't cloned it yet.
paths_json="[]"
while IFS= read -r sibling; do
  [ -z "$sibling" ] && continue
  sibling_path="$PARENT_DIR/$sibling"
  if [ ! -d "$sibling_path" ]; then
    echo "   ⚠ $sibling_path does not exist on this machine -- adding it anyway (clone it, or it's a no-op)" >&2
  fi
  paths_json="$(echo "$paths_json" | jq --arg p "$sibling_path" '. + [$p]')"
done <<< "$siblings"

echo "   Sibling repos: $(echo "$paths_json" | jq -r 'join(", ")')"

settings_file="$TARGET_DIR/.claude/settings.local.json"

existing="{}"
if [ -f "$settings_file" ]; then
  if ! existing="$(read_json "$settings_file" 2> /dev/null)"; then
    echo "Error: $settings_file exists but is not valid JSON; refusing to overwrite." >&2
    exit 1
  fi
fi

# Merge: union additionalDirectories (dedup, sorted) rather than replacing it,
# so a manual addition of the user's own survives a re-run. Other keys pass
# through untouched.
merged="$(echo "$existing" | jq --argjson new "$paths_json" '
  .permissions = (.permissions // {})
  | .permissions.additionalDirectories = (((.permissions.additionalDirectories // []) + $new) | unique | sort)
')"

if [ -n "$DRY_RUN" ]; then
  echo "   (dry run -- not writing $settings_file)"
  echo "$merged"
  exit 0
fi

mkdir -p "$TARGET_DIR/.claude"
temp_file="$(mktemp)"
echo "$merged" > "$temp_file"
if ! jq empty "$temp_file" 2> /dev/null; then
  echo "Error: generated invalid JSON" >&2
  rm -f "$temp_file"
  exit 1
fi

if [ -f "$settings_file" ] && [ ! -f "$settings_file.backup" ]; then
  cp "$settings_file" "$settings_file.backup"
  echo "   ℹ Backed up existing settings to ${settings_file##*/}.backup"
fi

mv "$temp_file" "$settings_file"
echo "   ✓ Wrote $settings_file (gitignored -- re-run this script on any other machine that needs the same access)"
