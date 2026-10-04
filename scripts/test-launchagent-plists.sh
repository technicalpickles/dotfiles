#!/usr/bin/env bash
# Lint every repo LaunchAgent plist and enforce hardened-Homebrew rules:
#   - plutil must accept it
#   - Label must match the filename
#   - nothing may write into /opt/homebrew/var or /opt/homebrew/etc, which
#     hardened Homebrew makes unwritable for us (see ADR 0058)
#
# Usage:
#   ./scripts/test-launchagent-plists.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

for plist in "$REPO_ROOT"/LaunchAgents/*.plist "$REPO_ROOT"/LaunchAgents/*/*.plist; do
  [ -f "$plist" ] || continue
  name="${plist#"$REPO_ROOT"/}"

  if ! plutil -lint -s "$plist"; then
    echo "FAIL: $name does not lint"
    FAIL=1
    continue
  fi

  label="$(plutil -extract Label raw -o - "$plist" 2> /dev/null)"
  if [ "$label.plist" != "$(basename "$plist")" ]; then
    echo "FAIL: $name has Label '$label', expected '$(basename "$plist" .plist)'"
    FAIL=1
  fi

  if grep -qE '/opt/homebrew/(var|etc)' "$plist"; then
    echo "FAIL: $name references /opt/homebrew/var or /opt/homebrew/etc"
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: all LaunchAgent plists"
fi
exit "$FAIL"
