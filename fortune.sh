#!/usr/bin/env bash
set -e

fortunes_dir="$(brew --prefix fortune)/share/games/fortunes/"
echo "Processing fortunes/*.yaml"

for file in fortunes/*.yaml; do
  fortune_basename=$(basename "$file" | sed -e 's/\.yaml$//')
  echo "🔮 Scrying $fortune_basename"
  fortune_file="$fortunes_dir/$fortune_basename"
  yq ea  'join("\n%\n")' "$file" > "$fortune_file"

  strfile -s "$fortune_file"

  paste <(echo "") <(fortune "$fortune_basename" | fold -sw 80)
done
