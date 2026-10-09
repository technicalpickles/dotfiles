#!/usr/bin/env bash
# Manual verification for the Homebrew env set by the zsh startup files
# (home/.zshenv, .zprofile, .zshrc; -c/-lc/-ic/-lic), the fish config chain
# (config/fish, -c/-lic), bash login (home/.bash_profile) and
# load_brew_shellenv (functions.sh, install-time), in both normal and hardened
# (setuid launcher) modes.
#
# Hardened mode is faked with a setuid file we own in a temp dir, pointed to
# by DOTPICKLES_BREW_STUB. Requires /opt/homebrew/bin/brew (Apple Silicon).
# Needs the macOS command sandbox disabled (chmod 4755, ps under brew shellenv).
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

mkdir -p "$TEST_DIR/stub" "$TEST_DIR/plain" "$TEST_DIR/bashhome"
MARKER="$TEST_DIR/stub-called"
printf '#!/bin/sh\necho stub-called >> "%s"\nexit 1\n' "$MARKER" > "$TEST_DIR/stub/brew"
chmod 4755 "$TEST_DIR/stub/brew"
cp "$TEST_DIR/stub/brew" "$TEST_DIR/plain/brew"
chmod 0755 "$TEST_DIR/plain/brew"
# bash login reads ~/.bash_profile; point HOME at a dir that only has ours
ln -s "$REPO_ROOT/home/.bash_profile" "$TEST_DIR/bashhome/.bash_profile"
ln -s "$REPO_ROOT/home/.bashrc" "$TEST_DIR/bashhome/.bashrc"
BASE_PATH="/usr/bin:/bin:/usr/sbin:/sbin"
FISH_BIN="$(command -v fish)"

# $1 = stub path, $2 = zsh flags (-c, -lc, -ic, -lic).
# The stub's dir is compared against /opt/homebrew/bin.
zsh_env() {
  env -i HOME="$HOME" PATH="$BASE_PATH" TERM=dumb DOTPICKLES_BREW_STUB="$1" ZDOTDIR="$REPO_ROOT/home" \
    STUBDIR="$(dirname "$1")" \
    zsh "$2" 'first=; for d in $path; do [[ $d == $STUBDIR || $d == /opt/homebrew/bin ]] && { first=$d; break; }; done; echo "$HOMEBREW_PREFIX|$first|$(whence -p brew)"' 2>&1 | tail -1
}
# $1 = stub path, $2 = fish flags (-c, -lic). Uses the real config chain
# (config.fish + conf.d) via XDG_CONFIG_HOME.
fish_env() {
  env -i HOME="$HOME" PATH="$BASE_PATH" TERM=dumb DOTPICKLES_BREW_STUB="$1" STUBDIR="$(dirname "$1")" \
    XDG_CONFIG_HOME="$REPO_ROOT/config" \
    "$FISH_BIN" "$2" "set first; for d in \$PATH; if test \$d = \$STUBDIR -o \$d = /opt/homebrew/bin; set first \$d; break; end; end; echo \"\$HOMEBREW_PREFIX|\$first|\"(command -s brew)" 2>&1 | tail -1
}
bash_env() {
  env -i HOME="$HOME" PATH="$BASE_PATH" DOTPICKLES_BREW_STUB="$1" STUBDIR="$(dirname "$1")" \
    bash -c "source $REPO_ROOT/functions.sh; load_brew_shellenv; first=; IFS=:; for d in \$PATH; do if [ \"\$d\" = \"\$STUBDIR\" ] || [ \"\$d\" = /opt/homebrew/bin ]; then first=\$d; break; fi; done; unset IFS; echo \"\$HOMEBREW_PREFIX|\$first|\$(command -v brew)\"" 2>&1 | tail -1
}
# bash login shell through home/.bash_profile. Prints BREW_PREFIX (set by
# .bash_profile) instead of HOMEBREW_PREFIX.
bash_login_env() {
  env -i HOME="$TEST_DIR/bashhome" PATH="$BASE_PATH" DOTPICKLES_BREW_STUB="$1" STUBDIR="$(dirname "$1")" \
    bash -lc "first=; IFS=:; for d in \$PATH; do if [ \"\$d\" = \"\$STUBDIR\" ] || [ \"\$d\" = /opt/homebrew/bin ]; then first=\$d; break; fi; done; unset IFS; echo \"\$BREW_PREFIX|\$first|\$(command -v brew)\"" 2>&1 | tail -1
}
marker_state() {
  if [ -e "$MARKER" ]; then echo "stub ran"; else echo "stub not run"; fi
}

# --- Test 1: hardened launcher -> static env, stub dir ahead of /opt/homebrew/bin, stub never run ---
want="/opt/homebrew|$TEST_DIR/stub|$TEST_DIR/stub/brew"
for flags in -c -lc -ic -lic; do
  assert_eq "zsh $flags hardened" "$want" "$(zsh_env "$TEST_DIR/stub/brew" "$flags")"
done
for flags in -c -lic; do
  assert_eq "fish $flags hardened" "$want" "$(fish_env "$TEST_DIR/stub/brew" "$flags")"
done
assert_eq "bash load_brew_shellenv hardened" "$want" "$(bash_env "$TEST_DIR/stub/brew")"
assert_eq "bash -lc hardened" "$want" "$(bash_login_env "$TEST_DIR/stub/brew")"
assert_eq "hardened shells never ran the stub" "stub not run" "$(marker_state)"

# --- Test 2: no launcher -> unchanged /opt/homebrew behavior ---
want="/opt/homebrew|/opt/homebrew/bin|/opt/homebrew/bin/brew"
for flags in -c -lc -ic -lic; do
  assert_eq "zsh $flags normal" "$want" "$(zsh_env "$TEST_DIR/missing/brew" "$flags")"
done
for flags in -c -lic; do
  assert_eq "fish $flags normal" "$want" "$(fish_env "$TEST_DIR/missing/brew" "$flags")"
done
assert_eq "bash load_brew_shellenv normal" "$want" "$(bash_env "$TEST_DIR/missing/brew")"
assert_eq "bash -lc normal" "$want" "$(bash_login_env "$TEST_DIR/missing/brew")"

# --- Test 3: non-setuid brew at the launcher path (Intel/Rosetta brew) -> not hardened ---
for flags in -c -lc -ic -lic; do
  assert_eq "zsh $flags ignores non-setuid brew" "$want" "$(zsh_env "$TEST_DIR/plain/brew" "$flags")"
done
for flags in -c -lic; do
  assert_eq "fish $flags ignores non-setuid brew" "$want" "$(fish_env "$TEST_DIR/plain/brew" "$flags")"
done
assert_eq "bash ignores non-setuid brew" "$want" "$(bash_env "$TEST_DIR/plain/brew")"
assert_eq "bash -lc ignores non-setuid brew" "$want" "$(bash_login_env "$TEST_DIR/plain/brew")"

exit "$FAIL"
