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

# Restore globally installed skills from the lock file
jq -r '.skills | to_entries[] | .value.source' "$HOME/.agents/.skill-lock.json" | while read -r source; do
  echo "  📦 installing $source"
  npx -y skills add "$source" -g -y
done

echo
