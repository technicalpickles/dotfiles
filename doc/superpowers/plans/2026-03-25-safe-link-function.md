# Safe link() Function Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the dotfiles `link()` function safe when the target is a real file or directory, with interactive prompts, a `--yes` flag for unattended use, and protection against nested symlinks.

**Architecture:** Add `confirm()` and `backup_path()` helpers to `functions.sh`, rewrite `link()` to use them. Add `--yes`/`-y` flag parsing and interactivity guard to `symlinks.sh` and `install.sh`.

**Tech Stack:** Bash, `ln`, `mv`, `readlink`

**Spec:** `doc/superpowers/specs/2026-03-25-safe-link-function-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `functions.sh` | Modify lines 87-106 | `confirm()`, `backup_path()`, rewritten `link()` |
| `symlinks.sh` | Modify lines 1-14 | `--yes`/`-y` flag parsing, interactivity guard |
| `install.sh` | Modify lines 1-6 | `--yes`/`-y` flag parsing, interactivity guard |
| `scripts/test-link.sh` | Create | Manual verification script |

---

### Task 1: Add `backup_path()` helper to `functions.sh`

**Files:**
- Modify: `functions.sh:86` (insert before `link()`)

- [ ] **Step 1: Add `backup_path()` function**

Insert before the `link()` function (before line 87):

```bash
backup_path() {
  local target="$1"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local backup="${target}.backup.${timestamp}"
  local counter=2
  while [ -e "$backup" ]; do
    backup="${target}.backup.${timestamp}-${counter}"
    counter=$((counter + 1))
  done
  echo "$backup"
}
```

- [ ] **Step 2: Verify it sources cleanly**

Run: `bash -n functions.sh`
Expected: no output (syntax OK)

- [ ] **Step 3: Commit**

```
git add functions.sh
git commit -m "feat(link): add backup_path() helper for timestamped backups"
```

---

### Task 2: Add `confirm()` helper to `functions.sh`

**Files:**
- Modify: `functions.sh:86` (insert before `backup_path()`)

- [ ] **Step 1: Add `confirm()` function**

Insert before `backup_path()`:

```bash
# Ask a y/N question. Returns 0 for yes, 1 for no.
# In auto-yes mode, always returns 0. Scripts guard against
# non-interactive use at startup, so this always has a tty or --yes.
confirm() {
  local prompt="$1"
  if [ "${DOTPICKLES_YES:-}" = "1" ]; then
    return 0
  fi
  read -p "$prompt " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}
```

- [ ] **Step 2: Verify it sources cleanly**

Run: `bash -n functions.sh`
Expected: no output (syntax OK)

- [ ] **Step 3: Commit**

```
git add functions.sh
git commit -m "feat(link): add confirm() helper for interactive/auto-yes prompts"
```

---

### Task 3: Rewrite `link()` in `functions.sh`

**Files:**
- Modify: `functions.sh:87-106` (the current `link()` function, line numbers will have shifted from Tasks 1-2)

- [ ] **Step 1: Replace the `link()` function**

Replace the entire current `link()` function (from `link() {` to its closing `}`) with:

```bash
link() {
  local linkable="$1"
  local target="$2"
  local display_target="${target/$HOME/~}"
  local source="${DIR}/${linkable}"

  if [ -L "$target" ]; then
    # Target is a symlink
    if [ "$(readlink "$target")" = "$source" ]; then
      echo "🔗 $display_target -> already linked"
    elif confirm "🔗 $display_target -> linked to $(readlink "$target"). Repoint to ${linkable}? [y/N]"; then
      echo "🔗 $display_target -> linking from $linkable"
      ln -Ff -s "$source" "$target"
    else
      echo "🔗 $display_target -> skipped (wrong symlink)"
    fi
  elif [ -e "$target" ]; then
    # Target exists as real file or directory
    local filetype="file"
    [ -d "$target" ] && filetype="directory"

    if confirm "🔗 $display_target -> exists as $filetype. Replace with symlink to ${linkable}? [y/N]"; then
      local backup
      backup="$(backup_path "$target")"
      echo "🔗 $display_target -> backing up to ${backup##*/}"
      mv "$target" "$backup"
      echo "🔗 $display_target -> linking from $linkable"
      ln -s "$source" "$target"
    else
      echo "🔗 $display_target -> skipped ($filetype exists)"
    fi
  else
    # Target doesn't exist
    echo "🔗 $display_target -> linking from $linkable"
    ln -s "$source" "$target"
  fi
}
```

- [ ] **Step 2: Verify it sources cleanly**

Run: `bash -n functions.sh`
Expected: no output (syntax OK)

- [ ] **Step 3: Commit**

```
git add functions.sh
git commit -m "feat(link): rewrite link() with safe handling for real files/dirs

Splits the old 'not a symlink' case into 'doesn't exist' (create)
and 'real file/dir' (prompt + backup). Uses confirm() for all
interactive prompts and backup_path() for timestamped backups.
Removes ln -Ff flags where target is known to not exist, preventing
nested symlink creation."
```

---

### Task 4: Add `--yes`/`-y` flag and interactivity guard to `symlinks.sh`

**Files:**
- Modify: `symlinks.sh:1-14`

- [ ] **Step 1: Add flag parsing and guard after the shebang block**

Replace lines 1-14 of `symlinks.sh` (everything before `link_directory_contents home` on line 15) with:

```bash
#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DIR

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --yes|-y) export DOTPICKLES_YES=1 ;;
  esac
done

if [[ -f .env ]]; then
  source .env
fi

# shellcheck source=./functions.sh
source ./functions.sh

# Guard: non-interactive without --yes is an error
if [ "${DOTPICKLES_YES:-}" != "1" ] && [ ! -t 0 ]; then
  echo "Error: not running interactively. Use --yes/-y for unattended mode." >&2
  exit 1
fi
```

The rest of the file (from `link_directory_contents home` onward) stays unchanged.

- [ ] **Step 2: Verify syntax**

Run: `bash -n symlinks.sh`
Expected: no output (syntax OK)

- [ ] **Step 3: Commit**

```
git add symlinks.sh
git commit -m "feat(symlinks): add --yes/-y flag and interactivity guard"
```

---

### Task 5: Add `--yes`/`-y` flag and interactivity guard to `install.sh`

**Files:**
- Modify: `install.sh:1-6`

- [ ] **Step 1: Add flag parsing after the shebang block**

Insert after line 4 (`set -eo pipefail`) and before line 6 (`DIR=...`):

```bash
# Parse flags
for arg in "$@"; do
  case "$arg" in
    --yes|-y) export DOTPICKLES_YES=1 ;;
  esac
done
```

Then insert the interactivity guard after `source ./functions.sh` (currently line 35) and before the first `if running_macos` block (currently line 37):

```bash
# Guard: non-interactive without --yes is an error
if [ "${DOTPICKLES_YES:-}" != "1" ] && [ ! -t 0 ]; then
  echo "Error: not running interactively. Use --yes/-y for unattended mode." >&2
  exit 1
fi
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n install.sh`
Expected: no output (syntax OK)

- [ ] **Step 3: Commit**

```
git add install.sh
git commit -m "feat(install): add --yes/-y flag and interactivity guard"
```

---

### Task 6: Write verification script and manually test

**Files:**
- Create: `scripts/test-link.sh`

- [ ] **Step 1: Create the verification script**

```bash
#!/usr/bin/env bash
# Manual verification for safe link() function.
# Run from the dotfiles repo root.
#
# Usage:
#   ./scripts/test-link.sh          # interactive tests
#   ./scripts/test-link.sh --yes    # auto-yes tests

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DIR

for arg in "$@"; do
  case "$arg" in
    --yes|-y) export DOTPICKLES_YES=1 ;;
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
  backup=$(ls -d "$TEST_DIR"/result4.backup.* 2>/dev/null | head -1)
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
  backup=$(ls "$TEST_DIR"/result5.backup.* 2>/dev/null | head -1)
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
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x scripts/test-link.sh`

- [ ] **Step 3: Run interactive tests**

Run from repo root: `./scripts/test-link.sh`
Expected: prompts for tests 3, 4, 5. Answer 'y' to all. All should show PASS.

- [ ] **Step 4: Run auto-yes tests**

Run: `./scripts/test-link.sh --yes`
Expected: no prompts, all tests show PASS.

- [ ] **Step 5: Test non-interactive guard**

Run: `echo "" | ./symlinks.sh`
Expected: `Error: not running interactively. Use --yes/-y for unattended mode.` and exit code 1.

- [ ] **Step 6: Run lint**

Run: `npm run lint`
Expected: passes (no TypeScript or formatting regressions)

- [ ] **Step 7: Commit**

```
git add scripts/test-link.sh
git commit -m "test: add manual verification script for safe link() function"
```
