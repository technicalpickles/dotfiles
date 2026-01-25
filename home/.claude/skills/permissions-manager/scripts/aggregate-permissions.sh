#!/usr/bin/env bash
# Aggregate permissions from all projects
set -euo pipefail

TIMESTAMP=$(date +%s)
OUTPUT_FILE="${1:-/tmp/permissions-aggregate-${TIMESTAMP}.txt}"

echo "Aggregating permissions from all projects..."
echo "Output: $OUTPUT_FILE"

# Run claude-permissions with all relevant flags
claude-permissions --aggregate > "$OUTPUT_FILE"

echo "✓ Aggregation complete"
echo "Total lines: $(wc -l < "$OUTPUT_FILE")"
echo ""
echo "Quick stats:"
echo "  Allow entries: $(grep -c "^[[:space:]]*[0-9]x " "$OUTPUT_FILE" | head -1 || echo 0)"
echo "  Deny entries:  $(awk '/^## deny/,/^## ask/ {print}' "$OUTPUT_FILE" | grep -c "^[[:space:]]*[0-9]x " || echo 0)"
echo "  Ask entries:   $(awk '/^## ask/,/^$/ {print}' "$OUTPUT_FILE" | grep -c "^[[:space:]]*[0-9]x " || echo 0)"
