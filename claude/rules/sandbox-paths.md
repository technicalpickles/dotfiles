## Sandbox `allowWrite`: Spell macOS Paths Canonically

An `allowWrite` entry rooted at `/tmp`, `/var`, or `/etc` silently does nothing. Write the `/private` form instead.

**Why:** those three are symlinks into `/private`, and Seatbelt matches the resolved path. A rule built from `"/tmp"` becomes `(subpath "/tmp")`, and no resolved path ever starts with `/tmp` -- the write lands on `/private/tmp/...` and falls outside the rule. The entry looks correct in `~/.claude/settings.json` and in the resolved config the whole time. Claude Code does this right for its own session dirs, registering both `/tmp/claude` and `/private/tmp/claude`; your entries get no such help.

This is not about `~` vs absolute. Bare absolute paths work fine -- allowlisting `/Users/<you>/.config/fish` takes effect immediately. Only the symlinked prefixes are affected.

**How to apply:**

- Write `/private/tmp`, `/private/var/...`. Keep the plain spelling alongside it if the config is shared with Linux, where `/tmp` is real and the plain entry is the one that fires.
- In dotfiles, `claudeconfig.sh` adds the `/private` twin at generate time, so `claude/roles/*.jsonc` keeps the natural spelling. See [ADR 0050](~/github.com/technicalpickles/dotfiles/doc/adr/0050-canonicalize-sandbox-allowwrite-paths.md). Any other repo has to spell it out by hand.

## Diagnosing a Sandbox Denial

**Check it's actually a denial.** `echo hi > "$dir/probe"` looks the same to the eye whether the sandbox blocked it or the directory doesn't exist. Read the real error, or `mkdir -p` first.

```
operation not permitted: /path/probe   <- sandbox
no such file or directory: /path/probe <- not sandbox, dir is missing
```

**A/B the fix live.** Settings edits apply to the running session, so testing an allowlist change needs no restart. Drop a candidate into the project's `.claude/settings.local.json` (gitignored in most repos), re-probe, revert. Fastest way to tell "unallowlistable" from "spelled wrong":

```json
{ "sandbox": { "filesystem": { "allowWrite": ["/private/tmp"] } } }
```

**See what's in force** with `jq '.sandbox.filesystem' ~/.claude/settings.json`. `/sandbox` has a Config tab showing resolved paths and the "denied within allowed" set, but it's an interactive panel and isn't available in every session.

**Some paths can't be allowlisted at all.** Claude Code's own config files, `~/.claude/settings.json` included, sit in the "denied within allowed" set, and per the [sandboxing docs](https://code.claude.com/docs/en/sandboxing) no `allowWrite` entry or `Edit` rule lifts it. A script whose job is to write one of those needs `dangerouslyDisableSandbox` and always will -- don't burn time trying to allowlist around it.

## Per-User Temp and Cache Dirs (`/var/folders/...`)

Look these up, never hardcode them:

```bash
getconf DARWIN_USER_TEMP_DIR  # /var/folders/<b>/<hash>/T/  scratch
getconf DARWIN_USER_CACHE_DIR # /var/folders/<b>/<hash>/C/  clang ModuleCache, xcrun_db
```

**Why:** plenty of tools ignore `$TMPDIR` and go straight here -- macOS `mktemp(1)` with no template uses `confstr(_CS_DARWIN_USER_TEMP_DIR)`, Foundation's `itemReplacementDirectory` does the same, and the Xcode/Swift toolchains lean on the cache dir. So a script can EPERM under the sandbox even though Claude Code pointed `$TMPDIR` at a writable session dir.

The `<hash>` encodes the account's UUID (`dsmemberutil getuuid -u $(id -u)`), which makes the path per-user _and_ per-machine. System users get formulaic UUIDs, so every daemon shares a long prefix; a login account gets a random v4 UUID and lands somewhere unrelated. It survives reboots but changes on a different Mac or a recreated account.

**How to apply:** allowlist it as `/private$(getconf DARWIN_USER_TEMP_DIR)`, computed at config-generation time. Never paste the literal into a committed config.
