#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./functions.sh
source "$DIR/functions.sh"

MANIFEST="$DIR/claude/marketplaces.jsonc"

# Stamp a recommended Claude Code plugin/marketplace set into a project's
# COMMITTED .claude/settings.json, so the repo works well in Claude Code on the
# web (cloud), where it's cloned fresh with no global ~/.claude. Marketplaces and
# plugins come from claude/marketplaces.jsonc (shared with claudeconfig.sh).

usage() {
  cat << 'EOF'
Usage: claude-project-setup.sh [TARGET_DIR] [--profile NAME] [--list-profiles] [--dry-run]

Writes <TARGET_DIR>/.claude/settings.json with extraKnownMarketplaces +
enabledPlugins for the chosen profile, MERGING into any existing settings
(other keys like permissions/hooks are preserved). Commit the result so
Claude Code on the web picks the plugins up.

Arguments:
  TARGET_DIR        project directory to configure (default: current directory)

Options:
  --profile NAME    plugin bundle from claude/marketplaces.jsonc (default: its defaultProfile)
  --list-profiles   list available profiles and their plugins, then exit
  --dry-run         print the merged settings.json without writing
  -h, --help        show this help
EOF
}

# Prerequisite: jq (the merge engine). node is optional (read_json falls back).
if ! command_available jq; then
  echo "Error: jq required. Install with: brew install jq" >&2
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "Error: manifest not found: $MANIFEST" >&2
  exit 1
fi

TARGET_DIR=""
PROFILE=""
DRY_RUN=""
while [ $# -gt 0 ]; do
  case "$1" in
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --list-profiles)
      read_json "$MANIFEST" | jq -r '
        "Profiles (default: \(.defaultProfile)):",
        (.profiles | to_entries[] | "  \(.key):\n" + (.value | map("    - " + .) | join("\n")))'
      exit 0
      ;;
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
      echo "Run 'claude-project-setup.sh --help' for usage." >&2
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

# Default profile from the manifest when not given.
manifest_json="$(read_json "$MANIFEST")"
if [ -z "$PROFILE" ]; then
  PROFILE="$(echo "$manifest_json" | jq -r '.defaultProfile')"
fi

echo "🔌 Configuring Claude plugins for: $TARGET_DIR"
echo "   Profile: $PROFILE"

# Build {extraKnownMarketplaces, enabledPlugins} for the chosen profile.
# Fail loud on an unknown profile or a plugin pointing at an undeclared
# marketplace key (typo guard).
if ! generated="$(echo "$manifest_json" | jq -e --arg profile "$PROFILE" '
  . as $m
  | ($m.profiles[$profile] // error("unknown profile: \($profile)")) as $plugins
  | ($plugins | map(split("@") | .[1]) | unique) as $keys
  | ($keys | map(select($m.marketplaces[.] == null))) as $missing
  | if ($missing | length) > 0
    then error("profile \($profile) references undeclared marketplace(s): \($missing | join(", "))")
    else . end
  | {
      extraKnownMarketplaces: (
        $keys | map({ key: ., value: { source: { source: "github", repo: $m.marketplaces[.].repo } } }) | from_entries
      ),
      enabledPlugins: ($plugins | map({ key: ., value: true }) | from_entries),
    }
' 2>&1)"; then
  echo "Error: $generated" >&2
  echo "Run 'claude-project-setup.sh --list-profiles' to see valid profiles." >&2
  exit 2
fi

settings_file="$TARGET_DIR/.claude/settings.json"

# Load existing settings (preserve all other keys); start from {} if absent.
existing="{}"
if [ -f "$settings_file" ]; then
  if ! existing="$(read_json "$settings_file" 2> /dev/null)"; then
    echo "Error: $settings_file exists but is not valid JSON; refusing to overwrite." >&2
    exit 1
  fi
fi

# Merge: only touch the two keys we own. Ours win on collision (re-runs refresh
# the recommendation); the user's other entries under those keys survive.
merged="$(echo "$existing" | jq --argjson new "$generated" '
  .extraKnownMarketplaces = ((.extraKnownMarketplaces // {}) * $new.extraKnownMarketplaces)
  | .enabledPlugins = ((.enabledPlugins // {}) * $new.enabledPlugins)
')"

if [ -n "$DRY_RUN" ]; then
  echo "   (dry run -- not writing $settings_file)"
  echo "$merged"
  exit 0
fi

# Write atomically + validate.
mkdir -p "$TARGET_DIR/.claude"
temp_file="$(mktemp)"
echo "$merged" > "$temp_file"
if ! jq empty "$temp_file" 2> /dev/null; then
  echo "Error: generated invalid JSON" >&2
  rm -f "$temp_file"
  exit 1
fi

# Back up an existing file once.
if [ -f "$settings_file" ] && [ ! -f "$settings_file.backup" ]; then
  cp "$settings_file" "$settings_file.backup"
  echo "   ℹ Backed up existing settings to ${settings_file##*/}.backup"
fi

mv "$temp_file" "$settings_file"
echo "   ✓ Wrote $settings_file"

# Nudge: this only helps cloud once it's committed.
if git -C "$TARGET_DIR" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "   → Commit .claude/settings.json so Claude Code on the web picks it up."
else
  echo "   ⚠ $TARGET_DIR isn't a git repo; .claude/settings.json only reaches cloud once committed somewhere."
fi
