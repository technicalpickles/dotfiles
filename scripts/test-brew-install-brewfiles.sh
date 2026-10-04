#!/usr/bin/env bash
# Manual verification for brew_install_brewfiles() and helpers (functions.sh).
#
# Stubs `brew` so no real Homebrew state is read or changed.
#
# Usage:
#   ./scripts/test-brew-install-brewfiles.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTPICKLES_YES=1

# shellcheck source=../functions.sh
source "$REPO_ROOT/functions.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
CALLS="$TEST_DIR/calls"
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

# brew stub: logs every call; `brew tap` lists installed taps; `brew info`
# returns fixture JSON.
brew() {
  echo "brew $*" >> "$CALLS"
  case "$1" in
    tap) [ $# -eq 1 ] && printf '%s\n' homebrew/core existing/tap ;;
    info)
      if [[ " $* " == *" --cask "* ]]; then
        cat "$TEST_DIR/cask.json"
      else
        cat "$TEST_DIR/formula.json"
      fi
      ;;
  esac
  return 0
}

cat > "$TEST_DIR/formula.json" << 'EOF'
{"formulae":[
  {"full_name":"gnupg","installed":[{"version":"2.4.5"}]},
  {"full_name":"jq","installed":[]},
  {"full_name":"markjaquith/tap/cowtree","installed":[]}
],"casks":[]}
EOF
cat > "$TEST_DIR/cask.json" << 'EOF'
{"formulae":[],"casks":[
  {"full_token":"1password-cli","installed":"2.30.0"},
  {"full_token":"mitmproxy","installed":null}
]}
EOF

# --- Test 1: Brewfile parsing ---
cat > "$TEST_DIR/Brewfile" << 'EOF'
# frozen_string_literal: true
# core
brew 'gpg' # comment after
#brew 'specstory'
  brew "jq"

tap 'existing/tap'
tap "new/tap"
brew 'markjaquith/tap/cowtree' # with a tap
cask '1password-cli'
cask_args appdir: '~/Applications'
EOF
assert_eq "brewfile_entries parses live tap/brew/cask lines only" \
  "brew gpg
brew jq
tap existing/tap
tap new/tap
brew markjaquith/tap/cowtree
cask 1password-cli" \
  "$(brewfile_entries "$TEST_DIR/Brewfile")"

# --- Test 2: missing role Brewfile is skipped silently ---
assert_eq "brewfile_entries skips missing files" \
  "$(brewfile_entries "$TEST_DIR/Brewfile")" \
  "$(brewfile_entries "$TEST_DIR/Brewfile" "$TEST_DIR/Brewfile.nope" 2>&1)"

# --- Test 3: aliases resolve; only uninstalled names come back ---
: > "$CALLS"
assert_eq "missing_brew_packages reports only uninstalled formulae" \
  "jq
markjaquith/tap/cowtree" \
  "$(missing_brew_packages formula gpg jq markjaquith/tap/cowtree)"
assert_eq "missing_brew_packages reports only uninstalled casks" \
  "mitmproxy" \
  "$(missing_brew_packages cask 1password-cli mitmproxy)"
assert_eq "missing_brew_packages with no names makes no brew call" \
  "" \
  "$(
    : > "$CALLS"
    missing_brew_packages formula
    cat "$CALLS"
  )"

# --- Test 4: no jq -> every name is reported ---
(
  command_available() { [ "$1" != jq ] && command -v "$1" > /dev/null 2>&1; }
  assert_eq "missing_brew_packages without jq echoes every name" \
    "gpg
jq" \
    "$(missing_brew_packages formula gpg jq)"
  exit "$FAIL"
) || FAIL=1

# --- Test 5: end to end ---
: > "$CALLS"
(
  cd "$TEST_DIR" && DOTPICKLES_ROLE=nope brew_install_brewfiles > /dev/null
)
assert_eq "brew_install_brewfiles taps only missing taps, installs once per kind" \
  "brew tap
brew tap new/tap
brew info --json=v2 --formula gpg jq markjaquith/tap/cowtree
brew install --formula jq markjaquith/tap/cowtree
brew info --json=v2 --cask 1password-cli
brew install --cask mitmproxy" \
  "$(cat "$CALLS")"

exit "$FAIL"
