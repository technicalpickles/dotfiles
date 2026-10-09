# Hardened Homebrew Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make this dotfiles repo (and the home Mac) work under automic-vault's hardened Homebrew (`av harden brew`), which forbids `brew services`, `brew bundle`, and app casks.

**Architecture:** Replace each forbidden Homebrew feature with something dotfiles already knows how to do: `brew services` becomes a dotfiles-managed LaunchAgent, `brew bundle` becomes a small formula installer in `functions.sh`, and app casks move to an `Appfile` manifest that `install.sh` and `bin/dotfiles-doctor` check, leaving apps to update themselves. Shell setup learns to find the hardened `/usr/local/bin/brew` launcher. A one-off script lets Homebrew forget app casks without deleting the apps.

**Tech Stack:** bash (macOS `/bin/bash` 3.2 compatible), zsh, fish, launchd plists, mise, jq, prettier (`prettier-plugin-sh`).

**Spec:** bean `dotfiles-4tco` (`.beans/dotfiles-4tco--make-dotfiles-this-mac-compatible-with-hardened-ho.md` in the main checkout). Upstream behavior lives in `~/github.com/automic-vault/automic-vault`: `src/isotopes/hardeners/homebrew.md`, `src/isotopes/hardeners/homebrew.rs`, `src/brew_stub/main.rs`.

## Global Constraints

- Hardened brew: `/usr/local/bin/brew` is a setuid/setgid launcher (`06755 automic:vault`); `/opt/homebrew` is owned `automic:vault`; the launcher runs brew with `HOME=/opt/homebrew/var/automic` and a scrubbed environment.
- `brew bundle` hard-errors under the launcher: "`brew bundle` is unavailable because Brewfiles may contain casks; run formula commands directly".
- Mutating commands without `--cask` get `--formula` inserted. A Brewfile `brew 'x'` line that is really a cask (e.g. `orbstack`) fails.
- Casks allowed only from official `homebrew/cask`, `binary` artifacts only, targets directly in `/opt/homebrew/bin`. Cask mutations must name every cask explicitly.
- Hardening refuses while any `brew services` entry has status other than `none` or a non-null user, or while `/opt/homebrew/Caskroom` holds a non-CLI-only cask.
- Every brew invocation goes through menu-bar approval; installs/upgrades need explicit Approval at the default "Read & Update" level. Batch installs into one command.
- `/usr/local/bin` must precede `/opt/homebrew/bin` in `PATH` once hardened. Never invoke `/opt/homebrew/bin/brew` directly once hardened.
- `av harden brew` offers to rewrite the literal string `/opt/homebrew/bin/brew` to `/usr/local/bin/brew` in `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.config/fish/config.fish`. Those are symlinks into this repo; answer **N** (this plan makes the files stub-aware instead).
- Repo conventions: shell scripts formatted by prettier-plugin-sh (`2> /dev/null` spacing, 2-space indent); `npm run lint` is the test suite; manual harnesses live in `scripts/test-*.sh`; ADRs via `bin/adr new`; LaunchAgents under `LaunchAgents/{,arm64-macos/,home/}` linked by `symlinks.sh`.
- Commit messages follow the repo's `area: summary` style.
- End every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

- **Brewfile aliases** (`gpg` is installed as `gnupg`, `nvim` as `neovim`): a naive "is it in `brew list`" check reports them missing forever and fires an approval prompt on every `install.sh`. Expected: already-installed aliases are not reinstalled. Pinned in `brewfile-installer` (Test 3).
- **Fresh machine with no `jq` yet**: Homebrew was just installed, nothing else. Expected: installer still installs everything rather than crashing. Pinned in `brewfile-installer` (Test 4).
- **Brewfile syntax variety**: double quotes (`brew "hyperfine"`), trailing comments, commented-out lines (`#brew 'specstory'`), `# frozen_string_literal`. Expected: only live `tap`/`brew`/`cask` lines count. Pinned in `brewfile-installer` (Test 1).
- **App installed in `~/Applications`** instead of `/Applications`: expected not reported missing. Pinned in `appfile` (Test 2).
- **Intel/Rosetta Homebrew at `/usr/local/bin/brew`** (a normal, non-setuid file): expected to be treated as before, not as the hardened launcher. Pinned in `stub-aware-shell-setup` (Test 3).

---

## File Structure

| File                                                  | Change | Responsibility                                                                                                                                                                |
| ----------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `doc/adr/0058-hardened-homebrew-compatibility.md`     | create | Why services/bundle/casks moved out of Homebrew                                                                                                                               |
| `LaunchAgents/home/com.technicalpickles.ollama.plist` | create | ollama server, replaces `brew services`                                                                                                                                       |
| `scripts/test-launchagent-plists.sh`                  | create | lint all plists; forbid writes into the protected prefix                                                                                                                      |
| `Brewfile`, `Brewfile.home`                           | modify | drop app casks and `brew 'orbstack'`; add `ollama`, `1password-cli`                                                                                                           |
| `config/mise/conf.d/dotfiles.toml`                    | modify | install `beans` via mise                                                                                                                                                      |
| `functions.sh`                                        | modify | `brewfile_entries`, `missing_brew_packages`, `brew_install_brewfiles`, `missing_apps`, `report_missing_apps`, stub-aware `load_brew_shellenv`, `op_ensure_signed_in` cask fix |
| `install.sh`                                          | modify | call `brew_install_brewfiles` + `report_missing_apps`                                                                                                                         |
| `scripts/test-brew-install-brewfiles.sh`              | create | harness for the installer                                                                                                                                                     |
| `home/.zshenv`                                        | modify | stub-aware brew env                                                                                                                                                           |
| `config/fish/conf.d/__homebrew.fish`                  | modify | stub-aware brew env                                                                                                                                                           |
| `scripts/test-brew-shellenv.sh`                       | create | harness for zsh/fish brew env                                                                                                                                                 |
| `Appfile`, `Appfile.home`, `Appfile.work`             | create | app manifest replacing casks                                                                                                                                                  |
| `bin/dotfiles-doctor`                                 | modify | report missing Appfile apps                                                                                                                                                   |
| `scripts/test-missing-apps.sh`                        | create | harness for `missing_apps`                                                                                                                                                    |
| `scripts/detach-cask.sh`                              | create | make brew forget an app cask without deleting the app                                                                                                                         |
| `scripts/test-detach-cask.sh`                         | create | harness for detach                                                                                                                                                            |
| `doc/architecture.md`, `bin/CLAUDE.md`                | modify | document the above                                                                                                                                                            |

All implementation tasks run in the worktree `.claude/worktrees/hardened-brew` (branch `hardened-brew`). The `cutover` task runs from the main checkout **after merge**, because `symlinks.sh` links files by absolute path and links into a worktree would dangle once it's removed.

---

### Task: `adr`

Written first so every later code comment can cite a fixed ADR number.

**Files:**

- Create: `doc/adr/0058-hardened-homebrew-compatibility.md`

**Interfaces:**

- Produces: ADR number used in comments by later tasks. Expected `0058`; if `bin/adr new` assigns a different number, use that number everywhere this plan says `0058`.

- [ ] **Step 1: Create the ADR skeleton**

Run: `bin/adr new "Hardened Homebrew compatibility"`
Expected: prints a path like `doc/adr/0058-hardened-homebrew-compatibility.md`.

- [ ] **Step 2: Fill in the ADR body**

Replace the generated body (keep the generated title/date lines) with:

```markdown
## Status

Accepted

## Context

automic-vault's Homebrew hardener (`av harden brew`) makes `/opt/homebrew`
owned by a dedicated `automic` user and installs a setuid launcher at
`/usr/local/bin/brew` that gates every brew command behind menu-bar approval.
This stops same-user code (malware, agents) from replacing installed tools.

Under it:

- `brew services` is unsupported. Hardening refuses while any service is
  loaded or registered. Upstream doesn't document why, but it follows from the
  design: brew runs as `automic` with `HOME=/opt/homebrew/var/automic`, so it
  can't install a plist into our `~/Library/LaunchAgents` or bootstrap into our
  `gui/<uid>` launchd domain, and service logs/state live in the now-protected
  prefix.
- `brew bundle` is refused outright, because Brewfiles may contain casks.
- Casks are refused unless they're official, CLI-only (`binary` artifacts into
  `/opt/homebrew/bin`). App and pkg casks reach outside the prefix.
- Shell startup must use `/usr/local/bin/brew` and put `/usr/local/bin` ahead
  of `/opt/homebrew/bin`.

## Decision

- Long-running services are dotfiles LaunchAgents (`LaunchAgents/`), pointing
  at stable `/opt/homebrew/opt/<formula>/bin/...` paths, with logs outside
  `/opt/homebrew`. This was already the pattern for gost and sleepwatcher.
- `install.sh` installs formulae (and CLI-only casks) with
  `brew_install_brewfiles` in `functions.sh`: one `brew install --formula`
  call for whatever is missing, so approval fires once.
- Mac apps are listed in `Appfile`/`Appfile.<role>` and installed by hand from
  the vendor. They update themselves. `install.sh` and `bin/dotfiles-doctor`
  report missing ones with a download link; nothing downloads installers
  unattended.
- Shell setup (`home/.zshenv`, `config/fish/conf.d/__homebrew.fish`,
  `load_brew_shellenv`) detects the launcher by its setuid bit and sets the
  Homebrew env statically, so no brew process spawns per shell start.

## Consequences

- No more `brew upgrade` for apps; each app's own updater handles it. Finicky
  has no auto-updater and needs a manual check now and then.
- A second user-owned Homebrew just for casks was rejected: it makes `brew`
  ambiguous and reopens the unattended installs the vault exists to gate.
- When `av harden brew` offers to rewrite shell startup files, answer N; the
  repo's files already handle both modes.
- Unhardened machines (work, containers) behave exactly as before.
```

- [ ] **Step 3: Lint**

Run: `npm run lint`
Expected: exit 0. If prettier reformats, run `npm run format` and re-run lint.

- [ ] **Step 4: Commit**

```bash
git add doc/adr/0058-hardened-homebrew-compatibility.md
git commit -m "adr: hardened Homebrew compatibility

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task: `ollama-launchagent`

**Files:**

- Create: `scripts/test-launchagent-plists.sh`
- Create: `LaunchAgents/home/com.technicalpickles.ollama.plist`
- Modify: `Brewfile.home` (add `brew 'ollama'`)

**Interfaces:**

- Produces: launchd label `com.technicalpickles.ollama`; logs at `/tmp/com.technicalpickles.ollama.{out,err}` (matches the repo's other agents). Used by `cutover`.

Home-role only because ollama is only installed on the home Mac. The plist hard-codes `/opt/homebrew`, which is fine because every home-role Mac is Apple Silicon (same assumption as the existing `home/` and `arm64-macos/` agents).

- [ ] **Step 1: Write the plist guard harness**

Create `scripts/test-launchagent-plists.sh`:

```bash
#!/usr/bin/env bash
# Lint every repo LaunchAgent plist and enforce hardened-Homebrew rules:
#   - plutil must accept it
#   - Label must match the filename
#   - nothing may write into /opt/homebrew/var or /opt/homebrew/etc, which
#     hardened Homebrew makes unwritable for us (see ADR 0058)
#
# Usage:
#   ./scripts/test-launchagent-plists.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

for plist in "$REPO_ROOT"/LaunchAgents/*.plist "$REPO_ROOT"/LaunchAgents/*/*.plist; do
  [ -f "$plist" ] || continue
  name="${plist#"$REPO_ROOT"/}"

  if ! plutil -lint -s "$plist"; then
    echo "FAIL: $name does not lint"
    FAIL=1
    continue
  fi

  label="$(plutil -extract Label raw -o - "$plist" 2> /dev/null)"
  if [ "$label.plist" != "$(basename "$plist")" ]; then
    echo "FAIL: $name has Label '$label', expected '$(basename "$plist" .plist)'"
    FAIL=1
  fi

  if grep -qE '/opt/homebrew/(var|etc)' "$plist"; then
    echo "FAIL: $name references /opt/homebrew/var or /opt/homebrew/etc"
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "PASS: all LaunchAgent plists"
fi
exit "$FAIL"
```

Run: `chmod +x scripts/test-launchagent-plists.sh && ./scripts/test-launchagent-plists.sh`
Expected: `PASS: all LaunchAgent plists` (existing plists already comply). If an existing plist fails the Label check, stop and report it; don't rename existing agents in this task.

- [ ] **Step 2: Prove the guard catches the brew-style plist**

Run:

```bash
mkdir -p LaunchAgents/home
sed 's/homebrew.mxcl.ollama/com.technicalpickles.ollama/' ~/Library/LaunchAgents/homebrew.mxcl.ollama.plist > LaunchAgents/home/com.technicalpickles.ollama.plist
./scripts/test-launchagent-plists.sh
```

Expected: `FAIL: LaunchAgents/home/com.technicalpickles.ollama.plist references /opt/homebrew/var or /opt/homebrew/etc`, exit 1.

- [ ] **Step 3: Write the real plist**

Overwrite `LaunchAgents/home/com.technicalpickles.ollama.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.technicalpickles.ollama</string>
    <!-- Replaces `brew services start ollama`, which hardened Homebrew
         doesn't support (ADR 0058). opt/ollama is a stable symlink across
         upgrades; after `brew upgrade ollama`, run
         `launchctl kickstart -k gui/$UID/com.technicalpickles.ollama`. -->
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/opt/ollama/bin/ollama</string>
        <string>serve</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <!-- Carried over from the Homebrew service definition. -->
    <key>EnvironmentVariables</key>
    <dict>
        <key>OLLAMA_FLASH_ATTENTION</key>
        <string>1</string>
        <key>OLLAMA_KV_CACHE_TYPE</key>
        <string>q8_0</string>
    </dict>
    <!-- Logs stay out of /opt/homebrew/var, which is unwritable once hardened. -->
    <key>StandardOutPath</key>
    <string>/tmp/com.technicalpickles.ollama.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/com.technicalpickles.ollama.err</string>
</dict>
</plist>
```

- [ ] **Step 4: Run the guard**

Run: `./scripts/test-launchagent-plists.sh`
Expected: `PASS: all LaunchAgent plists`, exit 0.

- [ ] **Step 5: Declare ollama in Brewfile.home**

ollama was installed ad hoc. Now that a repo agent depends on it, add it to `Brewfile.home` directly after the `brew 'sleepwatcher'` line:

```ruby
brew 'ollama' # served by LaunchAgents/home/com.technicalpickles.ollama.plist
```

- [ ] **Step 6: Lint and commit**

Run: `npm run lint` (expected exit 0; run `npm run format` first if needed)

```bash
git add scripts/test-launchagent-plists.sh LaunchAgents/home/com.technicalpickles.ollama.plist Brewfile.home
git commit -m "launchagents: run ollama from a dotfiles agent instead of brew services

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task: `beans-via-mise`

**Files:**

- Modify: `config/mise/conf.d/dotfiles.toml`

**Interfaces:**

- Produces: `beans` on PATH via mise shims, independent of Homebrew. `cutover` removes the cask.

beans currently comes from the third-party cask `hmans/beans`, which hardening rejects.

- [ ] **Step 1: Check mise can fetch beans from GitHub releases**

Run: `mise exec github:hmans/beans@latest -- beans version`
Expected: prints a version (current cask is `0.4.2`; newer is fine).

If it fails because no release asset matches darwin-arm64, try the go backend instead:
Run: `mise exec go:github.com/hmans/beans@latest -- beans version`
Use whichever backend works in Step 2. If neither works, stop and report: this task then becomes "install beans from a release binary by hand" and needs a decision.

- [ ] **Step 2: Add beans to the shared mise tools**

In `config/mise/conf.d/dotfiles.toml`, under `[tools]`, add (keeping the existing alphabetical-ish order, after `"npm:markdownlint-cli2"`):

```toml
# beans (issue tracker used by this repo) lives here, not as a Homebrew cask:
# hardened Homebrew rejects third-party casks (ADR 0058), and mise also gets
# it onto Linux/the VM.
"github:hmans/beans" = "latest"
```

(Substitute `"go:github.com/hmans/beans"` if Step 1 needed the go backend.)

- [ ] **Step 3: Verify with this file's config**

Run: `MISE_CONFIG_DIR="$PWD/config/mise" mise ls 2>&1 | grep -i beans`
Expected: a beans line from this config. Then:
Run: `MISE_CONFIG_DIR="$PWD/config/mise" mise install && MISE_CONFIG_DIR="$PWD/config/mise" mise which beans`
Expected: a path under `~/.local/share/mise/installs/`.

- [ ] **Step 4: Lint and commit**

Run: `npm run lint`

```bash
git add config/mise/conf.d/dotfiles.toml
git commit -m "mise: install beans via mise instead of the hmans/beans cask

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task: `brewfile-installer`

**Files:**

- Modify: `functions.sh` (replace `brew_bundle` at `functions.sh:203-207`; fix `op_ensure_signed_in` at `functions.sh:216-225`)
- Modify: `install.sh:57` (`brew_bundle` → `brew_install_brewfiles`)
- Create: `scripts/test-brew-install-brewfiles.sh`

**Interfaces:**

- Produces (in `functions.sh`):

  - `brewfile_entries FILE...` → stdout lines `"<tap|brew|cask> <name>"`, one per live entry, in file order; missing files skipped silently.
  - `missing_brew_packages <formula|cask> NAME...` → stdout, one name per line, of packages not installed (canonical names from `brew info`); with no `jq`, echoes every NAME.
  - `brew_install_brewfiles` → taps missing taps, installs missing formulae in one `brew install --formula` and missing casks in one `brew install --cask`, reading `Brewfile` and `Brewfile.$DOTPICKLES_ROLE` from the current directory.

- [ ] **Step 1: Write the failing harness**

Create `scripts/test-brew-install-brewfiles.sh`:

```bash
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
```

Note on Test 5's last two lines: the stub's cask fixture always includes `mitmproxy` as uninstalled, so even though the Brewfile only names `1password-cli`, the stub reports `mitmproxy` missing. That's a property of the fixture, and it proves the install line uses `missing_brew_packages` output verbatim.

Run: `chmod +x scripts/test-brew-install-brewfiles.sh && ./scripts/test-brew-install-brewfiles.sh`
Expected: FAIL lines / `brewfile_entries: command not found` errors (functions don't exist yet), exit non-zero.

- [ ] **Step 2: Implement the installer in functions.sh**

Replace the whole `brew_bundle() { ... }` function (`functions.sh:203-207`) with:

```bash
# Print "<kind> <name>" for each live tap/brew/cask line in the given
# Brewfiles, in order. Comments, blank lines, other directives, and missing
# files are skipped.
brewfile_entries() {
  local file
  for file in "$@"; do
    [ -f "$file" ] || continue
    sed -nE "s/^[[:space:]]*(tap|brew|cask)[[:space:]]+['\"]([^'\"]+)['\"].*/\1 \2/p" "$file"
  done
}

# Print the names (one per line) of the given formulae or casks that aren't
# installed. `brew info` resolves aliases (gpg -> gnupg, nvim -> neovim) the
# same way brew does, so installed aliases don't look missing forever. Without
# jq (fresh machine), print every name and let `brew install` skip the rest.
missing_brew_packages() {
  local kind="$1"
  shift
  [ $# -gt 0 ] || return 0

  if ! command_available jq; then
    printf '%s\n' "$@"
    return 0
  fi

  if [ "$kind" = formula ]; then
    brew info --json=v2 --formula "$@" | jq -r '.formulae[] | select(.installed | length == 0) | .full_name'
  else
    brew info --json=v2 --cask "$@" | jq -r '.casks[] | select(.installed == null) | .full_token'
  fi
}

# Install what Brewfile + Brewfile.$DOTPICKLES_ROLE declare. Replaces
# `brew bundle`, which hardened Homebrew refuses to run (ADR 0058). Missing
# formulae and casks each go in a single `brew install` so the approval prompt
# fires at most once per kind.
brew_install_brewfiles() {
  echo "🍻 installing Brewfile packages"
  local entries
  entries="$(brewfile_entries Brewfile "Brewfile.${DOTPICKLES_ROLE}")"

  local installed_taps tap
  installed_taps="$(brew tap)"
  for tap in $(awk '$1 == "tap" { print $2 }' <<< "$entries"); do
    if ! grep -qxF "$tap" <<< "$installed_taps"; then
      brew tap "$tap" 2>&1 | sed 's/^/  → /'
    fi
  done

  # Brewfile keyword for each kind: `brew 'x'` is a formula, `cask 'x'` a cask.
  local kind word names missing
  for kind in formula cask; do
    word=brew
    [ "$kind" = cask ] && word=cask
    # shellcheck disable=SC2207
    names=($(awk -v k="$word" '$1 == k { print $2 }' <<< "$entries"))
    missing="$(missing_brew_packages "$kind" ${names[@]+"${names[@]}"})"
    if [ -n "$missing" ]; then
      # shellcheck disable=SC2086
      brew install "--$kind" $missing 2>&1 | sed 's/^/  → /'
    else
      echo "  → all ${kind} entries installed"
    fi
  done
  echo
}
```

- [ ] **Step 3: Run the harness**

Run: `./scripts/test-brew-install-brewfiles.sh`
Expected: all `PASS:` lines, exit 0.

- [ ] **Step 4: Fix `op_ensure_signed_in` for hardened brew**

In `op_ensure_signed_in` (`functions.sh:216`), change:

```bash
brew install 1password-cli
```

to:

```bash
# 1password-cli is a cask; hardened brew pins bare installs to --formula.
brew install --cask 1password-cli
```

- [ ] **Step 5: Wire it into install.sh**

In `install.sh`, replace the line `  brew_bundle` with `  brew_install_brewfiles`.

Run: `grep -rn "brew_bundle\|brew bundle" --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.claude --exclude-dir=doc . || echo none`
Expected: `none` (the sketchybar comment mentions `brew services`, not bundle; leave it).

- [ ] **Step 6: Dry-check against the real Brewfiles (read-only)**

Run: `bash -c 'source functions.sh; DOTPICKLES_ROLE=home; brewfile_entries Brewfile Brewfile.home'`
Expected: every `brew`/`cask`/`tap` line from both files, no comments, no `#brew 'specstory/...'`.

Run: `bash -c 'source functions.sh; missing_brew_packages formula $(brewfile_entries Brewfile Brewfile.home | awk "\$1==\"brew\"{print \$2}")'`
Expected: either empty, or `orbstack` errors from `brew info` ("No available formula with the name orbstack"). That error is real and is fixed in the `appfile` task, which removes `brew 'orbstack'`. Note it and move on.

- [ ] **Step 7: Lint and commit**

Run: `npm run lint` (run `npm run format` first if needed; prettier-plugin-sh may respace the new code)

```bash
git add functions.sh install.sh scripts/test-brew-install-brewfiles.sh
git commit -m "install: replace brew bundle with a formula installer hardened brew allows

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task: `stub-aware-shell-setup`

**Files:**

- Modify: `home/.zshenv:6-11`
- Modify: `config/fish/conf.d/__homebrew.fish` (whole file)
- Modify: `functions.sh` `load_brew_shellenv` (`functions.sh:37-47`)
- Create: `scripts/test-brew-shellenv.sh`

**Interfaces:**

- Produces: env var `DOTPICKLES_BREW_STUB` (default `/usr/local/bin/brew`), read by all three shells, so tests can point at a fake launcher. Hardened mode = that path has the setuid bit (`test -u`).
- Hardened-mode env: `HOMEBREW_PREFIX=/opt/homebrew`, `HOMEBREW_CELLAR=/opt/homebrew/Cellar`, `HOMEBREW_REPOSITORY=/opt/homebrew`, `PATH` begins `<dir of stub>:/opt/homebrew/bin:/opt/homebrew/sbin`.

Static env in hardened mode (rather than `eval "$(/usr/local/bin/brew shellenv)"`) because every launcher run goes through menu-bar authorization over XPC, and `.zshenv` runs for every zsh, including non-interactive ones.

- [ ] **Step 1: Write the failing harness**

Create `scripts/test-brew-shellenv.sh`:

```bash
#!/usr/bin/env bash
# Manual verification for the Homebrew env set by home/.zshenv,
# config/fish/conf.d/__homebrew.fish, and load_brew_shellenv (functions.sh),
# in both normal and hardened (setuid launcher) modes.
#
# Hardened mode is faked with a setuid file we own in a temp dir, pointed to
# by DOTPICKLES_BREW_STUB. Requires /opt/homebrew/bin/brew (Apple Silicon).
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

zsh_env() {
  env -i HOME="$HOME" PATH="$BASE_PATH" DOTPICKLES_BREW_STUB="$1" ZDOTDIR="$REPO_ROOT/home" \
    zsh -c 'echo "$HOMEBREW_PREFIX|${path[1]}|$(whence -p brew)"' 2>&1
}
fish_env() {
  env -i HOME="$HOME" PATH="$BASE_PATH" DOTPICKLES_BREW_STUB="$1" \
    fish --no-config -c "source $REPO_ROOT/config/fish/conf.d/__homebrew.fish; echo \"\$HOMEBREW_PREFIX|\$PATH[1]|\"(command -s brew)" 2>&1
}
bash_env() {
  env -i HOME="$HOME" PATH="$BASE_PATH" DOTPICKLES_BREW_STUB="$1" \
    bash -c "source $REPO_ROOT/functions.sh; load_brew_shellenv; echo \"\$HOMEBREW_PREFIX|\${PATH%%:*}|\$(command -v brew)\"" 2>&1
}

# --- Test 1: hardened launcher -> static env, stub first on PATH, stub never run ---
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
```

Run: `chmod +x scripts/test-brew-shellenv.sh && ./scripts/test-brew-shellenv.sh`
Expected: Test 2 and Test 3 PASS (current behavior), Test 1 FAILs (hardened mode not implemented). If Test 2 fails before any change, the harness itself is wrong for this machine: stop and fix the harness (e.g. `.zshenv` printing extra output) before touching shell config.

- [ ] **Step 2: Make `.zshenv` stub-aware**

Replace `home/.zshenv` lines 6-11 (the `# Set up Homebrew environment FIRST` comment through the closing `fi`) with:

```zsh
# Set up Homebrew environment FIRST (needed by everything else)
#
# Hardened Homebrew (automic-vault, ADR 0058) installs a setuid launcher at
# /usr/local/bin/brew; /opt/homebrew/bin/brew must not be run directly, and
# every launcher run is approval-gated, so set the env statically instead of
# eval'ing `brew shellenv` on every zsh start. When `av harden brew` offers to
# rewrite this file, answer N.
_brew_stub="${DOTPICKLES_BREW_STUB:-/usr/local/bin/brew}"
if [[ -u $_brew_stub ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
  export HOMEBREW_CELLAR=/opt/homebrew/Cellar
  export HOMEBREW_REPOSITORY=/opt/homebrew
  typeset -U path
  path=("${_brew_stub:h}" /opt/homebrew/bin /opt/homebrew/sbin $path)
  export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
unset _brew_stub
```

- [ ] **Step 3: Make the fish conf.d stub-aware**

Replace all of `config/fish/conf.d/__homebrew.fish` with:

```fish
# Hardened Homebrew (automic-vault, ADR 0058) installs a setuid launcher at
# /usr/local/bin/brew. /opt/homebrew/bin/brew must not be run directly, and
# every launcher run is approval-gated, so in that mode set the env statically
# instead of calling brew on every shell start.
set -l brew_stub /usr/local/bin/brew
set -q DOTPICKLES_BREW_STUB; and set brew_stub $DOTPICKLES_BREW_STUB

# avoid running this multiple times to avoid messing with the PATH
if test -z "$HOMEBREW_PREFIX"
    if test -u $brew_stub
        set -gx HOMEBREW_PREFIX /opt/homebrew
        set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    else
        set -l brew (PATH="/opt/homebrew/bin:/usr/local/bin" command -s brew)
        if test -n "$brew"
            # use our own version of shellenv, to address /opt/homebrew/bin being on the path potentially already, but too late in the PATH
            #eval ($brew shellenv)
            set -gx HOMEBREW_PREFIX ($brew --prefix)
            set -gx HOMEBREW_CELLAR ($brew --cellar)
        end
    end

    if test -n "$HOMEBREW_PREFIX"
        set -gx HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX"
        fish_add_path --move -gP "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
        # the launcher's directory must come before $HOMEBREW_PREFIX/bin
        test -u $brew_stub; and fish_add_path --move -gP (dirname $brew_stub)
        ! set -q MANPATH; and set MANPATH ''
        set -gx MANPATH "$HOMEBREW_PREFIX/share/man" $MANPATH
        ! set -q INFOPATH; and set INFOPATH ''
        set -gx INFOPATH "$HOMEBREW_PREFIX/share/info" $INFOPATH
    end
end
```

- [ ] **Step 4: Make `load_brew_shellenv` stub-aware**

Replace `load_brew_shellenv` (`functions.sh:37-47`) with:

```bash
load_brew_shellenv() {
  local stub="${DOTPICKLES_BREW_STUB:-/usr/local/bin/brew}"
  # Hardened Homebrew (automic-vault, ADR 0058): a setuid launcher replaces
  # direct use of /opt/homebrew/bin/brew, and must come first on PATH.
  if test -u "$stub"; then
    export HOMEBREW_PREFIX=/opt/homebrew
    export HOMEBREW_CELLAR=/opt/homebrew/Cellar
    export HOMEBREW_REPOSITORY=/opt/homebrew
    export PATH="$(dirname "$stub"):/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    return 0
  fi

  if test -x /opt/homebrew/bin/brew; then
    brew=/opt/homebrew/bin/brew
  elif test -x /usr/local/bin/brew; then
    brew=/usr/local/bin/brew
  fi

  if test -n "${brew}"; then
    eval "$($brew shellenv)"
  fi
}
```

Before replacing, read the current body (`sed -n 37,47p functions.sh`) and keep anything after the `eval` line that this snippet doesn't show.

- [ ] **Step 5: Run the harness**

Run: `./scripts/test-brew-shellenv.sh`
Expected: all PASS, exit 0. If zsh output has extra lines (from later parts of `.zshenv`), adjust the harness to take the last line (`| tail -1`) rather than changing `.zshenv`.

- [ ] **Step 6: Smoke test real shells in the worktree**

Run: `ZDOTDIR="$PWD/home" zsh -i -c 'echo $HOMEBREW_PREFIX; whence -p brew' 2>&1 | tail -2`
Expected: `/opt/homebrew` and `/opt/homebrew/bin/brew` (this Mac isn't hardened yet).

- [ ] **Step 7: Lint and commit**

Run: `npm run lint`

```bash
git add home/.zshenv config/fish/conf.d/__homebrew.fish functions.sh scripts/test-brew-shellenv.sh
git commit -m "shell: use the hardened Homebrew launcher when present

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task: `appfile`

**Files:**

- Create: `Appfile`, `Appfile.home`, `Appfile.work`
- Modify: `Brewfile` (remove the 7 `cask` lines at `Brewfile:65-72`; add `cask '1password-cli'`)
- Modify: `Brewfile.home` (remove `brew 'orbstack'` and the 7 `cask` lines)
- Modify: `Brewfile.work` (remove `cask 'granola'`, `cask 'wispr-flow'`)
- Modify: `functions.sh` (add `missing_apps`, `report_missing_apps`)
- Modify: `install.sh` (call `report_missing_apps` after `brew_install_brewfiles`)
- Modify: `bin/dotfiles-doctor` (new section 5 + usage text)
- Create: `scripts/test-missing-apps.sh`

**Interfaces:**

- Consumes: `brew_install_brewfiles` (from `brewfile-installer`).
- Produces:

  - Appfile format: one app per line, `<Bundle Name>.app | <url>`; `#` comment lines and blank lines ignored.
  - `missing_apps FILE...` → stdout lines `"<Bundle Name>.app|<url>"` for apps not found in any dir of `DOTPICKLES_APP_DIRS` (colon-separated; default `/Applications:$HOME/Applications`). Missing files skipped.
  - `report_missing_apps` → prints a section for `install.sh`, reading `Appfile` and `Appfile.$DOTPICKLES_ROLE` from the current directory. Never downloads anything.

- [ ] **Step 1: Write the failing harness**

Create `scripts/test-missing-apps.sh`:

```bash
#!/usr/bin/env bash
# Manual verification for missing_apps() (functions.sh).
#
# Uses temp app dirs via DOTPICKLES_APP_DIRS so real /Applications isn't read.
#
# Usage:
#   ./scripts/test-missing-apps.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTPICKLES_YES=1

# shellcheck source=../functions.sh
source "$REPO_ROOT/functions.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
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

mkdir -p "$TEST_DIR/Applications/Present.app" "$TEST_DIR/UserApps/In Home.app"
export DOTPICKLES_APP_DIRS="$TEST_DIR/Applications:$TEST_DIR/UserApps"

cat > "$TEST_DIR/Appfile" << 'EOF'
# comment
Present.app | https://example.com/present

  Absent One.app   |   https://example.com/absent
In Home.app | https://example.com/home
EOF
cat > "$TEST_DIR/Appfile.role" << 'EOF'
Also Absent.app | https://example.com/also
EOF

# --- Test 1: reports only absent apps, trimmed, in file order ---
assert_eq "missing_apps reports absent apps" \
  "Absent One.app|https://example.com/absent
Also Absent.app|https://example.com/also" \
  "$(missing_apps "$TEST_DIR/Appfile" "$TEST_DIR/Appfile.role")"

# --- Test 2: an app in the second dir (~/Applications) counts as installed ---
assert_eq "missing_apps checks every app dir" \
  "" \
  "$(missing_apps "$TEST_DIR/Appfile" | grep 'In Home' || true)"

# --- Test 3: missing role Appfile is skipped silently ---
assert_eq "missing_apps skips missing files" \
  "Absent One.app|https://example.com/absent" \
  "$(missing_apps "$TEST_DIR/Appfile" "$TEST_DIR/Appfile.nope" 2>&1)"

# --- Test 4: report_missing_apps prints links, never installs ---
assert_eq "report_missing_apps lists each missing app with its link" \
  "📦 checking Appfile apps
  → missing Absent One.app: install from https://example.com/absent
  → missing Also Absent.app: install from https://example.com/also" \
  "$(cd "$TEST_DIR" && DOTPICKLES_ROLE=role report_missing_apps | sed '/^$/d')"

exit "$FAIL"
```

Run: `chmod +x scripts/test-missing-apps.sh && ./scripts/test-missing-apps.sh`
Expected: errors/FAILs (`missing_apps: command not found`), exit non-zero.

- [ ] **Step 2: Implement in functions.sh**

Add directly after `brew_install_brewfiles`:

```bash
# Print "<Bundle>.app|<url>" for each Appfile entry not installed in any
# directory of DOTPICKLES_APP_DIRS (colon-separated, default /Applications
# and ~/Applications). Appfile lines are "<Bundle>.app | <url>"; blank lines
# and # comments are skipped, as are missing files.
missing_apps() {
  local dirs="${DOTPICKLES_APP_DIRS:-/Applications:$HOME/Applications}"
  local file line app url dir found
  for file in "$@"; do
    [ -f "$file" ] || continue
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in '' | '#'*) continue ;; esac
      app="$(sed -E 's/^[[:space:]]+//; s/[[:space:]]*\|.*$//' <<< "$line")"
      url="$(sed -E 's/^[^|]*\|[[:space:]]*//; s/[[:space:]]+$//' <<< "$line")"
      [ -n "$app" ] || continue
      found=0
      while IFS= read -r dir; do
        if [ -d "$dir/$app" ]; then
          found=1
          break
        fi
      done <<< "$(tr ':' '\n' <<< "$dirs")"
      [ "$found" -eq 1 ] || echo "$app|$url"
    done < "$file"
  done
}

# Report Appfile apps that aren't installed. Apps aren't Homebrew-managed under
# hardened Homebrew (ADR 0058), and this deliberately never downloads anything.
report_missing_apps() {
  echo "📦 checking Appfile apps"
  local missing app url
  missing="$(missing_apps Appfile "Appfile.${DOTPICKLES_ROLE}")"
  if [ -z "$missing" ]; then
    echo "  → all apps installed"
  else
    while IFS='|' read -r app url; do
      echo "  → missing $app: install from $url"
    done <<< "$missing"
  fi
  echo
}
```

Note: blank lines with only spaces (`  `) don't match `''`; the `[ -n "$app" ] || continue` guard handles them.

- [ ] **Step 3: Run the harness**

Run: `./scripts/test-missing-apps.sh`
Expected: all PASS, exit 0.

- [ ] **Step 4: Create the Appfiles**

`Appfile`:

```
# Mac apps installed outside Homebrew. Hardened Homebrew (automic-vault) can't
# manage app casks (ADR 0058), so install these from the vendor; they update
# themselves (except Finicky: check its releases page now and then).
# install.sh and bin/dotfiles-doctor report any that are missing.
#
# Format: <bundle name>.app | <where to get it>
CleanShot X.app | https://cleanshot.com/
Dash.app | https://kapeli.com/dash
Finicky.app | https://github.com/johnste/finicky/releases
Hammerspoon.app | https://www.hammerspoon.org/
Obsidian.app | https://obsidian.md/download
Claude.app | https://claude.com/download
claude-devtools.app | https://github.com/matt1398/claude-devtools/releases
```

`Appfile.home`:

```
# Home-role apps. See Appfile for the format.
Discord.app | https://discord.com/download
Google Chrome.app | https://www.google.com/chrome/
Slack.app | https://slack.com/downloads/mac
zoom.us.app | https://zoom.us/download
Karabiner-Elements.app | https://karabiner-elements.pqrs.org/
Spotify.app | https://www.spotify.com/download/mac/
Raycast.app | https://www.raycast.com/
OrbStack.app | https://orbstack.dev/download
```

`Appfile.work`:

```
# Work-role apps. See Appfile for the format.
# Bundle names not verified on the work machine yet; fix if doctor flags them.
Granola.app | https://www.granola.ai/
Wispr Flow.app | https://wisprflow.ai/
```

- [ ] **Step 5: Remove casks from the Brewfiles**

In `Brewfile`, delete these lines: `cask 'cleanshot'`, `cask 'dash'`, `cask 'finicky'`, `cask 'hammerspoon'`, `cask 'obsidian'`, `cask 'claude'`, `cask 'claude-devtools'`. In their place add:

```ruby
# CLI-only casks are the only kind hardened Homebrew allows (ADR 0058).
# Apps live in Appfile.
cask '1password-cli'
```

In `Brewfile.home`, delete: `brew 'orbstack'`, `cask 'discord'`, `cask 'google-chrome'`, `cask 'slack'`, `cask 'zoom'`, `cask 'karabiner-elements'`, `cask 'spotify'`, `cask 'raycast'`.

In `Brewfile.work`, delete: `cask 'granola'`, `cask 'wispr-flow'`.

Run: `grep -n "^cask" Brewfile*`
Expected: only `Brewfile:...:cask '1password-cli'`.

- [ ] **Step 6: Wire into install.sh**

In `install.sh`, directly after the `  brew_install_brewfiles` line, add:

```bash
report_missing_apps
```

- [ ] **Step 7: Add the doctor check**

In `bin/dotfiles-doctor`, insert before `# --- Summary ---`:

```bash
# --- 5. Appfile apps (macOS only) ---
# Apps aren't Homebrew-managed under hardened Homebrew (ADR 0058); Appfile
# lists them so a missing one shows up here.
if running_macos; then
  missing_apps_out="$(cd "$DOTFILES_DIR" && missing_apps Appfile "Appfile.${DOTPICKLES_ROLE}")"
  if [[ -z "$missing_apps_out" ]]; then
    check_pass "all Appfile apps installed"
  else
    while IFS='|' read -r app url; do
      check_fail "$app not installed" "install from $url"
    done <<< "$missing_apps_out"
  fi
fi
```

And in its `usage()` heredoc, add a line after `  - basic tool availability (git, mise, brew)`:

```
  - Appfile apps installed (macOS only)
```

Also update the header comment's list (line ~6-7) to mention Appfile apps.

- [ ] **Step 8: Verify on this machine**

Run: `./scripts/test-missing-apps.sh && bash -c 'source functions.sh; DOTPICKLES_ROLE=home; report_missing_apps'`
Expected: harness passes; the real report says `all apps installed` (every listed app is in `/Applications` today).

Run: `bin/dotfiles-doctor 2>&1 | tail -5`
Expected: `✓ all Appfile apps installed`. Other pre-existing doctor failures in the worktree (symlinks pointing at the main checkout) are fine; only check the new line.

- [ ] **Step 9: Lint and commit**

Run: `npm run lint`

```bash
git add Appfile Appfile.home Appfile.work Brewfile Brewfile.home Brewfile.work functions.sh install.sh bin/dotfiles-doctor scripts/test-missing-apps.sh
git commit -m "apps: move app casks to an Appfile that install and doctor check

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task: `detach-cask-script`

**Files:**

- Create: `scripts/detach-cask.sh`
- Create: `scripts/test-detach-cask.sh`

**Interfaces:**

- Produces: `scripts/detach-cask.sh [--yes] CASK...`. Without `--yes`, prints what it would remove and changes nothing. With `--yes`, removes brew-made symlinks under `$HOMEBREW_PREFIX/{bin,sbin,share}` that point into `Caskroom/<cask>/` or into one of the cask's `.app` bundles, then removes `Caskroom/<cask>`. Never touches `/Applications`. Uses `HOMEBREW_PREFIX` (default `/opt/homebrew`).

`brew uninstall --cask` deletes the app too, and Homebrew has no "forget" command. Run only while unhardened (the user owns the prefix).

- [ ] **Step 1: Write the failing harness**

Create `scripts/test-detach-cask.sh`:

```bash
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
```

Run: `chmod +x scripts/test-detach-cask.sh && ./scripts/test-detach-cask.sh`
Expected: FAILs (script doesn't exist), exit non-zero.

- [ ] **Step 2: Write the script**

Create `scripts/detach-cask.sh`:

```bash
#!/usr/bin/env bash
# Make Homebrew forget app casks without deleting the apps.
#
# Hardened Homebrew (ADR 0058) refuses to run while Caskroom holds app casks,
# and `brew uninstall --cask` would delete the app itself. This removes the
# cask's Caskroom entry and the symlinks brew made for it (binaries,
# completions, manpages), leaving the .app in place to update itself.
#
# Run only while Homebrew is NOT hardened (you must own the prefix).
#
# Usage:
#   scripts/detach-cask.sh [--yes] <cask>...
#
# Without --yes, prints what would be removed and changes nothing.

set -euo pipefail

prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
apply=0
if [ "${1:-}" = "--yes" ]; then
  apply=1
  shift
fi
if [ $# -eq 0 ]; then
  echo "usage: $0 [--yes] <cask>..." >&2
  exit 2
fi

for token in "$@"; do
  caskroom="$prefix/Caskroom/$token"
  if [ ! -d "$caskroom" ]; then
    echo "skip $token: not in $prefix/Caskroom"
    continue
  fi

  # Match links into the Caskroom entry, plus links into the cask's app
  # bundles (e.g. Hammerspoon's `hs` points inside the .app).
  find_args=(-lname "*/Caskroom/$token/*")
  receipt="$caskroom/.metadata/INSTALL_RECEIPT.json"
  if [ -f "$receipt" ] && command -v jq > /dev/null 2>&1; then
    while IFS= read -r app; do
      [ -n "$app" ] && find_args+=(-o -lname "*/$app/*")
    done < <(jq -r '.uninstall_artifacts[]? | select(type == "object" and has("app")) | .app[] | strings' "$receipt")
  fi

  links="$(find "$prefix/bin" "$prefix/sbin" "$prefix/share" -type l \( "${find_args[@]}" \) 2> /dev/null || true)"

  echo "$token:"
  if [ -n "$links" ]; then
    while IFS= read -r link; do
      echo "  link $link"
    done <<< "$links"
  fi
  echo "  caskroom $caskroom"

  if [ "$apply" -eq 1 ]; then
    if [ -n "$links" ]; then
      while IFS= read -r link; do
        rm -f "$link"
      done <<< "$links"
    fi
    rm -rf "$caskroom"
    echo "  detached"
  fi
done

[ "$apply" -eq 1 ] || echo "(dry run; pass --yes to remove)"
```

- [ ] **Step 3: Run the harness**

Run: `chmod +x scripts/detach-cask.sh && ./scripts/test-detach-cask.sh`
Expected: all PASS, exit 0.

- [ ] **Step 4: Dry run against the real prefix (read-only)**

Run: `scripts/detach-cask.sh hammerspoon ghostty orbstack`
Expected: lists real links (e.g. `/opt/homebrew/bin/hs` for hammerspoon, completion/manpage links for ghostty) and the Caskroom path; ends with `(dry run; pass --yes to remove)`. Nothing removed (`ls /opt/homebrew/Caskroom/hammerspoon` still works).

- [ ] **Step 5: Lint and commit**

Run: `npm run lint`

```bash
git add scripts/detach-cask.sh scripts/test-detach-cask.sh
git commit -m "scripts: add detach-cask to drop app casks without deleting apps

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task: `docs`

**Files:**

- Modify: `doc/architecture.md`
- Modify: `bin/CLAUDE.md` (doctor description)
- Modify: `CLAUDE.md` (Development Commands section)

- [ ] **Step 1: Find the Homebrew section in architecture.md**

Run: `grep -n -i "brew\|launchagent" doc/architecture.md`
Expected: line numbers for any Brewfile/LaunchAgents discussion. Add the paragraph in Step 2 next to it (or under a new `## Homebrew` heading at the end if none exists).

- [ ] **Step 2: Add the architecture paragraph**

```markdown
## Homebrew (hardened-compatible)

The repo assumes automic-vault may harden Homebrew (ADR 0058), so it avoids
the features that breaks:

- `Brewfile` / `Brewfile.<role>` hold formulae, taps, and CLI-only casks.
  `install.sh` installs them with `brew_install_brewfiles` (`functions.sh`),
  not `brew bundle`.
- `Appfile` / `Appfile.<role>` list Mac apps, installed by hand from the
  vendor. `install.sh` and `bin/dotfiles-doctor` report missing ones.
- Long-running services are LaunchAgents in `LaunchAgents/`, never
  `brew services`. `scripts/test-launchagent-plists.sh` keeps them from
  writing into `/opt/homebrew`.
- Shell setup uses `/usr/local/bin/brew` when it's the setuid launcher.
- `scripts/detach-cask.sh` drops an app cask from Homebrew without deleting
  the app (only while unhardened).
```

- [ ] **Step 3: Update bin/CLAUDE.md and CLAUDE.md**

In `bin/CLAUDE.md`, in the `bin/dotfiles-doctor` bullet, change `and tool availability (git, mise, brew)` to `tool availability (git, mise, brew), and Appfile apps (macOS)`.

In `CLAUDE.md`, after the line `There are no traditional unit tests. "Testing" means \`npm run lint\` + manual install verification.`, add:

```markdown
Manual harnesses live in `scripts/test-*.sh` (e.g. `scripts/test-brew-install-brewfiles.sh`); run the relevant one when touching the code it covers.
```

- [ ] **Step 4: Run every harness, lint, commit**

Run:

```bash
for t in scripts/test-launchagent-plists.sh scripts/test-brew-install-brewfiles.sh scripts/test-brew-shellenv.sh scripts/test-missing-apps.sh scripts/test-detach-cask.sh; do "$t" > /dev/null && echo "ok $t" || echo "FAILED $t"; done
npm run lint
```

Expected: five `ok` lines, lint exit 0.

```bash
git add doc/architecture.md bin/CLAUDE.md CLAUDE.md
git commit -m "docs: describe hardened-Homebrew-compatible setup

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task: `cutover`

Runs on the home Mac from the **main checkout** after the branch is merged. Several steps need the user (sudo, GUI approval, judgment about each app); an agent should run the read-only checks and stop at each `(user)` step.

- [ ] **Step 1: Update the main checkout**

Run: `cd ~/github.com/technicalpickles/dotfiles && git pull && git log --oneline -3`
Expected: the merge commit is present.

- [ ] **Step 2: Switch ollama to the dotfiles agent**

```bash
brew services stop ollama
./symlinks.sh
launchctl load ~/Library/LaunchAgents/com.technicalpickles.ollama.plist
```

Run: `curl -s localhost:11434/api/version && brew services list`
Expected: a JSON version from ollama; `brew services list` shows `ollama none` (and gost/sleepwatcher `none`).

- [ ] **Step 3: Move beans to mise**

```bash
mise install
mise which beans
brew uninstall --cask beans
brew untap hmans/beans
hash -r
command -v beans
beans version
```

Expected: `beans` resolves to a mise shim/install path and prints a version.

- [ ] **Step 4: Detach app casks, canary first (user)**

```bash
scripts/detach-cask.sh spotify
scripts/detach-cask.sh --yes spotify
```

User: open Spotify, confirm it launches and its own update check works. Only then continue.

- [ ] **Step 5: Detach the rest (user)**

Brewfile apps plus apps installed ad hoc:

```bash
scripts/detach-cask.sh cleanshot dash finicky hammerspoon obsidian claude claude-devtools \
  discord google-chrome slack zoom karabiner-elements raycast orbstack \
  chatgpt dropbox google-drive ghostty jordanbaird-ice open-webui openclaw playcover-community telegram
```

Review the dry-run output, then rerun with `--yes`. Afterwards:

Run: `ls /opt/homebrew/Caskroom`
Expected: only `1password-cli` and `mitmproxy`.

If `hs` is wanted again: in Hammerspoon's console run `hs.ipc.cliInstall()`.

- [ ] **Step 6: Harden (user)**

```bash
av harden brew
```

When it asks to change shell startup references to `/usr/local/bin/brew`, answer **N**. Then open a new terminal.

- [ ] **Step 7: Verify**

```bash
command -v brew
zsh -lic 'whence -p brew'
fish -lc 'command -s brew'
bash -lc 'command -v brew'
echo $PATH | tr ' :' '\n\n' | grep -n -m2 -E '^/usr/local/bin$|^/opt/homebrew/bin$'
brew services list
bin/dotfiles-doctor
curl -s localhost:11434/api/version
```

Expected: `brew` is `/usr/local/bin/brew`, and the zsh, fish, and bash login checks each print `/usr/local/bin/brew`; `/usr/local/bin` listed before `/opt/homebrew/bin`; no services loaded; doctor passes (including `all Appfile apps installed`); ollama still answers.

- [ ] **Step 8: Re-run install end to end**

Run: `./install.sh`
Expected: `🍻 installing Brewfile packages` with `all formula entries installed` / `all cask entries installed` (or one approval prompt if something was missing), `📦 checking Appfile apps` with `all apps installed`, no `brew bundle` errors.

- [ ] **Step 9: Close out the bean**

Check off every item in `.beans/dotfiles-4tco--make-dotfiles-this-mac-compatible-with-hardened-ho.md`, then:

```bash
beans update dotfiles-4tco --status completed
git add .beans/dotfiles-4tco--*.md
git commit -m "beans: complete hardened Homebrew migration

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
