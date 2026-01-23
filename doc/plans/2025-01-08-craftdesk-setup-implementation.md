# Craftdesk Setup Helper Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a helper script and profile system for setting up craftdesk in any git repo with commit or local-only modes.

**Architecture:** Bash script (`craftdesk-setup`) reads profile templates from `claude/profiles/`, prompts user for profile and commit strategy, copies profile to `craftdesk.json`, configures git exclusions, and runs `craftdesk install`.

**Tech Stack:** Bash, jq (for JSON manipulation), craftdesk CLI

---

## Task 1: Create Profiles Directory Structure

**Files:**

- Create: `claude/profiles/` directory

**Step 1: Create the profiles directory**

```bash
mkdir -p ~/workspace/dotfiles/claude/profiles
```

**Step 2: Verify directory exists**

Run: `ls -la ~/workspace/dotfiles/claude/`
Expected: `profiles` directory listed

**Step 3: Commit**

```bash
cd ~/workspace/dotfiles
git add claude/profiles
git commit -m "feat: add claude/profiles directory for craftdesk templates"
```

---

## Task 2: Create Superpowers Profile

**Files:**

- Create: `claude/profiles/superpowers.json`

**Step 1: Create the superpowers profile**

```json
{
  "name": "local-project",
  "version": "1.0.0",
  "description": "Brainstorming, planning, debugging workflows",
  "dependencies": {
    "superpowers": {
      "git": "https://github.com/anthropics/superpowers-skill.git",
      "branch": "main"
    },
    "elements-of-style": {
      "git": "https://github.com/anthropics/elements-of-style-skill.git",
      "branch": "main"
    }
  }
}
```

**Step 2: Verify JSON is valid**

Run: `jq empty ~/workspace/dotfiles/claude/profiles/superpowers.json && echo "Valid JSON"`
Expected: "Valid JSON"

**Step 3: Commit**

```bash
cd ~/workspace/dotfiles
git add claude/profiles/superpowers.json
git commit -m "feat: add superpowers profile for craftdesk"
```

---

## Task 3: Create Minimal Profile

**Files:**

- Create: `claude/profiles/minimal.json`

**Step 1: Create the minimal profile**

```json
{
  "name": "local-project",
  "version": "1.0.0",
  "description": "Minimal setup - just essentials",
  "dependencies": {}
}
```

**Step 2: Verify JSON is valid**

Run: `jq empty ~/workspace/dotfiles/claude/profiles/minimal.json && echo "Valid JSON"`
Expected: "Valid JSON"

**Step 3: Commit**

```bash
cd ~/workspace/dotfiles
git add claude/profiles/minimal.json
git commit -m "feat: add minimal profile for craftdesk"
```

---

## Task 4: Create craftdesk-setup Script - Basic Structure

**Files:**

- Create: `bin/craftdesk-setup`

**Step 1: Create script with shebang, strict mode, and constants**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Constants
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/workspace/dotfiles}"
PROFILES_DIR="$DOTFILES_DIR/claude/profiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() { echo -e "${BLUE}$*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
error() { echo -e "${RED}✗ $*${NC}" >&2; }
die() {
  error "$*"
  exit 1
}
```

**Step 2: Make script executable**

Run: `chmod +x ~/workspace/dotfiles/bin/craftdesk-setup`

**Step 3: Verify script runs without error**

Run: `~/workspace/dotfiles/bin/craftdesk-setup --help 2>&1 || true`
Expected: No syntax errors (may show "unrecognized option" or similar)

**Step 4: Commit**

```bash
cd ~/workspace/dotfiles
git add bin/craftdesk-setup
git commit -m "feat: add craftdesk-setup script skeleton"
```

---

## Task 5: Add Prerequisite Checks

**Files:**

- Modify: `bin/craftdesk-setup`

**Step 1: Add prerequisite check functions after helper functions**

```bash
# Prerequisite checks
check_prerequisites() {
  # Check for git
  if ! command -v git &> /dev/null; then
    die "git is required but not installed"
  fi

  # Check for craftdesk
  if ! command -v craftdesk &> /dev/null; then
    die "craftdesk is required but not installed. Install with: npm install -g craftdesk"
  fi

  # Check for jq
  if ! command -v jq &> /dev/null; then
    die "jq is required but not installed. Install with: brew install jq"
  fi

  # Check we're in a git repo
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    die "Not inside a git repository"
  fi

  # Check profiles directory exists
  if [[ ! -d "$PROFILES_DIR" ]]; then
    die "Profiles directory not found: $PROFILES_DIR"
  fi
}
```

**Step 2: Add main function that calls check_prerequisites**

```bash
main() {
  check_prerequisites
  info "All prerequisites met"
}

main "$@"
```

**Step 3: Test in a git repo**

Run: `cd ~/workspace/dotfiles && ~/workspace/dotfiles/bin/craftdesk-setup`
Expected: "All prerequisites met"

**Step 4: Test outside a git repo**

Run: `cd /tmp && ~/workspace/dotfiles/bin/craftdesk-setup 2>&1 || true`
Expected: Error message about not being in a git repository

**Step 5: Commit**

```bash
cd ~/workspace/dotfiles
git add bin/craftdesk-setup
git commit -m "feat(craftdesk-setup): add prerequisite checks"
```

---

## Task 6: Add Repo State Detection

**Files:**

- Modify: `bin/craftdesk-setup`

**Step 1: Add detect_repo_state function before main**

```bash
# Detect current repo state
detect_repo_state() {
  REPO_ROOT=$(git rev-parse --show-toplevel)
  PROJECT_NAME=$(basename "$REPO_ROOT")

  # Check if craftdesk.json exists
  if [[ -f "$REPO_ROOT/craftdesk.json" ]]; then
    CRAFTDESK_EXISTS=true
  else
    CRAFTDESK_EXISTS=false
  fi

  # Check if .claude/ exists and is tracked
  if [[ -d "$REPO_ROOT/.claude" ]]; then
    CLAUDE_DIR_EXISTS=true
    if git ls-files --error-unmatch "$REPO_ROOT/.claude" &> /dev/null 2>&1; then
      CLAUDE_DIR_TRACKED=true
    else
      CLAUDE_DIR_TRACKED=false
    fi
  else
    CLAUDE_DIR_EXISTS=false
    CLAUDE_DIR_TRACKED=false
  fi
}
```

**Step 2: Update main to call detect_repo_state and show state**

```bash
main() {
  check_prerequisites
  detect_repo_state

  info "Repository: $PROJECT_NAME"
  info "Root: $REPO_ROOT"
  info "craftdesk.json exists: $CRAFTDESK_EXISTS"
  info ".claude/ exists: $CLAUDE_DIR_EXISTS"
  info ".claude/ tracked: $CLAUDE_DIR_TRACKED"
}
```

**Step 3: Test in dotfiles repo**

Run: `cd ~/workspace/dotfiles && ~/workspace/dotfiles/bin/craftdesk-setup`
Expected: Shows repo state information

**Step 4: Commit**

```bash
cd ~/workspace/dotfiles
git add bin/craftdesk-setup
git commit -m "feat(craftdesk-setup): add repo state detection"
```

---

## Task 7: Add Profile Selection Prompt

**Files:**

- Modify: `bin/craftdesk-setup`

**Step 1: Add list_profiles and select_profile functions**

```bash
# List available profiles
list_profiles() {
  local profiles=()
  for f in "$PROFILES_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    local name=$(basename "$f" .json)
    local desc=$(jq -r '.description // "No description"' "$f")
    profiles+=("$name|$desc")
  done
  printf '%s\n' "${profiles[@]}"
}

# Prompt for profile selection
select_profile() {
  local profiles_list
  profiles_list=$(list_profiles)

  if [[ -z "$profiles_list" ]]; then
    die "No profiles found in $PROFILES_DIR"
  fi

  echo ""
  info "Available profiles:"
  local i=1
  while IFS='|' read -r name desc; do
    echo "  $i) $name - $desc"
    ((i++))
  done <<< "$profiles_list"
  echo ""

  local profile_count
  profile_count=$(echo "$profiles_list" | wc -l | tr -d ' ')

  read -rp "Which profile? [1]: " choice
  choice=${choice:-1}

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > profile_count)); then
    die "Invalid selection: $choice"
  fi

  SELECTED_PROFILE=$(echo "$profiles_list" | sed -n "${choice}p" | cut -d'|' -f1)
  SELECTED_PROFILE_PATH="$PROFILES_DIR/$SELECTED_PROFILE.json"

  success "Selected profile: $SELECTED_PROFILE"
}
```

**Step 2: Update main to call select_profile**

```bash
main() {
  check_prerequisites
  detect_repo_state

  info "Repository: $PROJECT_NAME"

  # Check for existing craftdesk.json
  if [[ "$CRAFTDESK_EXISTS" == "true" ]]; then
    warn "craftdesk.json already exists"
    read -rp "Overwrite? [y/N]: " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      die "Aborted"
    fi
  fi

  select_profile
}
```

**Step 3: Test profile selection**

Run: `cd ~/workspace/dotfiles && ~/workspace/dotfiles/bin/craftdesk-setup`
Expected: Shows profile list, accepts selection, shows "Selected profile: ..."

**Step 4: Commit**

```bash
cd ~/workspace/dotfiles
git add bin/craftdesk-setup
git commit -m "feat(craftdesk-setup): add profile selection prompt"
```

---

## Task 8: Add Commit Strategy Prompt

**Files:**

- Modify: `bin/craftdesk-setup`

**Step 1: Add select_commit_strategy function**

```bash
# Prompt for commit strategy
select_commit_strategy() {
  echo ""
  info "How should craftdesk files be managed?"
  echo "  1) Commit to repo (for repos you own)"
  echo "  2) Keep local only (for repos you don't control)"
  echo ""

  read -rp "Choice [2]: " choice
  choice=${choice:-2}

  case "$choice" in
    1)
      COMMIT_STRATEGY="commit"
      success "Strategy: commit to repo"
      ;;
    2)
      COMMIT_STRATEGY="local"
      success "Strategy: keep local only"
      ;;
    *)
      die "Invalid selection: $choice"
      ;;
  esac
}
```

**Step 2: Update main to call select_commit_strategy**

```bash
main() {
  check_prerequisites
  detect_repo_state

  info "Repository: $PROJECT_NAME"

  if [[ "$CRAFTDESK_EXISTS" == "true" ]]; then
    warn "craftdesk.json already exists"
    read -rp "Overwrite? [y/N]: " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      die "Aborted"
    fi
  fi

  select_profile
  select_commit_strategy
}
```

**Step 3: Test commit strategy selection**

Run: `cd ~/workspace/dotfiles && ~/workspace/dotfiles/bin/craftdesk-setup`
Expected: Shows both prompts, accepts selections

**Step 4: Commit**

```bash
cd ~/workspace/dotfiles
git add bin/craftdesk-setup
git commit -m "feat(craftdesk-setup): add commit strategy prompt"
```

---

## Task 9: Add Setup Functions

**Files:**

- Modify: `bin/craftdesk-setup`

**Step 1: Add copy_profile function**

```bash
# Copy profile to craftdesk.json with project name substitution
copy_profile() {
  info "Creating craftdesk.json from $SELECTED_PROFILE profile..."

  jq --arg name "$PROJECT_NAME" '.name = $name' "$SELECTED_PROFILE_PATH" > "$REPO_ROOT/craftdesk.json"

  success "Created craftdesk.json"
}
```

**Step 2: Add configure_git_exclusions function**

```bash
# Configure git exclusions based on strategy
configure_git_exclusions() {
  if [[ "$COMMIT_STRATEGY" == "local" ]]; then
    info "Adding craftdesk files to .git/info/exclude..."

    local exclude_file="$REPO_ROOT/.git/info/exclude"

    # Check if already configured
    if grep -q "craftdesk (local)" "$exclude_file" 2> /dev/null; then
      warn "Exclusions already configured in .git/info/exclude"
      return
    fi

    cat >> "$exclude_file" << 'EOF'

# craftdesk (local)
craftdesk.json
craftdesk.lock
.claude/
EOF

    success "Added exclusions to .git/info/exclude"
  else
    info "Adding .claude/settings.local.json to .gitignore..."

    local gitignore="$REPO_ROOT/.gitignore"

    # Check if already in gitignore
    if grep -q ".claude/settings.local.json" "$gitignore" 2> /dev/null; then
      warn ".claude/settings.local.json already in .gitignore"
      return
    fi

    echo "" >> "$gitignore"
    echo "# Claude Code local settings" >> "$gitignore"
    echo ".claude/settings.local.json" >> "$gitignore"

    success "Added .claude/settings.local.json to .gitignore"
  fi
}
```

**Step 3: Add run_craftdesk_install function**

```bash
# Run craftdesk install
run_craftdesk_install() {
  info "Running craftdesk install..."

  cd "$REPO_ROOT"
  craftdesk install

  success "Dependencies installed"
}
```

**Step 4: Commit**

```bash
cd ~/workspace/dotfiles
git add bin/craftdesk-setup
git commit -m "feat(craftdesk-setup): add setup functions"
```

---

## Task 10: Wire Up Main and Add Summary

**Files:**

- Modify: `bin/craftdesk-setup`

**Step 1: Add show_summary function**

```bash
# Show final summary
show_summary() {
  echo ""
  success "Craftdesk configured with '$SELECTED_PROFILE' profile"
  echo "  - craftdesk.json created"
  echo "  - Dependencies installed to .claude/"

  if [[ "$COMMIT_STRATEGY" == "local" ]]; then
    echo "  - Files excluded from git (local only mode)"
  else
    echo "  - Ready to commit (run: git add craftdesk.json craftdesk.lock .claude/)"
  fi

  echo ""
  info "Run 'craftdesk list' to see installed crafts."
}
```

**Step 2: Update main to call all functions**

```bash
main() {
  check_prerequisites
  detect_repo_state

  info "Repository: $PROJECT_NAME"

  if [[ "$CRAFTDESK_EXISTS" == "true" ]]; then
    warn "craftdesk.json already exists"
    read -rp "Overwrite? [y/N]: " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      die "Aborted"
    fi
  fi

  select_profile
  select_commit_strategy

  copy_profile
  configure_git_exclusions
  run_craftdesk_install

  show_summary
}

main "$@"
```

**Step 3: Commit**

```bash
cd ~/workspace/dotfiles
git add bin/craftdesk-setup
git commit -m "feat(craftdesk-setup): wire up main and add summary"
```

---

## Task 11: Test in Local-Only Mode

**Files:**

- Test only, no changes

**Step 1: Create a test directory**

```bash
cd /tmp
mkdir craftdesk-test-local
cd craftdesk-test-local
git init
```

**Step 2: Run craftdesk-setup with local-only mode**

Run: `~/workspace/dotfiles/bin/craftdesk-setup`

- Select profile: 1 (superpowers)
- Select strategy: 2 (local only)

Expected: Script completes successfully

**Step 3: Verify .git/info/exclude contains exclusions**

Run: `cat .git/info/exclude`
Expected: Contains "craftdesk (local)" section with craftdesk.json, craftdesk.lock, .claude/

**Step 4: Verify files are not tracked**

Run: `git status`
Expected: Nothing to commit (craftdesk files are excluded)

**Step 5: Clean up**

```bash
cd /tmp
rm -rf craftdesk-test-local
```

---

## Task 12: Test in Commit Mode

**Files:**

- Test only, no changes

**Step 1: Create a test directory**

```bash
cd /tmp
mkdir craftdesk-test-commit
cd craftdesk-test-commit
git init
echo "# Test" > README.md
git add README.md
git commit -m "initial"
```

**Step 2: Run craftdesk-setup with commit mode**

Run: `~/workspace/dotfiles/bin/craftdesk-setup`

- Select profile: 1 (superpowers)
- Select strategy: 1 (commit)

Expected: Script completes successfully

**Step 3: Verify .gitignore contains settings.local.json**

Run: `cat .gitignore`
Expected: Contains ".claude/settings.local.json"

**Step 4: Verify craftdesk files are tracked**

Run: `git status`
Expected: Shows craftdesk.json, craftdesk.lock, .claude/ as untracked (ready to add)

**Step 5: Clean up**

```bash
cd /tmp
rm -rf craftdesk-test-commit
```

---

## Task 13: Final Commit with Complete Script

**Files:**

- Verify: `bin/craftdesk-setup`

**Step 1: Verify script is complete and working**

Run: `head -100 ~/workspace/dotfiles/bin/craftdesk-setup`
Expected: Complete script with all functions

**Step 2: Ensure script is committed**

```bash
cd ~/workspace/dotfiles
git status
```

If there are uncommitted changes:

```bash
git add bin/craftdesk-setup claude/profiles/
git commit -m "feat: complete craftdesk-setup helper script

- Add profile system with superpowers and minimal profiles
- Support commit and local-only modes
- Auto-configure git exclusions
- Run craftdesk install automatically"
```

---

## Summary

After completing all tasks, you will have:

1. `claude/profiles/superpowers.json` - Profile for superpowers workflow
2. `claude/profiles/minimal.json` - Minimal profile with no dependencies
3. `bin/craftdesk-setup` - Helper script that:
   - Checks prerequisites (git, craftdesk, jq)
   - Detects repo state
   - Prompts for profile selection
   - Prompts for commit strategy
   - Creates craftdesk.json from profile
   - Configures git exclusions appropriately
   - Runs craftdesk install
   - Shows summary

To use: `cd /path/to/any/repo && craftdesk-setup`
