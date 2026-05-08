# Consolidate DOTPICKLES_ROLE Detection Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make a single `bin/dotpickles-role` bash script the canonical source of truth for role detection across `install.sh`, fish, zsh, and `claudeconfig.sh`, with a gitignored override file for explicit per-machine overrides.

**Architecture:**

- **One detection script**: `bin/dotpickles-role` (POSIX bash, no deps), prints role to stdout, exits 0.
- **Resolution order** (first match wins):
  1. `$DOTPICKLES_ROLE` env var (if non-empty and a known role)
  2. `$DIR/.dotpickles-role` (gitignored override file in repo root, single line)
  3. `~/.config/dotpickles/role` (XDG location for non-repo callers)
  4. Container detection (`/.dockerenv`, `DOCKER_BUILD`, cgroup) → `container`
  5. Hostname regex `^josh-nichols-` → `work`
  6. Default → `personal` (with stderr warning when reached via fall-through)
- **Canonical vocabulary**: `personal`, `work`, `container`. The `home` name is retired entirely.
- **Consumers** (`install.sh`, `config.fish`, `.zshenv`, `claudeconfig.sh`) all call `bin/dotpickles-role` and export the result. Each keeps its own `export`/`set -gx` shape, but the value comes from the script.
- **Fish predicate** `dotpickles_role` stays for ergonomic conf.d checks (`if dotpickles_role "personal"`); two callers in `conf.d/` get renamed `home` → `personal`.
- **Universal-variable cleanup**: `config.fish` runs `set -eU DOTPICKLES_ROLE` on shell init to evict the stale value persisted in fish_variables.

**Tech Stack:** bash, fish, zsh, bats-style raw-bash assertion test (no new deps).

**Beans:** dotfiles-h7kh (this work), dotfiles-w9y9 (home/personal naming, gets resolved by this).

---

## Pre-flight

Before starting, agree on these decisions (recorded above; flag if any need to change):

- Override file lives at **repo-relative** `.dotpickles-role` (gitignored), **plus** `~/.config/dotpickles/role` for non-repo callers.
- Vocabulary expands to `personal | work | container`. No `home`.
- Hostname rule stays `^josh-nichols-` matches → `work`. (Add to override file if you want different behavior.)
- Falling through to the hostname/default branch warns to stderr so silent miscategorization gets noticed.
- The script is idempotent and side-effect-free aside from one stderr line.

---

### Task `dotpickles-role-script`: Write the canonical bash detector

**Files:**

- Create: `bin/dotpickles-role`
- Create: `test/dotpickles-role.sh`

**Step 1: Write the failing test**

Create `test/dotpickles-role.sh`:

```bash
#!/usr/bin/env bash
# Test harness for bin/dotpickles-role. No external deps.
# Each case sets up an isolated env, runs the script, asserts on stdout.

set -u
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/bin/dotpickles-role"
PASS=0
FAIL=0

assert_eq() {
  local label="$1" want="$2" got="$3"
  if [[ "$got" == "$want" ]]; then
    PASS=$((PASS + 1))
    printf '  ok    %s\n' "$label"
  else
    FAIL=$((FAIL + 1))
    printf '  FAIL  %s — want %q, got %q\n' "$label" "$want" "$got"
  fi
}

# Helper: run the script in a clean env with controlled inputs.
# Args: <test-name> <expected> [extra env...]
run_case() {
  local label="$1" want="$2"
  shift 2
  local got
  got="$(env -i HOME="$HOME" PATH="/usr/bin:/bin" "$@" "$SCRIPT" 2> /dev/null)"
  assert_eq "$label" "$want" "$got"
}

# 1. Explicit env var wins over everything
run_case "env var: personal" personal DOTPICKLES_ROLE=personal HOSTNAME=josh-nichols-mbp
run_case "env var: work" work DOTPICKLES_ROLE=work HOSTNAME=anything
run_case "env var: container" container DOTPICKLES_ROLE=container

# 2. Empty env var falls through (does not stick at empty)
run_case "empty env falls through" personal DOTPICKLES_ROLE=

# 3. Unknown env var falls through with warning (does not propagate)
run_case "unknown env falls through" personal DOTPICKLES_ROLE=banana

# 4. Override file beats hostname
TMP_REPO="$(mktemp -d)"
echo "work" > "$TMP_REPO/.dotpickles-role"
got="$(env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTPICKLES_REPO="$TMP_REPO" "$SCRIPT" 2> /dev/null)"
assert_eq "override file: work" "work" "$got"
rm -rf "$TMP_REPO"

# 5. XDG override file
TMP_HOME="$(mktemp -d)"
mkdir -p "$TMP_HOME/.config/dotpickles"
echo "container" > "$TMP_HOME/.config/dotpickles/role"
got="$(env -i HOME="$TMP_HOME" PATH="/usr/bin:/bin" "$SCRIPT" 2> /dev/null)"
assert_eq "xdg override file: container" "container" "$got"
rm -rf "$TMP_HOME"

# 6. Hostname regex
run_case "hostname work" work DOTPICKLES_HOSTNAME=josh-nichols-mbp
run_case "hostname personal default" personal DOTPICKLES_HOSTNAME=somethingelse

# 7. Container marker
run_case "container env hint" container DOCKER_BUILD=1

# 8. Fall-through default emits a stderr warning
stderr="$(env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTPICKLES_HOSTNAME=other "$SCRIPT" 2>&1 > /dev/null)"
case "$stderr" in
  *defaulting* | *default*)
    PASS=$((PASS + 1))
    echo "  ok    fall-through warns"
    ;;
  *)
    FAIL=$((FAIL + 1))
    printf '  FAIL  fall-through warns — got %q\n' "$stderr"
    ;;
esac

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
```

Make it executable: `chmod +x test/dotpickles-role.sh`

**Step 2: Run test to verify it fails**

Run: `./test/dotpickles-role.sh`
Expected: every case fails (script does not exist yet).

**Step 3: Write minimal implementation**

Create `bin/dotpickles-role`:

```bash
#!/usr/bin/env bash
# Print the active dotpickles role (personal | work | container).
#
# Resolution order (first match wins):
#   1. $DOTPICKLES_ROLE env var (must be a known role)
#   2. <repo>/.dotpickles-role override file (gitignored)
#   3. ~/.config/dotpickles/role
#   4. container marker (/.dockerenv, $DOCKER_BUILD, cgroup)
#   5. hostname regex
#   6. default 'personal' (warns to stderr)
#
# DOTPICKLES_REPO and DOTPICKLES_HOSTNAME are recognized for testability.

set -u

KNOWN_ROLES_RE='^(personal|work|container)$'

emit() {
  printf '%s\n' "$1"
  exit 0
}

# 1. env var
if [[ -n "${DOTPICKLES_ROLE:-}" ]]; then
  if [[ "$DOTPICKLES_ROLE" =~ $KNOWN_ROLES_RE ]]; then
    emit "$DOTPICKLES_ROLE"
  else
    printf 'dotpickles-role: ignoring unknown DOTPICKLES_ROLE=%q\n' "$DOTPICKLES_ROLE" >&2
  fi
fi

# 2. repo override file
repo="${DOTPICKLES_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
if [[ -f "$repo/.dotpickles-role" ]]; then
  role="$(tr -d '[:space:]' < "$repo/.dotpickles-role")"
  if [[ "$role" =~ $KNOWN_ROLES_RE ]]; then
    emit "$role"
  fi
fi

# 3. XDG override file
xdg="${XDG_CONFIG_HOME:-$HOME/.config}/dotpickles/role"
if [[ -f "$xdg" ]]; then
  role="$(tr -d '[:space:]' < "$xdg")"
  if [[ "$role" =~ $KNOWN_ROLES_RE ]]; then
    emit "$role"
  fi
fi

# 4. container detection
if [[ -f /.dockerenv ]] \
  || [[ -n "${DOCKER_BUILD:-}" ]] \
  || (grep -qE 'docker|lxc|containerd' /proc/1/cgroup 2> /dev/null); then
  emit container
fi

# 5. hostname regex
if [[ -n "${DOTPICKLES_HOSTNAME:-}" ]]; then
  hn="$DOTPICKLES_HOSTNAME"
elif hn="$(hostnamectl hostname 2> /dev/null)"; then
  :
else
  hn="$(hostname 2> /dev/null || echo)"
fi
if [[ "$hn" =~ ^josh-nichols- ]]; then
  emit work
fi

# 6. default
printf 'dotpickles-role: defaulting to personal (hostname=%q)\n' "$hn" >&2
emit personal
```

Make it executable: `chmod +x bin/dotpickles-role`

**Step 4: Run test to verify it passes**

Run: `./test/dotpickles-role.sh`
Expected: all cases pass.

**Step 5: Commit**

```bash
git add bin/dotpickles-role test/dotpickles-role.sh
git commit -m "feat(role): add canonical bin/dotpickles-role detector with tests"
```

---

### Task `gitignore-override`: Ignore the override file

**Files:**

- Modify: `.gitignore`

**Step 1: Add the entry**

Append to `.gitignore`:

```gitignore
# dotpickles role override (machine-local, set explicitly when hostname rule is wrong)
.dotpickles-role
```

**Step 2: Verify**

Run: `git check-ignore -v .dotpickles-role`
Expected: prints the .gitignore line that matches.

Run: `echo personal > .dotpickles-role && git status`
Expected: `.dotpickles-role` is **not** in untracked files.

Clean up: `rm .dotpickles-role`.

**Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: gitignore .dotpickles-role override file"
```

---

### Task `install-sh-uses-script`: Wire `install.sh` to the canonical detector

**Files:**

- Modify: `install.sh:25-39`

**Step 1: Replace inline detection**

Before:

```bash
if [[ -z "${DOTPICKLES_ROLE}" ]]; then
  if hostname=$(hostnamectl hostname 2> /dev/null); then
    :
  else
    hostname=$(hostname)
  fi
  if [[ "$hostname" =~ ^josh-nichols- ]]; then
    DOTPICKLES_ROLE="work"
  else
    DOTPICKLES_ROLE="personal"
  fi
fi

export DOTPICKLES_ROLE
echo "role: $DOTPICKLES_ROLE"
```

After:

```bash
DOTPICKLES_ROLE="$("$DIR/bin/dotpickles-role")"
export DOTPICKLES_ROLE
echo "role: $DOTPICKLES_ROLE"
```

**Step 2: Verify**

Run: `DOTPICKLES_ROLE= bash -c 'cd "$(pwd)" && DIR=$(pwd) && bash -c "$(sed -n "25,39p" install.sh)"'` — actually just easier:

Run: `bash -c 'cd '"$PWD"' && source ./install.sh; echo "role=$DOTPICKLES_ROLE"' 2>&1 | head -5`

…or simpler, dry-run by extracting the relevant lines into a scratch script. Quickest: temporarily run only the role-detection part.

Run: `DOTPICKLES_ROLE=work ./bin/dotpickles-role` → prints `work`.
Run: `DOTPICKLES_ROLE= ./bin/dotpickles-role` → prints `personal` (or `work` if on a `josh-nichols-*` machine).

**Step 3: Commit**

```bash
git add install.sh
git commit -m "refactor(install): use bin/dotpickles-role for role detection"
```

---

### Task `fish-uses-script`: Wire fish to the canonical detector and evict universal var

**Files:**

- Modify: `config/fish/config.fish:1-5`
- Modify: `config/fish/functions/dotpickles_role.fish` (no logic change, but add header comment)

**Step 1: Replace fish role detection**

Before (`config/fish/config.fish` lines 1-5):

```fish
if string match --quiet --regex '^josh-nichols-' (hostname)
    set -gx DOTPICKLES_ROLE work
else
    set -gx DOTPICKLES_ROLE home
end
```

After:

```fish
# DOTPICKLES_ROLE comes from the canonical bash detector. We evict any stale
# universal var first because fish persists -Ux values in fish_variables and
# they would otherwise survive across shells even after we change the source.
set -e -U DOTPICKLES_ROLE 2>/dev/null
set -gx DOTPICKLES_ROLE (~/.pickles/bin/dotpickles-role)
```

**Step 2: Manually evict the persisted universal var on this machine**

The persisted universal var is in the gitignored `config/fish/fish_variables` file. The shell's first run of the new `config.fish` will erase it via `set -e -U`, but to make it stick before the user opens a new shell:

Run: `fish -c "set -e -U DOTPICKLES_ROLE"`
Run: `grep -c 'DOTPICKLES_ROLE' config/fish/fish_variables` → expect `0`.

**Step 3: Verify in a fresh shell**

Run: `fish -c 'echo $DOTPICKLES_ROLE'`
Expected: prints `personal` (or whatever `bin/dotpickles-role` returns on this machine), and matches `bash -c './bin/dotpickles-role'`.

**Step 4: Commit**

```bash
git add config/fish/config.fish
git commit -m "refactor(fish): use bin/dotpickles-role and evict stale universal var"
```

---

### Task `rename-home-to-personal`: Update fish conf.d callers to canonical role names

**Files:**

- Modify: `config/fish/conf.d/git-duet.fish:1`
- Modify: `config/fish/conf.d/rustup.fish:1`

**Step 1: Replace literal "home" with "personal"**

Both files start with `if dotpickles_role "home"`. Change to `if dotpickles_role "personal"`.

**Step 2: Verify**

Run: `grep -rn '"home"' config/fish/`
Expected: no remaining matches that refer to a role.

Run: `fish -c 'dotpickles_role "personal"; and echo "yes"'`
Expected: prints `yes` on a personal-role machine.

**Step 3: Commit**

```bash
git add config/fish/conf.d/git-duet.fish config/fish/conf.d/rustup.fish
git commit -m "fix(fish): rename 'home' role check to 'personal' to match canonical vocabulary"
```

---

### Task `zshenv-uses-script`: Wire zsh to the canonical detector

**Files:**

- Modify: `home/.zshenv:13-20`

**Step 1: Replace inline detection**

Before:

```zsh
# Determine role based on hostname (consistent with fish config.fish)
if [[ -f /.dockerenv ]] || grep -q 'docker\|lxc\|containerd' /proc/1/cgroup 2> /dev/null || [[ -n "$DOCKER_BUILD" ]]; then
  export DOTPICKLES_ROLE=container
elif [[ "$(hostname)" =~ ^josh-nichols- ]]; then
  export DOTPICKLES_ROLE=work
else
  export DOTPICKLES_ROLE=personal
fi
```

After:

```zsh
# Role comes from the canonical detector. Falls back gracefully if the dotfiles
# repo isn't checked out yet (first-time bootstrap).
if [[ -x "$HOME/.pickles/bin/dotpickles-role" ]]; then
  export DOTPICKLES_ROLE="$("$HOME/.pickles/bin/dotpickles-role")"
else
  export DOTPICKLES_ROLE=personal
fi
```

**Step 2: Verify**

Run: `zsh -c 'source ~/.zshenv && echo "$DOTPICKLES_ROLE"'`
Expected: matches the output of `./bin/dotpickles-role`.

**Step 3: Commit**

```bash
git add home/.zshenv
git commit -m "refactor(zsh): use bin/dotpickles-role for role detection"
```

---

### Task `claudeconfig-warn-on-missing`: Make `claudeconfig.sh` use the script and warn on missing role files

**Files:**

- Modify: `claudeconfig.sh:50-51` and the role-merge block (look for `role_file`)

**Step 1: Replace the silent default**

Before:

```bash
# Detect role (uses existing DOTPICKLES_ROLE from environment)
ROLE="${DOTPICKLES_ROLE:-personal}"
echo "Configuring Claude Code for role: $ROLE"
```

After:

```bash
# Always re-derive from the canonical detector so a stale shell env doesn't
# silently miscategorize. Honors any explicit DOTPICKLES_ROLE the user set.
ROLE="$("$DIR/bin/dotpickles-role")"
echo "Configuring Claude Code for role: $ROLE"
```

**Step 2: Add the loud warning when the role file is missing**

Find the block that merges the role file (approximately):

```bash
if [ -f "$role_file" ] && [ "$ROLE" != "base" ]; then
  # ... merge role
fi
```

Add an `else` branch that prints to stderr and continues with a non-zero indicator. Concrete change:

```bash
if [ "$ROLE" != "base" ]; then
  if [ -f "$role_file" ]; then
    # ... existing merge
  else
    printf 'claudeconfig.sh: WARNING: no role file at %s — settings.json will be missing role-specific config\n' "$role_file" >&2
  fi
fi
```

**Step 3: Verify**

Run: `DOTPICKLES_ROLE=banana ./claudeconfig.sh 2>&1 | head -5`
Expected: `dotpickles-role: ignoring unknown DOTPICKLES_ROLE=banana` and continues with the resolved role.

Run: `DOTPICKLES_ROLE=container ./claudeconfig.sh 2>&1 | grep WARNING`
Expected: prints the WARNING line about the missing `claude/roles/container.jsonc` (since we don't have one yet — this is intentional and the warning is the point).

**Step 4: Commit**

```bash
git add claudeconfig.sh
git commit -m "fix(claudeconfig): use canonical role detector and warn on missing role file"
```

---

### Task `docs-and-adr`: Document the consolidation

**Files:**

- Modify: `doc/architecture.md` (the "Role-Based Configuration System" section)
- Create: `doc/adr/0021-canonical-role-detection.md`

**Step 1: Update architecture.md**

In the "Role-Based Configuration System" section, replace:

> Role detection logic is in [install.sh:12-23](../install.sh#L12-L23). The role defaults to "work" for hostnames matching `josh-nichols-*`, otherwise "personal".

…with a paragraph pointing to `bin/dotpickles-role` as the single source of truth, listing the resolution order, mentioning the override files, and noting the canonical vocabulary (`personal | work | container`).

**Step 2: Write ADR**

Use the existing ADR template:

```bash
bin/adr new "Canonical role detection via bin/dotpickles-role"
```

Body covers:

- **Context**: five separate detection sites, three vocabularies, silent miscategorization.
- **Decision**: single bash script as source of truth; resolution order; gitignored override file; canonical `personal | work | container`; loud stderr on fall-through and on unknown overrides.
- **Consequences**: small per-shell `exec` cost; one place to change; fish universal-var requires a one-shot eviction.
- Cross-links: ADR 0009 (envsense) — note the role layer is orthogonal to envsense's runtime detection.

**Step 3: Verify**

Run: `npm run lint`
Expected: passes (prettier formats the ADR if needed).

**Step 4: Commit**

```bash
git add doc/architecture.md doc/adr/0021-*.md
git commit -m "docs: ADR 0021 + architecture update for canonical role detection"
```

---

### Task `close-w9y9-and-h7kh`: Update beans

**Step 1: Resolve dotfiles-w9y9**

Its checklist items are all addressed by this work (fish renamed to `personal`, `claudeconfig.sh` warns on missing role, fresh-shell verification done). Mark complete:

```bash
beans update dotfiles-w9y9 --status completed
```

**Step 2: Mark dotfiles-h7kh complete**

```bash
beans update dotfiles-h7kh --status completed
```

**Step 3: Commit the bean status changes**

```bash
git add .beans/
git commit -m "chore(beans): close out role-detection consolidation"
```

---

### Task `final-verify`: End-to-end verification

**Step 1: All tests + lint**

Run: `./test/dotpickles-role.sh`
Expected: all pass.

Run: `npm run lint`
Expected: passes.

**Step 2: Cross-shell consistency**

Run all four and verify they print the same value:

```bash
./bin/dotpickles-role
bash -c 'source ./install.sh' 2>&1 | grep '^role:'
fish -c 'echo $DOTPICKLES_ROLE'
zsh -c 'source ~/.zshenv && echo $DOTPICKLES_ROLE'
```

Expected: same value across all four (e.g., `personal` on this machine).

**Step 3: Override file works**

```bash
echo work > .dotpickles-role
./bin/dotpickles-role                          # → work
DOTPICKLES_ROLE= ./bin/dotpickles-role         # → work (override file beats fall-through)
DOTPICKLES_ROLE=personal ./bin/dotpickles-role # → personal (env beats override)
rm .dotpickles-role
```

**Step 4: Final lint pass and the user has the floor**

Run: `npm run lint`

Hand off to the user for installation verification (`./install.sh --yes`) on a representative machine.

---

## Out of scope (capture as new beans if needed)

- Creating `claude/roles/container.jsonc` (the warning will fire on container machines until this exists). Decide separately whether `container` machines should use a tailored Claude config or just fall back to base.
- Migrating users away from manually setting `DOTPICKLES_ROLE` in shell rc files (none currently do; the override file is the documented alternative).
- A "cross-shell drift" CI check (e.g., a script that verifies all four detection paths agree). Worth a feature bean if drift recurs.
