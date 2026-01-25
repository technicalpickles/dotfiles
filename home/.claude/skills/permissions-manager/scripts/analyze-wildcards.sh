#!/usr/bin/env bash
# Analyze permissions for potentially dangerous wildcards
set -euo pipefail

SETTINGS_FILE="${1:-${HOME}/.claude/settings.json}"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "Error: Settings file not found: $SETTINGS_FILE"
  exit 1
fi

echo "Analyzing wildcards in: $SETTINGS_FILE"
echo ""

# Check for dangerous patterns
echo "=== DANGEROUS WILDCARDS ==="
echo ""

# rm -rf with wildcards
echo "## rm -rf with wildcards (potential multi-path deletion):"
jq -r '.permissions.allow[]? | select(contains("rm -rf") and contains(":*"))' "$SETTINGS_FILE" || echo "  (none found)"
echo ""

# sudo with broad wildcards
echo "## sudo with broad wildcards:"
jq -r '.permissions.allow[]? | select(startswith("Bash(sudo") and endswith(":*"))' "$SETTINGS_FILE" | head -5 || echo "  (none found)"
if jq -r '.permissions.allow[]? | select(startswith("Bash(sudo") and endswith(":*"))' "$SETTINGS_FILE" | wc -l | grep -q -v "^0$"; then
  echo "  ... (review these carefully)"
fi
echo ""

# Pipe to shell
echo "## Pipe to shell (should be in deny, not allow):"
jq -r '.permissions.allow[]? | select(contains("| bash") or contains("| sh"))' "$SETTINGS_FILE" || echo "  (none found - good!)"
echo ""

echo "=== QUESTIONABLE WILDCARDS ==="
echo ""

# chmod/chown in allow (should probably be ask)
echo "## File permission changes in allow (consider ask):"
jq -r '.permissions.allow[]? | select(contains("chmod") or contains("chown"))' "$SETTINGS_FILE" || echo "  (none found)"
echo ""

echo "=== SAFE WILDCARDS ==="
echo ""

# These are generally fine
echo "## Read-only operations (usually safe):"
jq -r '.permissions.allow[]? | select(contains("git log") or contains("git status") or contains("git diff"))' "$SETTINGS_FILE" | head -3 || echo "  (none found)"
echo "  ... (and others)"
echo ""

echo "## Tool-specific arguments (usually safe):"
jq -r '.permissions.allow[]? | select(contains("npm install") or contains("cargo build") or contains("go build"))' "$SETTINGS_FILE" | head -3 || echo "  (none found)"
echo "  ... (and others)"
echo ""

echo "=== SUMMARY ==="
total_allow=$(jq '.permissions.allow | length' "$SETTINGS_FILE")
wildcards=$(jq -r '.permissions.allow[]? | select(endswith(":*"))' "$SETTINGS_FILE" | wc -l)
echo "Total allow entries: $total_allow"
echo "With wildcards:      $wildcards"
echo "Percentage:          $(awk "BEGIN {printf \"%.1f%%\", ($wildcards/$total_allow)*100}")"
