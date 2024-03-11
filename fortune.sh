#/usr/bin/env bash
set -e

fortunes_dir="$(brew --prefix fortune)/share/games/fortunes/"
echo "Processing fortunes/*.yaml"

for file in fortunes/*.yaml; do
  echo "Found $file"
  fortune_basename=$(basename "$file" | sed -e 's/\.yaml$//')
  echo "Generating $fortune_file it"
  fortune_file="$fortunes_dir/$fortune_basename"
  yq ea  'join("\n%\n")' "$file" > "$fortune_file"

  strfile "$fortune_file"
  echo "Making sure it works..."
  fortune $fortune_basename
done
