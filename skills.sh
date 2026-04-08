#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./functions.sh
source ./functions.sh

echo "🧩 configuring agent skills"

mkdir -p "$HOME/.agents"
link "agents/.skill-lock.json" "$HOME/.agents/.skill-lock.json"

if ! command -v npx &>/dev/null; then
  echo "  ⚠ npx not found, skipping skill restoration"
  exit 0
fi

LOCK_FILE="$HOME/.agents/.skill-lock.json"

# Restore GitHub-sourced skills (simple: one skill per source)
jq -r '.skills | to_entries[] | select(.value.sourceType == "github") | .value.source' "$LOCK_FILE" | while read -r source; do
  echo "  📦 installing $source (github)"
  npx -y skills add "$source" -g -y
done

# Restore git-sourced skills (grouped by sourceUrl, with -s flags per skill)
# Skip LFS smudge since remote repos may have LFS objects we don't need
jq -r '
  [.skills | to_entries[] | select(.value.sourceType == "git")]
  | group_by(.value.sourceUrl)[]
  | { url: .[0].value.sourceUrl, skills: [.[].key] }
  | @json
' "$LOCK_FILE" | while read -r group; do
  url=$(echo "$group" | jq -r '.url')
  mapfile -t skill_names < <(echo "$group" | jq -r '.skills[]')

  skill_flags=""
  for name in "${skill_names[@]}"; do
    skill_flags="$skill_flags -s $name"
  done

  echo "  📦 installing ${skill_names[*]} from $url"
  # shellcheck disable=SC2086
  GIT_LFS_SKIP_SMUDGE=1 npx -y skills add "$url" $skill_flags -g -y
done

echo
