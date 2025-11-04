# Monorepo Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a skill and init script that helps Claude work effectively in monorepos by maintaining directory context awareness and ensuring commands execute from correct locations using absolute paths.

**Architecture:** Skill enforces methodology (always use absolute paths), separate init script handles detection and config generation. Works with or without configuration file. TDD approach: write pressure test scenarios before skill, iterate until bulletproof.

**Tech Stack:** Markdown (skill), Bash (init script), jq (JSON processing), fd (file detection)

---

## Task 1: Create Baseline Test Scenarios (RED Phase)

**Files:**

- Create: `home/.claude/skills/working-in-monorepos/tests/baseline-scenarios.md`

**Step 1: Create test directory structure**

```bash
mkdir -p home/.claude/skills/working-in-monorepos/tests
```

**Step 2: Write pressure test scenarios**

Create `home/.claude/skills/working-in-monorepos/tests/baseline-scenarios.md`:

```markdown
# Baseline Test Scenarios (Without Skill)

These scenarios test agent behavior WITHOUT the skill loaded.

## Scenario 1: Simple Command After cd

**Setup:**

- Repo: ~/workspace/schemaflow
- Subprojects: ruby/, cli/
- Just ran: `cd ruby && bundle install`

**Task:** "Now run rspec"

**Expected baseline failures:**

- `cd ruby && bundle exec rspec` (compounds cd)
- `bundle exec rspec` (assumes location)
- `cd ruby && rspec` (still wrong)

**Success criteria:** Agent uses absolute path

---

## Scenario 2: Multiple Commands in Sequence

**Setup:**

- Repo: ~/workspace/schemaflow
- Just ran: `cd ruby && bundle install`
- Then ran: `cd ruby && rubocop`

**Task:** "Now run the tests"

**Expected baseline failures:**

- Continues compounding cd commands
- Assumes it's in ruby/ directory

**Success criteria:** Each command uses absolute path from root

---

## Scenario 3: Time Pressure + Sunk Cost

**Setup:**

- You've been working in ruby/ subproject for 2 hours
- Made 10 commits, all using relative paths
- Tests are passing
- It's 5:45pm, meeting at 6pm

**Task:** "Quick, run the linter before the meeting"

**Expected baseline failures:**

- Uses relative path to save time
- "I've been here all session, I know where I am"
- "The shell hasn't changed directories"

**Success criteria:** Uses absolute path despite pressure

---

## Scenario 4: Complex Monorepo (zenpayroll pattern)

**Setup:**

- Repo: ~/workspace/zenpayroll
- Root project at .
- Component at components/gusto-deprecation
- rubocop MUST run from root
- rspec in components MUST run from component dir

**Task:** "Run rubocop on the gusto-deprecation component"

**Expected baseline failures:**

- Runs from component directory
- Doesn't check command rules
- Assumes rubocop can run anywhere

**Success criteria:** Runs rubocop from absolute repo root path
```

**Step 3: Commit test scenarios**

```bash
git add home/.claude/skills/working-in-monorepos/tests/
git commit -m "test: add baseline test scenarios for monorepo skill"
```

---

## Task 2: Run Baseline Tests and Document Failures

**Files:**

- Create: `home/.claude/skills/working-in-monorepos/tests/baseline-results.md`

**Step 1: Run baseline tests with subagent**

Use Task tool to run each scenario WITHOUT the skill loaded. For each scenario:

1. Launch fresh subagent (general-purpose)
2. Present scenario
3. Record exact agent responses and commands used
4. Document rationalizations verbatim

**Step 2: Document baseline results**

Create `home/.claude/skills/working-in-monorepos/tests/baseline-results.md`:

```markdown
# Baseline Test Results

## Scenario 1: Simple Command After cd

**Agent response:**
[Record exact response]

**Commands used:**
[Record exact commands]

**Rationalizations:**
[Quote agent's reasoning]

---

[Repeat for each scenario]

## Summary of Failures

**Common patterns:**

- [List repeated failure patterns]

**Rationalizations to counter:**

- [List all rationalizations from all tests]

**What the skill must prevent:**

- [Specific behaviors to address]
```

**Step 3: Commit baseline results**

```bash
git add home/.claude/skills/working-in-monorepos/tests/baseline-results.md
git commit -m "test: document baseline test failures for monorepo skill"
```

---

## Task 3: Write Minimal Skill (GREEN Phase)

**Files:**

- Create: `home/.claude/skills/working-in-monorepos/SKILL.md`

**Step 1: Create skill with frontmatter**

Create `home/.claude/skills/working-in-monorepos/SKILL.md`:

````markdown
---
name: working-in-monorepos
description: Use when working in repositories with multiple subprojects (monorepos) where commands need to run from specific directories - prevents directory confusion, redundant cd commands, and ensures commands execute from correct locations
---

# Working in Monorepos

## Overview

Helps Claude work effectively in monorepo environments by ensuring commands always execute from the correct location using absolute paths.

**Core principle:** Bash shell state is not guaranteed between commands. Always use absolute paths.

**Announce at start:** "I'm using the working-in-monorepos skill."

## When to Use

Use this skill when:

- Repository contains multiple subprojects (ruby/, cli/, components/\*, etc.)
- Commands must run from specific directories
- Working across multiple subprojects in one session

Don't use for:

- Single-project repositories
- Repositories where all commands run from root

## The Iron Rule: Always Use Absolute Paths

When executing ANY command in a monorepo subproject:

✅ **CORRECT:**

```bash
cd /Users/josh/workspace/schemaflow/ruby && bundle exec rspec
cd /Users/josh/workspace/schemaflow/cli && npm test
```
````

❌ **WRONG:**

```bash
# Relative paths (assumes current directory)
cd ruby && bundle exec rspec

# No cd prefix (assumes location)
bundle exec rspec

# Chaining cd (compounds errors)
cd ruby && cd ruby && rspec
```

**Why:** You cannot rely on shell state. Absolute paths guarantee correct execution location regardless of where the shell currently is.

## Constructing Absolute Paths

### With .monorepo.json Config

If `.monorepo.json` exists at repo root:

1. Read `root` field for absolute repo path
2. Read subproject `path` from `subprojects` map
3. Construct: `cd {root}/{path} && command`

Example:

```json
{
  "root": "/Users/josh/workspace/schemaflow",
  "subprojects": { "ruby": { "path": "ruby" } }
}
```

→ `cd /Users/josh/workspace/schemaflow/ruby && bundle exec rspec`

### Without Config

Use git to find repo root dynamically:

```bash
cd $(git rev-parse --show-toplevel)/ruby && bundle exec rspec
```

## Setup Workflow (No Config Present)

When skill activates in a repo without `.monorepo.json`:

1. **Detect:** "I notice this appears to be a monorepo without a .monorepo.json config."
2. **Offer:** "I can run bin/monorepo-init to auto-detect subprojects and generate config. Would you like me to?"
3. **User accepts:** Run `bin/monorepo-init --dry-run`, show output, ask for approval, then `bin/monorepo-init --write`
4. **User declines:** "No problem. I'll use git to find the repo root for each command."
5. **User wants custom:** "You can also create .monorepo.json manually. See example below."

## Command Execution Rules (With Config)

If `.monorepo.json` defines command rules:

```json
{
  "commands": {
    "rubocop": { "location": "root" },
    "rspec": {
      "location": "subproject",
      "command": "bundle exec rspec",
      "overrides": { "root": { "command": "bin/rspec" } }
    }
  }
}
```

**Check rules before executing:**

1. Look up command in `commands` map
2. Check `location`: "root" | "subproject"
3. Check for `command` override
4. Check for context-specific `overrides`

**Example:**

- rubocop: Always run from repo root
- rspec in ruby/: Use `bundle exec rspec`
- rspec in root project: Use `bin/rspec`

## Common Mistakes to Prevent

❌ **"I just used cd, so I'm in the right directory"**
Reality: You cannot track shell state reliably. Always use absolute paths.

❌ **"The shell remembers where I am"**
Reality: Shell state is not guaranteed between commands. Always use absolute paths.

❌ **"It's wasteful to cd every time"**
Reality: Explicitness prevents bugs. Always use absolute paths.

❌ **"Relative paths are simpler"**
Reality: They break when assumptions are wrong. Always use absolute paths.

## Quick Reference

| Task                    | Command Pattern                                                  |
| ----------------------- | ---------------------------------------------------------------- |
| Run tests in subproject | `cd $(git rev-parse --show-toplevel)/subproject && test-command` |
| With config             | `cd {root}/{subproject.path} && command`                         |
| Check for config        | `test -f .monorepo.json`                                         |
| Generate config         | `bin/monorepo-init --dry-run` then `bin/monorepo-init --write`   |
| Always rule             | Use absolute path + cd prefix for EVERY command                  |

## Configuration Schema

`.monorepo.json` at repository root:

```json
{
  "root": "/absolute/path/to/repo",
  "subprojects": {
    "subproject-id": {
      "path": "relative/path",
      "type": "ruby|node|go|python|rust|java",
      "description": "Optional"
    }
  },
  "commands": {
    "command-name": {
      "location": "root|subproject",
      "command": "optional override",
      "overrides": {
        "context": { "command": "context-specific" }
      }
    }
  }
}
```

**Minimal example:**

```json
{
  "root": "/Users/josh/workspace/schemaflow",
  "subprojects": {
    "ruby": { "path": "ruby", "type": "ruby" },
    "cli": { "path": "cli", "type": "node" }
  }
}
```

````

**Step 2: Commit initial skill**

```bash
git add home/.claude/skills/working-in-monorepos/SKILL.md
git commit -m "feat: add initial monorepo skill (GREEN phase)"
````

---

## Task 4: Test Skill and Document Results

**Files:**

- Create: `home/.claude/skills/working-in-monorepos/tests/green-results.md`

**Step 1: Run scenarios WITH skill**

Use Task tool to run each baseline scenario WITH the skill loaded:

1. Launch fresh subagent (general-purpose)
2. Include skill in context: "You have access to: working-in-monorepos"
3. Present same scenarios
4. Record agent responses and commands
5. Document whether agent followed rules

**Step 2: Document GREEN results**

Create `home/.claude/skills/working-in-monorepos/tests/green-results.md`:

```markdown
# GREEN Phase Test Results

## Scenario 1: Simple Command After cd

**Agent response:**
[Record exact response]

**Commands used:**
[Record exact commands]

**Followed rules:** YES/NO
**If NO, rationalization:**
[Quote reasoning]

---

[Repeat for each scenario]

## Summary

**Success rate:** X/Y scenarios passed

**Remaining issues:**

- [List scenarios that failed]

**New rationalizations found:**

- [Quote any new excuses]

**Next steps:**

- [What needs to be added to skill]
```

**Step 3: Commit GREEN results**

```bash
git add home/.claude/skills/working-in-monorepos/tests/green-results.md
git commit -m "test: document GREEN phase results"
```

---

## Task 5: Refactor Skill to Close Loopholes

**Files:**

- Modify: `home/.claude/skills/working-in-monorepos/SKILL.md`

**Step 1: Add explicit negations for new rationalizations**

Based on GREEN phase results, add explicit counters for each rationalization found.

Example additions:

```markdown
## Red Flags - STOP

If you're thinking ANY of these thoughts, you're about to violate the rule:

- "I just used cd, so I'm in the right directory"
- "The shell remembers where I am"
- "It's wasteful to cd every time"
- "I can track directory state mentally"
- "Relative paths are simpler"
- "I'll just check pwd first"

**All of these mean: Use absolute path anyway. No exceptions.**
```

Add rationalization table:

```markdown
## Common Rationalizations

| Excuse              | Reality                                        |
| ------------------- | ---------------------------------------------- |
| "I just cd'd there" | Shell state not guaranteed. Use absolute path. |
| "Shell remembers"   | Shell state not guaranteed. Use absolute path. |
| "It's wasteful"     | Bugs are more wasteful. Use absolute path.     |
| "I can track it"    | You can't. Use absolute path.                  |
```

**Step 2: Add foundational principle if needed**

If agents argued "spirit vs letter":

```markdown
## Foundational Principle

**Using relative paths violates both the letter AND spirit of this rule.**

The rule exists because shell state is unreliable. Any approach that depends on tracking state (relative paths, checking pwd, mental tracking) violates the principle.
```

**Step 3: Commit refactored skill**

```bash
git add home/.claude/skills/working-in-monorepos/SKILL.md
git commit -m "refactor: add explicit negations and rationalization table"
```

---

## Task 6: Re-verify Skill (Stay GREEN)

**Files:**

- Modify: `home/.claude/skills/working-in-monorepos/tests/green-results.md`

**Step 1: Re-run all scenarios with updated skill**

Run all baseline scenarios again with the refactored skill.

**Step 2: Update GREEN results**

Append to `green-results.md`:

```markdown
---

# REFACTOR Re-test Results

## Scenario 1: Simple Command After cd

**Agent response:**
[Record]

**Followed rules:** YES/NO

---

[Repeat for all]

## Summary

**Success rate:** X/Y scenarios passed

**Status:** BULLETPROOF / NEEDS MORE WORK

**If needs more work:**

- [New rationalizations found]
- [Plan for next REFACTOR iteration]
```

**Step 3: Commit re-test results**

```bash
git add home/.claude/skills/working-in-monorepos/tests/green-results.md
git commit -m "test: re-verify skill after REFACTOR"
```

**Step 4: Iterate if needed**

If any scenarios still fail, repeat Task 5 and Task 6 until bulletproof (all scenarios pass).

---

## Task 7: Create Init Script Structure

**Files:**

- Create: `bin/monorepo-init`

**Step 1: Write script structure with usage**

Create `bin/monorepo-init`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# monorepo-init: Auto-detect subprojects and generate .monorepo.json
#
# Usage:
#   bin/monorepo-init              # Output JSON to stdout
#   bin/monorepo-init --dry-run    # Same as above
#   bin/monorepo-init --write      # Write to .monorepo.json

show_usage() {
  cat << EOF
Usage: monorepo-init [OPTIONS]

Auto-detect subprojects and generate .monorepo.json

OPTIONS:
  --dry-run    Output JSON to stdout (default)
  --write      Write to .monorepo.json
  -h, --help   Show this help

DETECTION:
  Scans for package manager artifacts:
  - package.json (Node)
  - Gemfile (Ruby)
  - go.mod (Go)
  - pyproject.toml, setup.py, requirements.txt (Python)
  - Cargo.toml (Rust)
  - build.gradle, pom.xml (Java)

EXAMPLES:
  bin/monorepo-init --dry-run
  bin/monorepo-init | jq .
  bin/monorepo-init --write
EOF
}

# Parse arguments
MODE="dry-run"
while [[ $# -gt 0 ]]; do
  case $1 in
    --write)
      MODE="write"
      shift
      ;;
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    -h | --help)
      show_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_usage >&2
      exit 1
      ;;
  esac
done

# TODO: Implementation in next tasks
echo "Not yet implemented" >&2
exit 1
```

**Step 2: Make executable**

```bash
chmod +x bin/monorepo-init
```

**Step 3: Commit script structure**

```bash
git add bin/monorepo-init
git commit -m "feat: add monorepo-init script structure"
```

---

## Task 8: Implement Detection Logic

**Files:**

- Modify: `bin/monorepo-init`

**Step 1: Add detection functions**

Add after argument parsing:

```bash
# Find repo root
find_repo_root() {
  git rev-parse --show-toplevel 2> /dev/null || {
    echo "Error: Not in a git repository" >&2
    exit 1
  }
}

# Detect subproject type from artifacts
detect_type() {
  local dir="$1"

  if [[ -f "$dir/package.json" ]]; then
    echo "node"
  elif [[ -f "$dir/Gemfile" ]]; then
    echo "ruby"
  elif [[ -f "$dir/go.mod" ]]; then
    echo "go"
  elif [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/setup.py" ]] || [[ -f "$dir/requirements.txt" ]]; then
    echo "python"
  elif [[ -f "$dir/Cargo.toml" ]]; then
    echo "rust"
  elif [[ -f "$dir/build.gradle" ]] || [[ -f "$dir/pom.xml" ]]; then
    echo "java"
  else
    echo "unknown"
  fi
}

# Find all artifact files
find_artifacts() {
  local root="$1"

  # Check if fd is available (faster)
  if command -v fd &> /dev/null; then
    fd -t f '(package\.json|Gemfile|go\.mod|pyproject\.toml|setup\.py|requirements\.txt|Cargo\.toml|build\.gradle|pom\.xml)$' "$root"
  else
    # Fallback to find
    find "$root" -type f \( \
      -name 'package.json' -o \
      -name 'Gemfile' -o \
      -name 'go.mod' -o \
      -name 'pyproject.toml' -o \
      -name 'setup.py' -o \
      -name 'requirements.txt' -o \
      -name 'Cargo.toml' -o \
      -name 'build.gradle' -o \
      -name 'pom.xml' \
      \)
  fi
}
```

**Step 2: Commit detection functions**

```bash
git add bin/monorepo-init
git commit -m "feat: add artifact detection functions"
```

---

## Task 9: Implement JSON Generation

**Files:**

- Modify: `bin/monorepo-init`

**Step 1: Add JSON generation function**

Add before MODE handling:

```bash
# Generate JSON structure
generate_json() {
  local root="$1"
  local subprojects="$2" # newline-separated list of "id:path:type"

  # Start JSON
  cat << EOF
{
  "root": "$root",
  "subprojects": {
EOF

  # Add each subproject
  local first=true
  while IFS=: read -r id path type; do
    if [[ "$first" == true ]]; then
      first=false
    else
      echo ","
    fi

    cat << EOF
    "$id": {
      "path": "$path",
      "type": "$type"
    }
EOF
  done <<< "$subprojects"

  # Close JSON
  cat << EOF

  }
}
EOF
}
```

**Step 2: Replace TODO with main logic**

Replace `echo "Not yet implemented"` section with:

```bash
# Main logic
REPO_ROOT=$(find_repo_root)
cd "$REPO_ROOT"

# Find all artifacts and group by directory
declare -A seen_dirs
SUBPROJECTS=""

while read -r artifact_path; do
  dir=$(dirname "$artifact_path")

  # Skip if we've seen this directory
  [[ -n "${seen_dirs[$dir]:-}" ]] && continue
  seen_dirs[$dir]=1

  # Generate subproject ID (relative path with / → -)
  rel_path="${dir#$REPO_ROOT/}"
  if [[ "$rel_path" == "$REPO_ROOT" ]] || [[ "$rel_path" == "." ]]; then
    id="root"
    rel_path="."
  else
    id="${rel_path//\//-}"
  fi

  # Detect type
  type=$(detect_type "$dir")

  # Add to list
  SUBPROJECTS+="$id:$rel_path:$type"$'\n'
done < <(find_artifacts "$REPO_ROOT")

# Generate JSON
JSON=$(generate_json "$REPO_ROOT" "$SUBPROJECTS")

# Output based on mode
case "$MODE" in
  dry-run)
    echo "$JSON"
    ;;
  write)
    if [[ -f ".monorepo.json" ]]; then
      echo "Warning: .monorepo.json already exists" >&2
      echo "Overwrite? (y/N) " >&2
      read -r response
      if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Aborted" >&2
        exit 1
      fi
    fi
    echo "$JSON" > .monorepo.json
    echo "Written to .monorepo.json" >&2
    ;;
esac
```

**Step 3: Commit JSON generation**

```bash
git add bin/monorepo-init
git commit -m "feat: implement JSON generation and main logic"
```

---

## Task 10: Test Init Script Manually

**Files:**

- Create: `home/.claude/skills/working-in-monorepos/tests/init-script-test.md`

**Step 1: Test in schemaflow repo (if available)**

If you have access to ~/workspace/schemaflow:

```bash
cd ~/workspace/schemaflow
/path/to/dotfiles/bin/monorepo-init --dry-run
```

Expected output:

```json
{
  "root": "/Users/josh/workspace/schemaflow",
  "subprojects": {
    "cli": { "path": "cli", "type": "node" },
    "ruby": { "path": "ruby", "type": "ruby" }
  }
}
```

**Step 2: Test in dotfiles repo (current repo)**

```bash
cd /path/to/dotfiles
bin/monorepo-init --dry-run
```

Expected: Detects package.json at root (if present) or no subprojects

**Step 3: Document test results**

Create `home/.claude/skills/working-in-monorepos/tests/init-script-test.md`:

```markdown
# Init Script Manual Test Results

## Test 1: schemaflow (if available)

**Command:** `bin/monorepo-init --dry-run`

**Output:**
[Paste actual output]

**Expected:**
[Paste expected output]

**Status:** PASS / FAIL
**Notes:** [Any observations]

---

## Test 2: dotfiles

**Command:** `bin/monorepo-init --dry-run`

**Output:**
[Paste actual output]

**Status:** PASS / FAIL
**Notes:** [Any observations]

---

## Issues Found

[List any bugs or unexpected behavior]

## Fixes Needed

[List what needs to be fixed]
```

**Step 4: Commit test results**

```bash
git add home/.claude/skills/working-in-monorepos/tests/init-script-test.md
git commit -m "test: document init script manual testing"
```

---

## Task 11: Fix Init Script Issues (if any)

**Files:**

- Modify: `bin/monorepo-init`

**Step 1: Address issues from manual testing**

Based on test results, fix any bugs or unexpected behavior.

Common issues to watch for:

- Empty subprojects list
- Incorrect path handling
- JSON formatting errors
- Duplicates in output

**Step 2: Re-test after fixes**

Run manual tests again to verify fixes.

**Step 3: Commit fixes**

```bash
git add bin/monorepo-init
git commit -m "fix: [description of issue fixed]"
```

**Step 4: Update test results**

Add re-test results to `init-script-test.md`.

```bash
git add home/.claude/skills/working-in-monorepos/tests/init-script-test.md
git commit -m "test: document init script re-test results"
```

---

## Task 12: Update Symlinks Script

**Files:**

- Modify: `symlinks.sh`

**Step 1: Check current symlink handling for skills**

```bash
grep -A 5 "\.claude/skills" symlinks.sh
```

**Step 2: Verify skills directory gets symlinked**

The existing infrastructure should handle `home/.claude/skills/` → `~/.claude/skills/`.

Verify by checking symlinks.sh contains:

```bash
link_directory_contents "home" "$HOME"
```

This should already handle all files in `home/` including `.claude/skills/`.

**Step 3: No changes needed if already working**

If the existing symlink logic handles skills correctly, document this:

```bash
git commit --allow-empty -m "docs: verify skills directory symlinks work correctly"
```

---

## Task 13: Update CLAUDE.md with Monorepo Skill

**Files:**

- Modify: `CLAUDE.md`

**Step 1: Add monorepo skill to appropriate section**

Find the "Custom Binaries" or relevant section and add:

```markdown
**Monorepo Management:**

- `bin/monorepo-init`: Auto-detect subprojects and generate `.monorepo.json` config
- Skill: `working-in-monorepos` - Helps Claude work in monorepos by ensuring commands use absolute paths

When working in repositories with multiple subprojects, the working-in-monorepos skill prevents directory confusion by requiring absolute paths for all commands.
```

**Step 2: Commit CLAUDE.md update**

```bash
git add CLAUDE.md
git commit -m "docs: add monorepo skill to CLAUDE.md"
```

---

## Task 14: Create Example Config Files

**Files:**

- Create: `home/.claude/skills/working-in-monorepos/examples/schemaflow.json`
- Create: `home/.claude/skills/working-in-monorepos/examples/zenpayroll.json`

**Step 1: Create examples directory**

```bash
mkdir -p home/.claude/skills/working-in-monorepos/examples
```

**Step 2: Create schemaflow example**

Create `home/.claude/skills/working-in-monorepos/examples/schemaflow.json`:

```json
{
  "root": "/Users/josh/workspace/schemaflow",
  "subprojects": {
    "ruby": {
      "path": "ruby",
      "type": "ruby",
      "description": "Ruby library"
    },
    "cli": {
      "path": "cli",
      "type": "node",
      "description": "CLI tool"
    }
  }
}
```

**Step 3: Create zenpayroll example**

Create `home/.claude/skills/working-in-monorepos/examples/zenpayroll.json`:

```json
{
  "root": "/Users/josh/workspace/zenpayroll",
  "subprojects": {
    "root": {
      "path": ".",
      "type": "ruby",
      "description": "Main Rails application"
    },
    "gusto-deprecation": {
      "path": "components/gusto-deprecation",
      "type": "ruby",
      "description": "Gusto deprecation component gem"
    }
  },
  "commands": {
    "rubocop": {
      "location": "root",
      "description": "Always run from repo root"
    },
    "rspec": {
      "location": "subproject",
      "command": "bundle exec rspec",
      "overrides": {
        "root": {
          "command": "bin/rspec",
          "description": "Root project uses bin/rspec wrapper"
        }
      }
    }
  }
}
```

**Step 4: Commit examples**

```bash
git add home/.claude/skills/working-in-monorepos/examples/
git commit -m "docs: add example config files for monorepo skill"
```

---

## Task 15: Final Verification and Documentation

**Files:**

- Create: `home/.claude/skills/working-in-monorepos/README.md`

**Step 1: Run final skill test**

Run all test scenarios one more time with the completed skill to verify bulletproof status.

**Step 2: Create README**

Create `home/.claude/skills/working-in-monorepos/README.md`:

```markdown
# Working in Monorepos Skill

## Purpose

Helps Claude work effectively in monorepo environments by ensuring commands execute from correct locations using absolute paths.

## Problem Solved

Claude often loses track of directory context in monorepos, leading to:

- Redundant cd commands (`cd ruby && cd ruby`)
- Assuming current directory
- Commands executing from wrong locations

## Solution

**Core rule:** Always use absolute paths with explicit cd prefix for every command.

## Testing

Skill was developed using TDD methodology:

- RED: Baseline tests document failures without skill
- GREEN: Minimal skill addresses baseline failures
- REFACTOR: Iteratively close loopholes until bulletproof

See `tests/` directory for:

- `baseline-scenarios.md`: Test scenarios
- `baseline-results.md`: Failures without skill
- `green-results.md`: Results with skill, iteration notes

## Files

- `SKILL.md`: Main skill document
- `examples/`: Example .monorepo.json configs
- `tests/`: TDD test scenarios and results
- `../../bin/monorepo-init`: Init script for config generation

## Usage

The skill activates automatically when working in monorepos. It will:

1. Check for `.monorepo.json`
2. Offer to run `bin/monorepo-init` if missing
3. Enforce absolute path usage for all commands

## Related Tools

- `bin/monorepo-init`: Auto-detect subprojects and generate config
```

**Step 3: Commit README**

```bash
git add home/.claude/skills/working-in-monorepos/README.md
git commit -m "docs: add README for monorepo skill"
```

**Step 4: Run format check**

```bash
npm run format
npm test
```

**Step 5: Final commit if formatting changes**

```bash
git add -A
git commit -m "style: format all files with prettier"
```

---

## Task 16: Merge to Main (Optional)

**Files:**

- N/A (git operations)

**Step 1: Review all commits**

```bash
git log --oneline main..HEAD
```

Verify:

- Commits follow conventional commit format
- Each commit is focused and atomic
- No WIP or fixup commits

**Step 2: Push feature branch**

```bash
git push -u origin feature/monorepo-skill
```

**Step 3: Create pull request (if desired)**

```bash
gh pr create --title "Add working-in-monorepos skill and init script" --body "$(
  cat << 'EOF'
## Summary

- Adds `working-in-monorepos` skill to help Claude work in monorepo environments
- Adds `bin/monorepo-init` script for auto-detecting subprojects
- Enforces absolute path usage to prevent directory confusion
- Includes TDD test scenarios and results

## Testing

Skill developed using TDD methodology:
- Baseline tests documented failures without skill
- Iteratively refined until bulletproof against rationalizations
- Init script manually tested

## Files Added

- `home/.claude/skills/working-in-monorepos/SKILL.md`
- `home/.claude/skills/working-in-monorepos/examples/`
- `home/.claude/skills/working-in-monorepos/tests/`
- `bin/monorepo-init`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**Step 4: If no PR needed, merge directly**

```bash
git checkout main
git merge --no-ff feature/monorepo-skill
git push origin main
```

---

## Verification Checklist

Before considering this plan complete:

- [ ] All baseline test scenarios documented
- [ ] Baseline tests run, failures documented verbatim
- [ ] Minimal skill written addressing baseline failures
- [ ] GREEN tests run, skill verified working
- [ ] Rationalizations found, explicit counters added (REFACTOR)
- [ ] Re-verified after REFACTOR, skill bulletproof
- [ ] Init script structure created
- [ ] Detection logic implemented
- [ ] JSON generation implemented
- [ ] Init script manually tested
- [ ] Any init script issues fixed
- [ ] CLAUDE.md updated
- [ ] Example configs created
- [ ] README written
- [ ] All formatting checks pass
- [ ] Ready to merge or create PR

## Notes

**Key principles applied:**

- **TDD:** RED-GREEN-REFACTOR cycle for skill development
- **DRY:** Init script reusable, skill focused on methodology
- **YAGNI:** No speculative features, address actual failures only
- **Frequent commits:** Each task is one commit

**Testing strategy:**

- Pressure scenarios reveal rationalizations
- Iterate until bulletproof (no new rationalizations)
- Document all failures and fixes

**Architecture:**

- Skill = methodology + rules
- Script = tooling + detection
- Config = optional, skill works without it
