#!/usr/bin/env bash
# Verify the agent git configs never write upstream tracking into .git/config,
# while interactive git still does. Runs in CI and locally.
#
# Usage:
#   ./scripts/test-agent-gitconfig.sh
#
# Builds a fake HOME whose .gitconfig and .gitconfig.d link to this checkout's
# home/, so every include (common, claude-agent-common, ...) resolves to the
# files under review, not whatever is installed on the machine.

set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

FAKEHOME="$TEST_DIR/fakehome"
mkdir -p "$FAKEHOME"
ln -s "$DIR/home/.gitconfig.d" "$FAKEHOME/.gitconfig.d"
ln -s "$DIR/home/.gitconfig" "$FAKEHOME/.gitconfig"

export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

fail=0
pass() { echo "PASS: $1"; }
fail() {
  echo "FAIL: $1"
  fail=1
}

# Seed a remote with main and one extra branch to track.
cd "$TEST_DIR"
GIT_CONFIG_GLOBAL=/dev/null git init -q --bare -b main remote.git
GIT_CONFIG_GLOBAL=/dev/null git init -q -b main seed
(
  cd seed
  echo hi > f && git add f
  GIT_CONFIG_GLOBAL=/dev/null git -c commit.gpgsign=false commit -qm init
  GIT_CONFIG_GLOBAL=/dev/null git push -q ../remote.git main main:existing
)

# expect_config <label> <key> <expected|unset> <env...>
expect_config() {
  local label=$1 key=$2 expected=$3
  shift 3
  local actual
  actual=$(env "$@" git config --get "$key" 2> /dev/null || echo unset)
  if [ "$actual" = "$expected" ]; then
    pass "$label: $key = $expected"
  else
    fail "$label: $key = $actual (expected $expected)"
  fi
}

# scenario <label> <expect-tracking: yes|no> <env...>
# Clones, creates a branch and pushes it, then creates a branch from
# origin/existing. Checks whether .git/config gained [branch] sections.
scenario() {
  local label=$1 expect=$2
  shift 2
  local clone="$TEST_DIR/clone-$label"
  env "$@" git clone -q "$TEST_DIR/remote.git" "$clone"
  cp "$clone/.git/config" "$TEST_DIR/before-$label"
  (
    cd "$clone"
    env "$@" git switch -q -c "x-$label"
    env "$@" git -c commit.gpgsign=false push -q origin 2> /dev/null
    env "$@" git switch -q -c y origin/existing 2> /dev/null
  )
  local wrote=no
  if ! diff -q "$TEST_DIR/before-$label" "$clone/.git/config" > /dev/null; then
    wrote=yes
  fi
  if [ "$wrote" = "$expect" ]; then
    pass "$label: tracking written = $wrote"
  else
    fail "$label: tracking written = $wrote (expected $expect)"
    diff "$TEST_DIR/before-$label" "$clone/.git/config" | sed 's/^/    /'
  fi
}

for role in home work; do
  agent=(HOME="$FAKEHOME" GIT_CONFIG_GLOBAL="$FAKEHOME/.gitconfig.d/claude-agent-$role")
  expect_config "claude-agent-$role" push.autosetupremote unset "${agent[@]}"
  expect_config "claude-agent-$role" branch.autosetupmerge false "${agent[@]}"
  expect_config "claude-agent-$role" push.default current "${agent[@]}"
  expect_config "claude-agent-$role" core.fsmonitor false "${agent[@]}"
  scenario "agent-$role" no "${agent[@]}"
done

interactive=(-u GIT_CONFIG_GLOBAL HOME="$FAKEHOME")
expect_config interactive push.autosetupremote true "${interactive[@]}"
expect_config interactive push.default current "${interactive[@]}"
scenario interactive yes "${interactive[@]}"

exit $fail
