# 50. canonicalize-sandbox-allowwrite-paths

Date: 2026-08-24

## Status

Accepted

## Context

`claude/roles/base.jsonc` has carried `"/tmp"` in `sandbox.filesystem.allowWrite` since commit `cabbbea` (2026-08-20). It never worked. Writing to `/tmp` under the sandbox kept returning `operation not permitted`, and plain-`/tmp` denials remained one of the largest sources of sandbox EPERM noise (43 hits across Jul-Aug).

The entry was present and correct in the generated `~/.claude/settings.json`, and Claude Code's own resolved config listed it. It simply had no effect.

The working theory recorded in `dotfiles-uxr8` was that Claude Code silently drops non-`~`-rooted absolute paths on rewrite, since every surviving `allowWrite` entry was `~/`-rooted and the only non-`~` entry was the broken one. That theory implied `/tmp` was permanently unallowlistable, and that `/var/folders/...` (needed for the Xcode toolchain, `dotfiles-b6gd`) was too.

**The theory was wrong.** A live A/B through project `settings.local.json` disproved it:

| `allowWrite` entry  | write to `/tmp` | write to `/private/tmp` |
| ------------------- | --------------- | ----------------------- |
| `/tmp` only         | denied          | denied                  |
| `/private/tmp` only | **ok**          | **ok**                  |

A bare absolute path that is _not_ symlinked works fine: adding `/Users/technicalpickles/.config/fish` (absolute, non-`~`) made that directory writable immediately. So absolute paths are honored.

The real mechanism is macOS path canonicalization. `/tmp`, `/var`, and `/etc` are symlinks into `/private`:

```
lrwxr-xr-x  /tmp -> private/tmp
lrwxr-xr-x  /var -> private/var
lrwxr-xr-x  /etc -> private/etc
```

The Seatbelt sandbox matches the **resolved** path. A rule generated from `"/tmp"` becomes `(subpath "/tmp")`, and no resolved path ever begins with `/tmp` — the write lands on `/private/tmp/...` and falls outside the rule.

Claude Code already knows this and works around it for its own session directories, registering both spellings side by side in the resolved config:

```
"/tmp/claude", "/private/tmp/claude", ...
```

User-supplied entries get no such treatment.

A related consequence: macOS `mktemp(1)` with no template uses `confstr(_CS_DARWIN_USER_TEMP_DIR)` rather than `$TMPDIR`, so it ignores the writable session temp dir Claude Code provides and lands in `/var/folders/<hash>/T`. That is why `claudeconfig.sh` itself could not run sandboxed.

## Decision

Canonicalize at generate time in `claudeconfig.sh`, after the `allowWrite` array is merged and deduplicated, gated on `uname = Darwin`:

1. **Mirror symlinked prefixes.** Every entry matching `^/(tmp|var|etc)(/|$)` gets a `/private`-prefixed twin added alongside it. Both spellings are kept, so `claude/roles/base.jsonc` stays portable — on Linux `/tmp` is a real directory and the plain entry is the one that fires.
2. **Inject the Darwin user temp dir.** Add `/private$(getconf DARWIN_USER_TEMP_DIR)` so no-template `mktemp` works. This is per-user and per-machine, so it is computed rather than hardcoded. Scoped to the temp dir (`/T`) only; the sibling cache dir (`/C`) stays denied.

The source-of-truth files keep the human-meaningful spelling. The transformation is a generator concern, in the same spirit as the existing `allowedHosts` validation guard directly below it.

## Consequences

### Positive

- `/tmp` writes work under the sandbox, removing the single biggest source of self-inflicted EPERM noise.
- `claudeconfig.sh` runs sandboxed up to its final step. It still needs `dangerouslyDisableSandbox` for exactly one operation: the `mv` onto `~/.claude/settings.json`. That path is in the sandbox's "denied within allowed" set, and per Claude Code's [sandboxing docs](https://code.claude.com/docs/en/sandboxing) there is deliberately no way to exempt it — "an `allowWrite` entry or an `Edit` allow rule that covers the path doesn't lift the protection." This is by design, not a config bug, and should not be chased further.
- `dotfiles-b6gd` (Xcode/Swift toolchain) gains a live line of attack that was previously believed dead. `/var/folders/<hash>/C/clang/ModuleCache` and friends are allowlistable via the same `/private` prefix.
- Anything added to `allowWrite` under a symlinked prefix is handled automatically. A future contributor writing `/var/log/foo` does not need to know about this.
- Settings edits apply to a running session, so the fix takes effect without restarting Claude Code.

### Negative

- The generated `allowWrite` array carries two entries for every symlinked-prefix path. Harmless but noisier to read, and the `/private` twins have no source-of-truth line in `claude/roles/*.jsonc` — someone grepping for `/private/tmp` in the repo finds only `claudeconfig.sh` and this ADR.
- Injecting `DARWIN_USER_TEMP_DIR` makes `~/.claude/settings.json` machine-specific in a new way. That file is generated and gitignored, so nothing breaks, but the same repo now produces a different settings file per machine beyond the existing role differences.
- The mirroring is a heuristic keyed to three known macOS symlinks. It will not catch a symlinked path outside `/tmp`, `/var`, `/etc` (a user-created symlink in `$HOME`, say), which would fail the same silent way with no guard to explain it.
