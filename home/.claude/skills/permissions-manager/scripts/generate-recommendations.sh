#!/usr/bin/env bash
# Generate recommendations from aggregated permissions
set -euo pipefail

AGGREGATE_FILE="$1"
OUTPUT_FILE="${2:-recommendations-$(date +%Y%m%d-%H%M%S).md}"

if [[ ! -f "$AGGREGATE_FILE" ]]; then
  echo "Error: Aggregate file not found: $AGGREGATE_FILE"
  exit 1
fi

echo "Generating recommendations from: $AGGREGATE_FILE"
echo "Output: $OUTPUT_FILE"

# Extract sections
extract_section() {
  local section="$1"
  local file="$2"
  awk "/^## $section/,/^## / {print}" "$file" | grep "^[[:space:]]*[0-9]" || echo ""
}

# Parse frequency and command
parse_entries() {
  local input="$1"
  echo "$input" | while read -r line; do
    if [[ -z "$line" ]]; then continue; fi
    freq=$(echo "$line" | awk '{print $1}' | tr -d 'x')
    cmd=$(echo "$line" | cut -d' ' -f2-)
    echo "$freq|$cmd"
  done
}

# Generate markdown
cat > "$OUTPUT_FILE" <<EOF
# Claude Permissions Recommendations

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Analyzer Version**: 1.0.0
**Source**: $(basename "$AGGREGATE_FILE")

## Summary

EOF

# Count current stats
current_allow=$(jq '.permissions.allow | length' ~/.claude/settings.json 2>/dev/null || echo "unknown")
current_ask=$(jq '.permissions.ask | length' ~/.claude/settings.json 2>/dev/null || echo "unknown")
current_deny=$(jq '.permissions.deny | length' ~/.claude/settings.json 2>/dev/null || echo "unknown")

cat >> "$OUTPUT_FILE" <<EOF
| Metric | Count |
|--------|-------|
| Allow  | $current_allow |
| Ask    | $current_ask |
| Deny   | $current_deny |

EOF

# High frequency (4+)
echo "## High-Frequency Patterns (4+ projects)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
extract_section "allow" "$AGGREGATE_FILE" | \
  parse_entries | \
  awk -F'|' '$1 >= 4 {print $2}' | \
  sort -u | \
  while read -r cmd; do
    if [[ -n "$cmd" ]]; then
      echo "- \`$cmd\`" >> "$OUTPUT_FILE"
    fi
  done

if ! grep -q "^- " "$OUTPUT_FILE" | tail -10; then
  echo "(No patterns found)" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Medium frequency (2-3)
echo "## Medium-Frequency Patterns (2-3 projects)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
extract_section "allow" "$AGGREGATE_FILE" | \
  parse_entries | \
  awk -F'|' '$1 >= 2 && $1 <= 3 {print $2}' | \
  sort -u | \
  while read -r cmd; do
    if [[ -n "$cmd" ]]; then
      echo "- \`$cmd\`" >> "$OUTPUT_FILE"
    fi
  done

if ! grep -q "^- " "$OUTPUT_FILE" | tail -20; then
  echo "(No patterns found)" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Deny analysis
echo "## Current Deny Rules" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
extract_section "deny" "$AGGREGATE_FILE" | \
  parse_entries | \
  sort -rn -t'|' -k1 | \
  while IFS='|' read -r freq cmd; do
    if [[ -n "$cmd" ]]; then
      echo "- \`$cmd\` (appears $freq times)" >> "$OUTPUT_FILE"
    fi
  done
echo "" >> "$OUTPUT_FILE"

# Ask analysis
echo "## Current Ask Rules" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
extract_section "ask" "$AGGREGATE_FILE" | \
  parse_entries | \
  sort -rn -t'|' -k1 | \
  while IFS='|' read -r freq cmd; do
    if [[ -n "$cmd" ]]; then
      echo "- \`$cmd\` (appears $freq times)" >> "$OUTPUT_FILE"
    fi
  done
echo "" >> "$OUTPUT_FILE"

# Recommendations section
cat >> "$OUTPUT_FILE" <<EOF
## Recommendations

### 1. Promote to Global Permissions

Consider adding high-frequency patterns to global permission files in \`claude/permissions.*.json\`:

#### Add to \`permissions.shell.json\`:
EOF

# Suggest shell commands
extract_section "allow" "$AGGREGATE_FILE" | \
  parse_entries | \
  awk -F'|' '$1 >= 3 && $2 ~ /^Bash\([a-z]+:/ {print $2}' | \
  grep -v "git\|npm\|cargo\|bundle\|pip" | \
  sort -u | \
  head -10 | \
  while read -r cmd; do
    if [[ -n "$cmd" ]]; then
      echo "- \`$cmd\`" >> "$OUTPUT_FILE"
    fi
  done

cat >> "$OUTPUT_FILE" <<EOF

#### Create New Ecosystem Files:

Check if any of these warrant their own ecosystem file:
EOF

# Look for patterns that might need ecosystem files
extract_section "allow" "$AGGREGATE_FILE" | \
  parse_entries | \
  awk -F'|' '$1 >= 2 {print $2}' | \
  grep -oE "Bash\([a-z]+" | \
  sed 's/Bash(//' | \
  sort | uniq -c | sort -rn | head -10 | \
  awk '{if ($1 >= 3) print "- `permissions." $2 ".json` (" $1 " commands)"}' \
  >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" <<EOF

### 2. Security Improvements

#### Remove Dangerous Wildcards:

Check for these patterns and remove \`:*\` suffix where inappropriate:
EOF

# Find rm -rf with wildcards
jq -r '.permissions.allow[]? | select(contains("rm -rf") and contains(":*"))' ~/.claude/settings.json 2>/dev/null | \
  while read -r perm; do
    echo "- \`$perm\` → Use exact match" >> "$OUTPUT_FILE"
  done || echo "- (No dangerous rm -rf wildcards found)" >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" <<EOF

### 3. Consider Ask Instead of Deny

Review deny rules to see if any should be \`ask\` instead:
EOF

extract_section "deny" "$AGGREGATE_FILE" | \
  parse_entries | \
  grep -v "curl.*|.*bash\|curl.*|.*sh" | \
  head -5 | \
  while IFS='|' read -r freq cmd; do
    if [[ -n "$cmd" ]] && [[ "$freq" -gt 0 ]]; then
      echo "- \`$cmd\` - appears $freq times, consider making it \`ask\`" >> "$OUTPUT_FILE"
    fi
  done

cat >> "$OUTPUT_FILE" <<EOF

### 4. Next Steps

1. Review these recommendations carefully
2. Use \`/permissions-manager apply\` to make changes interactively
3. Run \`./claudeconfig.sh\` to regenerate settings
4. Run \`claude-permissions cleanup\` to remove duplicates
5. Test common workflows to ensure nothing broke

## Notes

- Recommendations are based on frequency analysis
- High-frequency doesn't always mean "should be global"
- Review project-specific patterns carefully
- Consider security implications of each change
EOF

echo "✓ Recommendations generated: $OUTPUT_FILE"
echo ""
echo "Preview:"
head -30 "$OUTPUT_FILE"
echo "..."
