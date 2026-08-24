## Sandbox `allowWrite` Paths: Spell Them Canonically on macOS

An `allowWrite` entry under a symlinked prefix silently does nothing. It shows up correctly in `~/.claude/settings.json` and in the resolved config, and it still never fires.

macOS has three of these at the filesystem root:

```
/tmp -> private/tmp
/var -> private/var
/etc -> private/etc
```

Seatbelt matches the **resolved** path. A rule built from `"/tmp"` becomes `(subpath "/tmp")`, and no resolved path ever begins with `/tmp`, so the write lands on `/private/tmp/...` and falls outside the rule. Claude Code works around this for its own session dirs by registering both spellings (you can see `/tmp/claude` and `/private/tmp/claude` side by side in the resolved config). User entries get no such treatment.

**How to apply:** write `/private/tmp`, `/private/var/...`. Keep the plain spelling too if the config is shared with Linux, where `/tmp` is a real directory and the plain entry is the one that works. In this repo `claudeconfig.sh` adds the `/private` twin automatically at generate time, so `claude/roles/*.jsonc` keeps the natural spelling. A repo without that generator step has to spell it out by hand.

This is not about `~` vs absolute. Bare absolute paths work fine: allowlisting `/Users/<you>/.config/fish` takes effect immediately. Only the symlinked prefixes are affected.

### Diagnosing a suspected sandbox denial

**Separate EPERM from ENOENT first.** `echo hi > "$dir/probe"` fails identically to the naked eye whether the sandbox blocked it or the directory just does not exist. Read the actual error, or `mkdir -p` first. Half of "the sandbox is blocking me" reports are a missing directory.

```bash
# Real denial:
#   operation not permitted: /path/probe
# Not a denial:
#   no such file or directory: /path/probe
```

**A/B it live.** Settings edits apply to the running session, so you do not need to restart Claude Code to test an allowlist change. Put a candidate entry in the project's `.claude/settings.local.json` (gitignored in most repos), re-probe, and revert. This is the fastest way to confirm whether a path is genuinely unallowlistable or just spelled wrong:

```json
{ "sandbox": { "filesystem": { "allowWrite": ["/private/tmp"] } } }
```

**Check what is actually in force:**

```bash
jq '.sandbox.filesystem' ~/.claude/settings.json
```

`/sandbox` also has a Config tab showing resolved paths and the "Denied within allowed" set, but it is an interactive terminal panel, so it is not available in every session.

### Per-user temp and cache dirs (`/var/folders/...`)

macOS gives every user a private temp and cache directory under `/var/folders`. Look them up rather than copying a path out of an error message, because the value differs per user and per machine:

```bash
getconf DARWIN_USER_TEMP_DIR  # /var/folders/<b>/<hash>/T/   (TMPDIR-ish scratch)
getconf DARWIN_USER_CACHE_DIR # /var/folders/<b>/<hash>/C/   (clang ModuleCache, xcrun_db)
```

These matter because some tools ignore `$TMPDIR` and go straight here:

- macOS `mktemp(1)` with no template uses `confstr(_CS_DARWIN_USER_TEMP_DIR)`
- Foundation's `itemReplacementDirectory` does the same
- the Xcode and Swift toolchains use the cache dir heavily

So a script can EPERM in the sandbox even though Claude Code set `$TMPDIR` to a writable session dir. To allowlist one, prefix it with `/private` like anything else under `/var`:

```bash
echo "/private$(getconf DARWIN_USER_TEMP_DIR)"
```

**That path is per-user and per-machine, so never hardcode it.** Compute it at config-generation time. The `<hash>` is an encoding of the account's UUID:

```bash
dsmemberutil getuuid -u $(id -u)
```

System users (uid < 500) get formulaic UUIDs of the form `FFFFEEEE-DDDD-CCCC-BBBB-AAAA<uid as 8 hex digits>`, which is why every daemon shares a long common prefix in its folder name and differs only in the tail. A real login account gets a random v4 UUID minted when the account was created, so its folder name looks unrelated to everything else and changes if you move to another Mac or recreate the account. The full name is one 32-character string split 2 chars / 30 chars across the two path components.

(The exact encoding is not plain base32 in any of the usual alphabets, and has not been reverse engineered here. It does not need to be: `getconf` gives you the answer.)

### Paths that cannot be allowlisted at all

Some paths sit in the sandbox's "denied within allowed" set, and per the [sandboxing docs](https://code.claude.com/docs/en/sandboxing) no `allowWrite` entry or `Edit` allow rule lifts the protection. Claude Code's own config files are the main ones, including `~/.claude/settings.json`.

If a script's job is to write one of those, it needs `dangerouslyDisableSandbox` and always will. Do not spend time trying to allowlist your way around it. The only global override is `filesystem.disabled`, which turns filesystem isolation off entirely.
