#!/usr/bin/env bash
set -e

# shellcheck source=./functions.sh
source ./functions.sh

if ! command_available fortune; then
  echo "Missing fortune command"
  exit 1
fi

if ! command_available strfile; then
  echo "Missing strfile command"
  exit 1
fi

fortunes_dir="$(brew --prefix fortune)/share/games/fortunes/"
echo "Processing fortunes/*.yaml"

for file in fortunes/*.yaml; do
  fortune_basename=$(basename "$file" | sed -e 's/\.yaml$//')
  echo "🔮 Scrying $fortune_basename"
  fortune_file="$fortunes_dir/$fortune_basename"
  # fortune files are \n%\n delimited
  yq ea 'join("\n%\n")' "$file" > "$fortune_file"

  # generate the .dat so fortune can access
  strfile -s "$fortune_file"

  paste <(echo "") <(fortune "$fortune_basename" | fold -w 80)
done
