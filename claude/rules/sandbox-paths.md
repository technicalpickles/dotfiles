## Sandbox `allowWrite`: Spell macOS Paths Canonically

An `allowWrite` entry rooted at `/tmp`, `/var`, or `/etc` silently does nothing. Write the `/private` form instead.

**Why:** those three are symlinks into `/private`, and Seatbelt matches the resolved path. A rule built from `"/tmp"` becomes `(subpath "/tmp")`, and no resolved path ever starts with `/tmp` -- the write lands on `/private/tmp/...` and falls outside the rule. The entry looks correct in `~/.claude/settings.json` and in the resolved config the whole time. Claude Code does this right for its own session dirs, registering both `/tmp/claude` and `/private/tmp/claude`; your entries get no such help.

This is not about `~` vs absolute. Bare absolute paths work fine -- allowlisting `/Users/<you>/.config/fish` takes effect immediately. Only the symlinked prefixes are affected.

**How to apply:**

- Write `/private/tmp`, `/private/var/...`. Keep the plain spelling alongside it if the config is shared with Linux, where `/tmp` is real and the plain entry is the one that fires.
- In dotfiles, `claudeconfig.sh` adds the `/private` twin at generate time, so `claude/roles/*.jsonc` keeps the natural spelling. See [ADR 0050](~/github.com/technicalpickles/dotfiles/doc/adr/0050-canonicalize-sandbox-allowwrite-paths.md). Any other repo has to spell it out by hand.

## Diagnosing a Sandbox Denial

**Why:** `echo hi > "$dir/probe"` looks the same whether the sandbox blocked it or the dir just doesn't exist (`operation not permitted` vs. `no such file or directory`), and some paths (`~/.claude/settings.json` included) sit in a "denied within allowed" set that no `allowWrite` entry can ever lift.

**How to apply:**

- Read the actual error before assuming sandbox; `mkdir -p` first if unsure.
- A/B live: settings edits apply to the running session, no restart needed. Drop a candidate into `.claude/settings.local.json`, re-probe, revert.
- Check what's in force: `jq '.sandbox.filesystem' ~/.claude/settings.json`, or the `/sandbox` command's Config tab (interactive-only).
- If the path is in the "denied within allowed" set (Claude Code's own config files), stop allowlisting and use `dangerouslyDisableSandbox` — it always will need it.

## Per-User Temp and Cache Dirs (`/var/folders/...`)

**Why:** plenty of tools ignore `$TMPDIR` and go straight here — macOS `mktemp(1)` with no template, Foundation's `itemReplacementDirectory`, and the Xcode/Swift toolchains all do — so a script can EPERM under the sandbox even though `$TMPDIR` itself is writable. The `<hash>` encodes the account's UUID, so it's per-user _and_ per-machine — it survives reboots but changes on a different Mac or a recreated account.

**How to apply:** look these up, never hardcode them, and allowlist as `/private$(getconf DARWIN_USER_TEMP_DIR)` computed at config-generation time:

```bash
getconf DARWIN_USER_TEMP_DIR  # /var/folders/<b>/<hash>/T/  scratch
getconf DARWIN_USER_CACHE_DIR # /var/folders/<b>/<hash>/C/  clang ModuleCache, xcrun_db
```
