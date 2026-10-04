#!/usr/bin/env bash
# Manual verification for the Homebrew env set by home/.zshenv,
# config/fish/conf.d/__homebrew.fish, and load_brew_shellenv (functions.sh),
# in both normal and hardened (setuid launcher) modes.
#
# Hardened mode is faked with a setuid file we own in a temp dir, pointed to
# by DOTPICKLES_BREW_STUB. Requires /opt/homebrew/bin/brew (Apple Silicon).
#
# Each shell prints: HOMEBREW_PREFIX|<first of stub dir and /opt/homebrew/bin on PATH>|<resolved brew>
# (other dirs like ~/bin legitimately sit ahead of both, so only their relative order is checked)
#
# Usage:
#   ./scripts/test-brew-shellenv.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
FAIL=0

assert_eq() {
  if [ "$2" = "$3" ]; then
    echo "PASS: $1"
  else
    echo "FAIL: $1"
    echo "  expected: $2"
    echo "  actual:   $3"
    FAIL=1
  fi
}

mkdir -p "$TEST_DIR/stub" "$TEST_DIR/plain"
printf '#!/bin/sh\necho stub-called >&2\nexit 1\n' > "$TEST_DIR/stub/brew"
chmod 4755 "$TEST_DIR/stub/brew"
cp "$TEST_DIR/stub/brew" "$TEST_DIR/plain/brew"
chmod 0755 "$TEST_DIR/plain/brew"
BASE_PATH="/usr/bin:/bin:/usr/sbin:/sbin"
FISH_BIN="$(command -v fish)"

# $1 = stub path. The stub's dir is compared against /opt/homebrew/bin.
zsh_env() {
  env -i HOME="$HOME" PATH="$BASE_PATH" DOTPICKLES_BREW_STUB="$1" ZDOTDIR="$REPO_ROOT/home" \
    STUBDIR="$(dirname "$1")" \
    zsh -c 'first=; for d in $path; do [[ $d == $STUBDIR || $d == /opt/homebrew/bin ]] && { first=$d; break; }; done; echo "$HOMEBREW_PREFIX|$first|$(whence -p brew)"' 2>&1 | tail -1
}
fish_env() {
  env -i HOME="$HOME" PATH="$BASE_PATH" DOTPICKLES_BREW_STUB="$1" STUBDIR="$(dirname "$1")" \
    "$FISH_BIN" --no-config -c "source $REPO_ROOT/config/fish/conf.d/__homebrew.fish; set first; for d in \$PATH; if test \$d = \$STUBDIR -o \$d = /opt/homebrew/bin; set first \$d; break; end; end; echo \"\$HOMEBREW_PREFIX|\$first|\"(command -s brew)" 2>&1 | tail -1
}
bash_env() {
  env -i HOME="$HOME" PATH="$BASE_PATH" DOTPICKLES_BREW_STUB="$1" STUBDIR="$(dirname "$1")" \
    bash -c "source $REPO_ROOT/functions.sh; load_brew_shellenv; first=; IFS=:; for d in \$PATH; do if [ \"\$d\" = \"\$STUBDIR\" ] || [ \"\$d\" = /opt/homebrew/bin ]; then first=\$d; break; fi; done; unset IFS; echo \"\$HOMEBREW_PREFIX|\$first|\$(command -v brew)\"" 2>&1 | tail -1
}

# --- Test 1: hardened launcher -> static env, stub dir ahead of /opt/homebrew/bin, stub never run ---
want="/opt/homebrew|$TEST_DIR/stub|$TEST_DIR/stub/brew"
assert_eq "zsh hardened" "$want" "$(zsh_env "$TEST_DIR/stub/brew")"
assert_eq "fish hardened" "$want" "$(fish_env "$TEST_DIR/stub/brew")"
assert_eq "bash load_brew_shellenv hardened" "$want" "$(bash_env "$TEST_DIR/stub/brew")"

# --- Test 2: no launcher -> unchanged /opt/homebrew behavior ---
want="/opt/homebrew|/opt/homebrew/bin|/opt/homebrew/bin/brew"
assert_eq "zsh normal" "$want" "$(zsh_env "$TEST_DIR/missing/brew")"
assert_eq "fish normal" "$want" "$(fish_env "$TEST_DIR/missing/brew")"
assert_eq "bash load_brew_shellenv normal" "$want" "$(bash_env "$TEST_DIR/missing/brew")"

# --- Test 3: non-setuid brew at the launcher path (Intel/Rosetta brew) -> not hardened ---
assert_eq "zsh ignores non-setuid brew" "$want" "$(zsh_env "$TEST_DIR/plain/brew")"
assert_eq "fish ignores non-setuid brew" "$want" "$(fish_env "$TEST_DIR/plain/brew")"
assert_eq "bash ignores non-setuid brew" "$want" "$(bash_env "$TEST_DIR/plain/brew")"

exit "$FAIL"
