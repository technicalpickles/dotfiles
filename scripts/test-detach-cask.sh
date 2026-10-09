#!/usr/bin/env bash
# Manual verification for scripts/detach-cask.sh against a fake prefix.
#
# Usage:
#   ./scripts/test-detach-cask.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
FAIL=0

check() {
  if eval "$2"; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"
    FAIL=1
  fi
}

P="$TEST_DIR/prefix"
mkdir -p "$P/Caskroom/foo/1.0/.x" "$P/Caskroom/foo/.metadata" "$P/bin" "$P/share/man/man1" "$P/etc/bash_completion.d" "$P/Cellar/other/1.0/bin"
echo '{"uninstall_artifacts":[{"app":["Foo.app"]},{"binary":["x"]}]}' > "$P/Caskroom/foo/.metadata/INSTALL_RECEIPT.json"
ln -s "$P/Caskroom/foo/1.0/foo" "$P/bin/foo"
ln -s "/Applications/Foo.app/Contents/Resources/foo-cli" "$P/bin/foo-cli"
ln -s "$P/Caskroom/foo/1.0/foo.1" "$P/share/man/man1/foo.1"
ln -s "$P/Caskroom/foo/1.0/foo.bash" "$P/etc/bash_completion.d/foo"
ln -s "$P/Cellar/other/1.0/bin/other" "$P/bin/other"
ln -s "/Applications/Foobar.app/Contents/foobar" "$P/bin/foobar"

# --- Test 1: dry run changes nothing and lists the links ---
out="$(HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" foo)"
check "dry run keeps Caskroom" '[ -d "$P/Caskroom/foo" ]'
check "dry run keeps links" '[ -L "$P/bin/foo" ] && [ -L "$P/bin/foo-cli" ]'
check "dry run lists caskroom link" 'grep -q "$P/bin/foo\$" <<< "$out"'
check "dry run lists app link" 'grep -q "$P/bin/foo-cli" <<< "$out"'
check "dry run lists manpage link" 'grep -q "$P/share/man/man1/foo.1" <<< "$out"'
check "dry run lists bash completion link" 'grep -q "$P/etc/bash_completion.d/foo" <<< "$out"'
check "dry run does not list unrelated links" '! grep -qE "bin/(other|foobar)" <<< "$out"'

# --- Test 2: --yes removes the cask's links and Caskroom entry only ---
HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" --yes foo > /dev/null
check "--yes removes Caskroom/foo" '[ ! -e "$P/Caskroom/foo" ]'
check "--yes removes caskroom link" '[ ! -L "$P/bin/foo" ]'
check "--yes removes app link" '[ ! -L "$P/bin/foo-cli" ]'
check "--yes removes manpage link" '[ ! -L "$P/share/man/man1/foo.1" ]'
check "--yes removes bash completion link" '[ ! -L "$P/etc/bash_completion.d/foo" ]'
check "--yes keeps formula link" '[ -L "$P/bin/other" ]'
check "--yes keeps similarly named app link" '[ -L "$P/bin/foobar" ]'

# --- Test 3: unknown cask is skipped, not an error ---
check "unknown cask exits 0" 'HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" --yes nope > /dev/null'

# --- Test 4: no args is a usage error ---
check "no args exits 2" 'HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" > /dev/null 2>&1; [ $? -eq 2 ]'

# --- Test 5: empty token is rejected ---
check "--yes \"\" exits 2" 'HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" --yes "" > /dev/null 2>&1; [ $? -eq 2 ]'

# --- Test 6: .. is rejected ---
check "--yes .. exits 2" 'HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" --yes .. > /dev/null 2>&1; [ $? -eq 2 ]'

# --- Test 7: flag after cask name is rejected ---
mkdir -p "$P/Caskroom/testflag/1.0/.metadata"
echo '{}' > "$P/Caskroom/testflag/1.0/.metadata/INSTALL_RECEIPT.json"
check "foo --yes exits 2" 'HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" testflag --yes > /dev/null 2>&1; [ $? -eq 2 ]'
check "flag error keeps Caskroom" '[ -d "$P/Caskroom/testflag" ]'

# --- Test 8: cask with no receipt is skipped ---
mkdir -p "$P/Caskroom/noreceipt/1.0"
check "no receipt skipped" 'HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" --yes noreceipt 2>&1 | grep -q "skip noreceipt"'
check "no receipt Caskroom survives" '[ -d "$P/Caskroom/noreceipt" ]'

# --- Test 9: malformed receipt is skipped ---
mkdir -p "$P/Caskroom/bad/1.0/.metadata"
echo '{not json' > "$P/Caskroom/bad/1.0/.metadata/INSTALL_RECEIPT.json"
check "malformed receipt skipped" 'HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" --yes bad 2>&1 | grep -q "skip bad"'
check "malformed receipt Caskroom survives" '[ -d "$P/Caskroom/bad" ]'

# --- Test 9b: unparseable receipt where brew writes it: jq's error lands in the skip message ---
mkdir -p "$P/Caskroom/badjson/1.0" "$P/Caskroom/badjson/.metadata"
echo '{not json' > "$P/Caskroom/badjson/.metadata/INSTALL_RECEIPT.json"
out="$(HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" --yes badjson 2> "$TEST_DIR/badjson.err")"
check "bad json: skip message carries jq error" 'grep -q "skip badjson: .*jq failed: .*parse error" "$TEST_DIR/badjson.err"'
check "bad json: jq error not in stdout" '! grep -q "parse error" <<< "$out"'
check "bad json: Caskroom survives" '[ -d "$P/Caskroom/badjson" ]'

# --- Test 10: two casks in one call ---
mkdir -p "$P/Caskroom/two1/1.0" "$P/Caskroom/two2/1.0" "$P/Caskroom/two1/.metadata" "$P/Caskroom/two2/.metadata"
echo '{"uninstall_artifacts":[]}' > "$P/Caskroom/two1/.metadata/INSTALL_RECEIPT.json"
echo '{"uninstall_artifacts":[]}' > "$P/Caskroom/two2/.metadata/INSTALL_RECEIPT.json"
ln -s "$P/Caskroom/two1/1.0/two1" "$P/bin/two1"
ln -s "$P/Caskroom/two2/1.0/two2" "$P/bin/two2"
HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" --yes two1 two2 > /dev/null
check "two casks: first removed" '[ ! -e "$P/Caskroom/two1" ]'
check "two casks: second removed" '[ ! -e "$P/Caskroom/two2" ]'
check "two casks: first link removed" '[ ! -L "$P/bin/two1" ]'
check "two casks: second link removed" '[ ! -L "$P/bin/two2" ]'

exit "$FAIL"
