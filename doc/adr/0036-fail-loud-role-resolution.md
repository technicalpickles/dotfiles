# 36. Fail-loud role resolution

Date: 2026-06-12

## Status

Accepted

Amends [ADR 0031](0031-role-scoped-agent-git-identity.md) and builds on
[ADR 0035](0035-canonical-dotpickles-role-names.md).

## Context

`claudeconfig.sh` merges `claude/roles/base.jsonc` with a role file
(`claude/roles/$ROLE.jsonc`) and the stacks to generate `~/.claude/settings.json`.
The role file is where role-specific `env` (notably `GIT_CONFIG_GLOBAL`, which
swaps in the agent git identity per [ADR 0031](0031-role-scoped-agent-git-identity.md))
and sandbox rules live.

The role-loading step was guarded by `if [ -f "$role_file" ] && [ "$ROLE" != "base" ]`.
When `$ROLE` pointed at a name with no matching file, that condition was simply
false and the merge was skipped. A missing role file and a role that genuinely
has no overrides were **indistinguishable** to the script: both produced a
settings.json with no role `env` block.

That silence is what let the `personal` -> `home` drift (see
[ADR 0035](0035-canonical-dotpickles-role-names.md)) hide for ~2 months. The
live role was `home`, `claude/roles/home.jsonc` didn't exist, the merge was
skipped, `GIT_CONFIG_GLOBAL` was never set, and the only symptom was 1Password
signing prompts during agent sessions, which looks exactly like normal
interactive behavior. Nothing pointed at the cause.

## Decision

`claudeconfig.sh` warns loudly when `$ROLE` is not `base` and has no matching
role file:

```
⚠️  WARNING: role '<role>' has no role file (claude/roles/<role>.jsonc).
   No role-specific env (e.g. GIT_CONFIG_GLOBAL) or sandbox rules will apply.
   Check DOTPICKLES_ROLE and claude/roles/ for a name mismatch.
```

The default role in `claudeconfig.sh` is also `home` (was `personal`), matching
the canonical names in [ADR 0035](0035-canonical-dotpickles-role-names.md).

### Why warn rather than hard-fail

The script still generates a usable settings.json from base + stacks; a missing
role file degrades the config rather than corrupting it. Exiting non-zero would
block the whole `install.sh` run over a recoverable condition. A loud warning
surfaces the mismatch on every regeneration without taking the rest of the
config setup down with it.

## Consequences

### Positive

- A drifted or typo'd `DOTPICKLES_ROLE` is visible immediately on the next
  `claudeconfig.sh` run, instead of manifesting weeks later as mysterious
  1Password prompts.
- Generalizes beyond this one bug: any future role-keyed env or sandbox rule
  that fails to load now announces itself.

### Negative

- It is a warning, not an enforcement. A user who ignores the line still gets a
  reduced config. The guard makes the failure _legible_, not impossible.
- Only `claudeconfig.sh` is guarded. Other role-keyed lookups (Brewfile, the SSH
  agent allowlist) have their own skip-with-message behavior and are not unified
  under one mechanism.
