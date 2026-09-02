#!/usr/bin/env bash
# Manual verification for repoint_dangling_launchagents() (functions.sh).
#
# Uses a temp $HOME/Library/LaunchAgents and a temp fake $DIR (repo root) so no
# real LaunchAgents state is touched. Stubs launchctl for the same reason.
#
# Usage:
#   ./scripts/test-repoint-dangling-launchagents.sh

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Auto-yes: this harness is non-interactive and link() prompts on a
# repointed/wrong symlink.
export DOTPICKLES_YES=1

# Stub launchctl so the harness never touches real launchd state.
launchctl() {
  echo "  (stub) launchctl $*"
  return 0
}

# shellcheck source=../functions.sh
source "$REPO_ROOT/functions.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

echo "=== Test directory: $TEST_DIR ==="
echo

# --- Test 1: dangling symlink, matching plist still at the top level -> repointed ---
echo "--- Test 1: dangling symlink, plist found at top level ---"
export DIR="$TEST_DIR/repo1"
export HOME="$TEST_DIR/home1"
mkdir -p "$DIR/LaunchAgents" "$HOME/Library/LaunchAgents"
echo "<plist/>" > "$DIR/LaunchAgents/com.example.foo.plist"
ln -s "$DIR/LaunchAgents/old-location/com.example.foo.plist" "$HOME/Library/LaunchAgents/com.example.foo.plist"

repoint_dangling_launchagents

resolved="$(readlink "$HOME/Library/LaunchAgents/com.example.foo.plist")"
if [ "$resolved" = "$DIR/LaunchAgents/com.example.foo.plist" ]; then
  echo "PASS: dangling symlink repointed to current repo plist"
else
  echo "FAIL: expected repoint to $DIR/LaunchAgents/com.example.foo.plist, got $resolved"
fi
echo

# --- Test 2: dangling symlink, plist only under arm64-macos/ -> repointed via fallback ---
echo "--- Test 2: dangling symlink, plist found via arm64-macos fallback ---"
export DIR="$TEST_DIR/repo2"
export HOME="$TEST_DIR/home2"
mkdir -p "$DIR/LaunchAgents/arm64-macos" "$HOME/Library/LaunchAgents"
echo "<plist/>" > "$DIR/LaunchAgents/arm64-macos/com.example.bar.plist"
ln -s "$DIR/LaunchAgents/com.example.bar.plist" "$HOME/Library/LaunchAgents/com.example.bar.plist"

# Force the arm64 branch regardless of the machine actually running this
# harness -- running_arm64_macos shells out to `uname -m`, which we can't
# fake portably, so override the function itself in a subshell, scoped to
# this one test only.
(
  # shellcheck disable=SC2329 # invoked indirectly, from repoint_dangling_launchagents
  running_arm64_macos() { return 0; }
  repoint_dangling_launchagents
)

resolved="$(readlink "$HOME/Library/LaunchAgents/com.example.bar.plist")"
if [ "$resolved" = "$DIR/LaunchAgents/arm64-macos/com.example.bar.plist" ]; then
  echo "PASS: dangling symlink repointed via arm64-macos fallback"
else
  echo "FAIL: expected repoint to $DIR/LaunchAgents/arm64-macos/com.example.bar.plist, got $resolved"
fi
echo

# --- Test 3: dangling symlink, no matching plist anywhere -> left alone ---
echo "--- Test 3: dangling symlink, no matching repo plist ---"
export DIR="$TEST_DIR/repo3"
export HOME="$TEST_DIR/home3"
mkdir -p "$DIR/LaunchAgents" "$HOME/Library/LaunchAgents"
ln -s "$DIR/LaunchAgents/gone/com.example.baz.plist" "$HOME/Library/LaunchAgents/com.example.baz.plist"

output="$(repoint_dangling_launchagents 2>&1)"

if [ -L "$HOME/Library/LaunchAgents/com.example.baz.plist" ] && [ ! -e "$HOME/Library/LaunchAgents/com.example.baz.plist" ]; then
  echo "PASS: unmatched dangling symlink left in place (still dangling, not deleted)"
else
  echo "FAIL: unmatched dangling symlink was modified or removed"
fi

if echo "$output" | grep -q "no applicable repo plist found"; then
  echo "PASS: warning printed for unmatched dangling symlink"
else
  echo "FAIL: expected warning about no applicable repo plist, got: $output"
fi
echo

# --- Test 4: dangling symlink, plist exists at BOTH top level and arm64-macos/ -> arm64-macos wins ---
echo "--- Test 4: dangling symlink, plist in both locations, arm64-macos takes precedence ---"
export DIR="$TEST_DIR/repo4"
export HOME="$TEST_DIR/home4"
mkdir -p "$DIR/LaunchAgents/arm64-macos" "$HOME/Library/LaunchAgents"
echo "<plist/>" > "$DIR/LaunchAgents/com.example.qux.plist"
echo "<plist/>" > "$DIR/LaunchAgents/arm64-macos/com.example.qux.plist"
ln -s "$DIR/LaunchAgents/old-location/com.example.qux.plist" "$HOME/Library/LaunchAgents/com.example.qux.plist"

# Force the arm64 branch, same technique as Test 2.
(
  # shellcheck disable=SC2329 # invoked indirectly, from repoint_dangling_launchagents
  running_arm64_macos() { return 0; }
  repoint_dangling_launchagents
)

resolved="$(readlink "$HOME/Library/LaunchAgents/com.example.qux.plist")"
if [ "$resolved" = "$DIR/LaunchAgents/arm64-macos/com.example.qux.plist" ]; then
  echo "PASS: dangling symlink repointed to arm64-macos plist (matches symlinks.sh link order)"
else
  echo "FAIL: expected repoint to $DIR/LaunchAgents/arm64-macos/com.example.qux.plist, got $resolved"
fi
echo

# --- Test 5: two dangling symlinks in one invocation, matched then unmatched ---
# Regression test for a bug where `local name current_repo_path` (bare
# re-declaration, no assignment) failed to reset current_repo_path between
# loop iterations, so the second (unmatched) symlink silently inherited the
# first (matched) symlink's resolved path instead of being reported as
# unmatched. Glob order matters here: com.example.aaa sorts before
# com.example.zzz, so aaa (matched) is processed first and zzz (unmatched)
# second -- the exact order that exposed the bug.
echo "--- Test 5: multiple dangling symlinks, matched then unmatched, in one call ---"
export DIR="$TEST_DIR/repo5"
export HOME="$TEST_DIR/home5"
mkdir -p "$DIR/LaunchAgents" "$HOME/Library/LaunchAgents"
echo "<plist/>" > "$DIR/LaunchAgents/com.example.aaa.plist"
ln -s "$DIR/LaunchAgents/old-location/com.example.aaa.plist" "$HOME/Library/LaunchAgents/com.example.aaa.plist"
ln -s "$DIR/LaunchAgents/gone/com.example.zzz.plist" "$HOME/Library/LaunchAgents/com.example.zzz.plist"

output="$(repoint_dangling_launchagents 2>&1)"

resolved_aaa="$(readlink "$HOME/Library/LaunchAgents/com.example.aaa.plist")"
if [ "$resolved_aaa" = "$DIR/LaunchAgents/com.example.aaa.plist" ]; then
  echo "PASS: matched symlink (aaa) repointed to its own repo plist"
else
  echo "FAIL: expected aaa repoint to $DIR/LaunchAgents/com.example.aaa.plist, got $resolved_aaa"
fi

resolved_zzz="$(readlink "$HOME/Library/LaunchAgents/com.example.zzz.plist")"
if [ "$resolved_zzz" = "$DIR/LaunchAgents/gone/com.example.zzz.plist" ] && [ ! -e "$HOME/Library/LaunchAgents/com.example.zzz.plist" ]; then
  echo "PASS: unmatched symlink (zzz) left dangling, not repointed to aaa's target"
else
  echo "FAIL: unmatched symlink (zzz) was repointed (got $resolved_zzz), expected to remain dangling at its original target"
fi

if echo "$output" | grep -q "com.example.zzz.plist -> dangling, no applicable repo plist found"; then
  echo "PASS: warning printed for the unmatched symlink (zzz)"
else
  echo "FAIL: expected warning about zzz having no applicable repo plist, got: $output"
fi
echo

echo "=== Done ==="
