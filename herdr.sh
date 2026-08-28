#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./functions.sh
source ./functions.sh

echo "🐑 configuring herdr plugins"

if ! command_available herdr; then
  echo "  ⚠ herdr not found, skipping plugin restoration"
  exit 0
fi

MANIFEST="$DIR/config/herdr/plugins.toml"

installed_ids="$(herdr plugin list --json | jq -r '.result.plugins[].plugin_id')"

yq -p toml -o json '.plugin' "$MANIFEST" | jq -c '.[]' | while read -r entry; do
  id="$(jq -r '.id' <<< "$entry")"

  if grep -qx "$id" <<< "$installed_ids"; then
    echo "  🔌 $id -> already installed"
    continue
  fi

  github="$(jq -r '.github // empty' <<< "$entry")"
  ref="$(jq -r '.ref // empty' <<< "$entry")"
  local_path="$(jq -r '.local // empty' <<< "$entry")"

  if [ -n "$github" ]; then
    if [ -n "$ref" ]; then
      echo "  🔌 $id -> installing from github:$github@$ref"
      herdr plugin install "$github" --ref "$ref" --yes
    else
      echo "  🔌 $id -> installing from github:$github"
      herdr plugin install "$github" --yes
    fi
  elif [ -n "$local_path" ]; then
    expanded="${local_path/#\~/$HOME}"
    echo "  🔌 $id -> linking local $expanded"
    herdr plugin link "$expanded"
  else
    echo "  ⚠ $id -> no source declared in plugins.toml, skipping" >&2
  fi
done

echo
