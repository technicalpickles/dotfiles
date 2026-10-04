#!/usr/bin/env bash
# Manual verification for missing_apps() (functions.sh).
#
# Uses temp app dirs via DOTPICKLES_APP_DIRS so real /Applications isn't read.
#
# Usage:
#   ./scripts/test-missing-apps.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTPICKLES_YES=1

# shellcheck source=../functions.sh
source "$REPO_ROOT/functions.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
FAIL=0

assert_eq() {
  if [ "$2" = "$3" ]; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"
    echo "  expected: $(printf '%q' "$2")"
    echo "  actual:   $(printf '%q' "$3")"
    FAIL=1
  fi
}

mkdir -p "$TEST_DIR/Applications/Present.app" "$TEST_DIR/UserApps/In Home.app"
export DOTPICKLES_APP_DIRS="$TEST_DIR/Applications:$TEST_DIR/UserApps"

cat > "$TEST_DIR/Appfile" << 'EOF'
# comment
Present.app | https://example.com/present

  Absent One.app   |   https://example.com/absent
In Home.app | https://example.com/home
EOF
cat > "$TEST_DIR/Appfile.role" << 'EOF'
Also Absent.app | https://example.com/also
EOF

# --- Test 1: reports only absent apps, trimmed, in file order ---
assert_eq "missing_apps reports absent apps" \
  "Absent One.app|https://example.com/absent
Also Absent.app|https://example.com/also" \
  "$(missing_apps "$TEST_DIR/Appfile" "$TEST_DIR/Appfile.role")"

# --- Test 2: an app in the second dir (~/Applications) counts as installed ---
assert_eq "missing_apps checks every app dir" \
  "" \
  "$(missing_apps "$TEST_DIR/Appfile" | grep 'In Home' || true)"

# --- Test 3: missing role Appfile is skipped silently ---
assert_eq "missing_apps skips missing files" \
  "Absent One.app|https://example.com/absent" \
  "$(missing_apps "$TEST_DIR/Appfile" "$TEST_DIR/Appfile.nope" 2>&1)"

# --- Test 4: report_missing_apps prints links, never installs ---
assert_eq "report_missing_apps lists each missing app with its link" \
  "📦 checking Appfile apps
  → missing Absent One.app: install from https://example.com/absent
  → missing Also Absent.app: install from https://example.com/also" \
  "$(cd "$TEST_DIR" && DOTPICKLES_ROLE=role report_missing_apps | sed '/^$/d')"

exit "$FAIL"
