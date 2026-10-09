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
      [ -n "${BREW_INFO_FAIL:-}" ] && return 1
      if [[ " $* " == *" --cask "* ]]; then
        cat "$TEST_DIR/cask.json"
      else
        cat "$TEST_DIR/formula.json"
      fi
      ;;
    install)
      [[ " $* " == *" ${BREW_INSTALL_FAIL:---none--} "* ]] && return 1
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
brew tap markjaquith/tap
brew info --json=v2 --formula gpg jq markjaquith/tap/cowtree
brew install --formula jq markjaquith/tap/cowtree
brew info --json=v2 --cask 1password-cli
brew install --cask mitmproxy" \
  "$(cat "$CALLS")"

# --- Test 6: failure paths never abort a caller running under set -e ---
(
  set -eo pipefail
  : > "$TEST_DIR/stderr"
  got="$(BREW_INFO_FAIL=1 missing_brew_packages formula gpg jq 2> "$TEST_DIR/stderr")"
  assert_eq "brew info failure reports every name" "gpg
jq" "$got"
  assert_eq "brew info failure warns on stderr" \
    "  → warning: brew info failed for formula entries; installing all of them" \
    "$(cat "$TEST_DIR/stderr")"
  exit "$FAIL"
) || FAIL=1

# --- Test 7: implicit tap, and case-insensitive tap match ---
mkdir "$TEST_DIR/t7"
cat > "$TEST_DIR/t7/Brewfile" << 'EOF'
tap 'Existing/Tap'
brew 'someuser/somerepo/thing'
EOF
: > "$CALLS"
(
  set -eo pipefail
  cd "$TEST_DIR/t7" && DOTPICKLES_ROLE=nope brew_install_brewfiles > /dev/null
) || FAIL=1
assert_eq "implicit tap is tapped; mixed-case installed tap is not re-tapped" \
  "brew tap someuser/somerepo" \
  "$(grep '^brew tap .' "$CALLS")"

# --- Test 8: install failure warns, continues, returns non-zero ---
: > "$CALLS"
(
  set -eo pipefail
  cd "$TEST_DIR" && DOTPICKLES_ROLE=nope BREW_INSTALL_FAIL=--formula brew_install_brewfiles > "$TEST_DIR/out"
) && rc=0 || rc=$?
assert_eq "failed install returns non-zero" "1" "$rc"
assert_eq "failed install warns" "1" "$(grep -c 'warning: brew install --formula failed' "$TEST_DIR/out")"
assert_eq "cask step still runs after formula failure" "1" "$(grep -c '^brew install --cask' "$CALLS")"

exit "$FAIL"
