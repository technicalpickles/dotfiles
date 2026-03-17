#!/usr/bin/env bash
# Redact project names and private information from permission analysis
set -euo pipefail

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE}.redacted}"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: Input file not found: $INPUT_FILE"
  exit 1
fi

echo "Redacting private information from: $INPUT_FILE"
echo "Output: $OUTPUT_FILE"

# Get list of project directories (directories in workspace)
WORKSPACE_DIR="${HOME}/workspace"
declare -A project_map

if [[ -d "$WORKSPACE_DIR" ]]; then
  counter=1
  while IFS= read -r -d '' dir; do
    project_name=$(basename "$dir")
    # Skip common non-project directories
    if [[ "$project_name" != ".git" ]] && \
       [[ "$project_name" != "node_modules" ]] && \
       [[ "$project_name" != ".DS_Store" ]]; then
      project_map["$project_name"]="Project-$(printf "%02d" $counter)"
      ((counter++))
    fi
  done < <(find "$WORKSPACE_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
fi

# Create redacted output
cp "$INPUT_FILE" "$OUTPUT_FILE"

# Redact project names
for project in "${!project_map[@]}"; do
  redacted="${project_map[$project]}"
  # Use perl for in-place editing with proper escaping
  perl -i -pe "s/\Q$project\E/$redacted/g" "$OUTPUT_FILE"
done

# Redact common private patterns
perl -i -pe 's|~/workspace/[^/\s]+|<project-dir>|g' "$OUTPUT_FILE"
perl -i -pe 's|/Users/[^/\s]+/workspace|<workspace>|g' "$OUTPUT_FILE"
perl -i -pe 's|/Users/[^/\s]+|<home>|g' "$OUTPUT_FILE"

# Redact internal domains (keep common ones)
perl -i -pe 's/([a-z0-9-]+\.)(internal|corp|local)\b/$1<internal>/g' "$OUTPUT_FILE"

# Redact API keys and tokens (just in case)
perl -i -pe 's/[A-Za-z0-9]{32,}/<REDACTED>/g' "$OUTPUT_FILE"

echo "✓ Redaction complete"
echo "Total substitutions: $(grep -o "<project-dir>\|<workspace>\|<home>\|<internal>\|<REDACTED>" "$OUTPUT_FILE" | wc -l)"
