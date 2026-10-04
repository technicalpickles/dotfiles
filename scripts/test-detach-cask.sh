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
mkdir -p "$P/Caskroom/foo/1.0/.x" "$P/Caskroom/foo/.metadata" "$P/bin" "$P/share/man/man1" "$P/Cellar/other/1.0/bin"
echo '{"uninstall_artifacts":[{"app":["Foo.app"]},{"binary":["x"]}]}' > "$P/Caskroom/foo/.metadata/INSTALL_RECEIPT.json"
ln -s "$P/Caskroom/foo/1.0/foo" "$P/bin/foo"
ln -s "/Applications/Foo.app/Contents/Resources/foo-cli" "$P/bin/foo-cli"
ln -s "$P/Caskroom/foo/1.0/foo.1" "$P/share/man/man1/foo.1"
ln -s "$P/Cellar/other/1.0/bin/other" "$P/bin/other"
ln -s "/Applications/Foobar.app/Contents/foobar" "$P/bin/foobar"

# --- Test 1: dry run changes nothing and lists the links ---
out="$(HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" foo)"
check "dry run keeps Caskroom" '[ -d "$P/Caskroom/foo" ]'
check "dry run keeps links" '[ -L "$P/bin/foo" ] && [ -L "$P/bin/foo-cli" ]'
check "dry run lists caskroom link" 'grep -q "$P/bin/foo\$" <<< "$out"'
check "dry run lists app link" 'grep -q "$P/bin/foo-cli" <<< "$out"'
check "dry run lists manpage link" 'grep -q "$P/share/man/man1/foo.1" <<< "$out"'
check "dry run does not list unrelated links" '! grep -qE "bin/(other|foobar)" <<< "$out"'

# --- Test 2: --yes removes the cask's links and Caskroom entry only ---
HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" --yes foo > /dev/null
check "--yes removes Caskroom/foo" '[ ! -e "$P/Caskroom/foo" ]'
check "--yes removes caskroom link" '[ ! -L "$P/bin/foo" ]'
check "--yes removes app link" '[ ! -L "$P/bin/foo-cli" ]'
check "--yes removes manpage link" '[ ! -L "$P/share/man/man1/foo.1" ]'
check "--yes keeps formula link" '[ -L "$P/bin/other" ]'
check "--yes keeps similarly named app link" '[ -L "$P/bin/foobar" ]'

# --- Test 3: unknown cask is skipped, not an error ---
check "unknown cask exits 0" 'HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" --yes nope > /dev/null'

# --- Test 4: no args is a usage error ---
check "no args exits 2" 'HOMEBREW_PREFIX="$P" "$REPO_ROOT/scripts/detach-cask.sh" > /dev/null 2>&1; [ $? -eq 2 ]'

exit "$FAIL"
