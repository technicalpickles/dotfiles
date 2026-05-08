#!/usr/bin/env bash
# Manual verification for safe link() function.
#
# Usage:
#   ./scripts/test-link.sh          # interactive tests
#   ./scripts/test-link.sh --yes    # auto-yes tests

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DIR

for arg in "$@"; do
  case "$arg" in
    --yes | -y) export DOTPICKLES_YES=1 ;;
  esac
done

source "$DIR/functions.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

echo "=== Test directory: $TEST_DIR ==="
echo

# Test 1: target doesn't exist -> creates symlink
echo "--- Test 1: target doesn't exist ---"
mkdir -p "$TEST_DIR/source/thing"
echo "hello" > "$TEST_DIR/source/thing/file.txt"
link "source/thing" "$TEST_DIR/result1"
if [ -L "$TEST_DIR/result1" ]; then
  echo "PASS: symlink created"
else
  echo "FAIL: expected symlink at $TEST_DIR/result1"
fi
echo

# Test 2: correct symlink -> no-op
echo "--- Test 2: correct symlink (no-op) ---"
link "source/thing" "$TEST_DIR/result1"
echo "PASS: no error on re-link"
echo

# Test 3: wrong symlink -> prompt/auto-replace
echo "--- Test 3: wrong symlink ---"
ln -s "/nonexistent/old/path" "$TEST_DIR/result3"
link "source/thing" "$TEST_DIR/result3"
if [ -L "$TEST_DIR/result3" ] && [ "$(readlink "$TEST_DIR/result3")" = "$DIR/source/thing" ]; then
  echo "PASS: symlink repointed"
else
  echo "INFO: symlink not repointed (expected if you answered 'n')"
fi
echo

# Test 4: real directory -> prompt/auto-backup-and-replace
echo "--- Test 4: real directory exists ---"
mkdir -p "$TEST_DIR/result4"
echo "precious data" > "$TEST_DIR/result4/config.json"
link "source/thing" "$TEST_DIR/result4"
if [ -L "$TEST_DIR/result4" ]; then
  echo "PASS: directory replaced with symlink"
  backup=$(ls -d "$TEST_DIR"/result4.backup.* 2> /dev/null | head -1)
  if [ -n "$backup" ] && [ -f "$backup/config.json" ]; then
    echo "PASS: backup exists with original content"
  else
    echo "FAIL: backup missing or incomplete"
  fi
else
  echo "INFO: directory not replaced (expected if you answered 'n')"
fi
echo

# Test 5: real file -> prompt/auto-backup-and-replace
echo "--- Test 5: real file exists ---"
echo "important stuff" > "$TEST_DIR/result5"
link "source/thing" "$TEST_DIR/result5"
if [ -L "$TEST_DIR/result5" ]; then
  echo "PASS: file replaced with symlink"
  backup=$(ls "$TEST_DIR"/result5.backup.* 2> /dev/null | head -1)
  if [ -n "$backup" ]; then
    echo "PASS: backup exists"
  else
    echo "FAIL: backup missing"
  fi
else
  echo "INFO: file not replaced (expected if you answered 'n')"
fi
echo

# Test 6: no nested symlinks
echo "--- Test 6: no nested symlinks ---"
mkdir -p "$TEST_DIR/result6"
DOTPICKLES_YES=1 link "source/thing" "$TEST_DIR/result6"
if [ -L "$TEST_DIR/result6" ] && [ ! -e "$TEST_DIR/result6/thing" ]; then
  echo "PASS: no nested symlink"
else
  echo "FAIL: nested symlink detected or replacement failed"
fi
echo

echo "=== Done ==="
