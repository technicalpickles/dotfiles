---
# dotfiles-uxr8
title: Claude Code strips sandbox entries from generated settings.json
status: completed
type: bug
priority: high
created_at: 2026-08-24T13:22:07Z
updated_at: 2026-08-24T13:45:33Z
---

RESOLVED 2026-08-24. See [ADR 0050](doc/adr/0050-canonicalize-sandbox-allowwrite-paths.md).

## Conclusion: the "strips entries" theory was wrong on both counts

1. Nothing was being stripped. `claudeconfig.sh` had simply not been re-run since
   `cabbbea`. Re-running restored `/tmp`, `~/.dolt`, `~/worktrees` and brought
   `allowedHosts` back from absent to 67 entries.
2. The follow-up "Claude Code ignores non-`~`-rooted absolute paths" theory is
   also REFUTED. Absolute paths are honored fine -- allowlisting the bare
   absolute `/Users/technicalpickles/.config/fish` made it writable immediately.

## The actual mechanism: macOS symlink canonicalization

`/tmp`, `/var`, `/etc` are symlinks into `/private`, and Seatbelt matches the
RESOLVED path. A rule built from `"/tmp"` becomes `(subpath "/tmp")`, which never
matches, because the write resolves to `/private/tmp/...`.

Live A/B via project `.claude/settings.local.json`:

    allowWrite = ["/tmp"]           -> /tmp DENIED, /private/tmp DENIED
    allowWrite = ["/private/tmp"]   -> /tmp OK,     /private/tmp OK

Claude Code already works around this for its own dirs, registering both
`"/tmp/claude"` and `"/private/tmp/claude"`. User entries get no such treatment.

## Fix shipped

`claudeconfig.sh` now canonicalizes at generate time (Darwin-gated), right above
the existing allowedHosts guard:
- every `^/(tmp|var|etc)(/|$)` entry gets a `/private` twin (both kept, so
  base.jsonc stays portable -- plain `/tmp` is the one that works on Linux)
- injects `/private$(getconf DARWIN_USER_TEMP_DIR)` so no-template `mktemp`
  works (macOS mktemp uses confstr(_CS_DARWIN_USER_TEMP_DIR), ignoring $TMPDIR)

Verified live after regen: `/tmp` writable, `/private/tmp` writable, `mktemp` OK.

## claudeconfig.sh sandboxing: answered, won't fix

It now runs sandboxed up to its final step, failing only on the `mv` onto
`~/.claude/settings.json`. That path is in the sandbox's "denied within allowed"
set and the docs are explicit that it CANNOT be exempted: "an allowWrite entry or
an Edit allow rule that covers the path doesn't lift the protection." By design.
`claudeconfig.sh` will always need the sandbox escape for that one write. Don't
chase it further.

## Checklist (final)
- [x] Reproduce / diff settings.json before and after regen
- [x] Confirm or refute the 'non-`~` absolute paths get stripped' hypothesis -- REFUTED
- [x] Identify the real mechanism (symlink canonicalization) and ship a fix
- [x] Resolve why claudeconfig.sh can't run sandboxed -- protected path, by design
- [x] Add a generate-time transformation so future symlink-prefixed entries just work
- [x] Write up as ADR 0050
- [~] allowedHosts survival watch -- split out to its own bean
