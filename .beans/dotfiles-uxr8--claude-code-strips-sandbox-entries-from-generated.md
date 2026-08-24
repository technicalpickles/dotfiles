---
# dotfiles-uxr8
title: Claude Code strips sandbox entries from generated settings.json
status: todo
type: bug
priority: high
created_at: 2026-08-24T13:22:07Z
updated_at: 2026-08-24T13:22:07Z
---

claudeconfig.sh writes sandbox.network.allowedHosts and sandbox.filesystem.allowWrite, but the live ~/.claude/settings.json (mtime 2026-08-23 13:44) is missing:
- the ENTIRE sandbox.network.allowedHosts array (script writes it at claudeconfig.sh:245)
- "/tmp" from allowWrite (added to claude/roles/base.jsonc in cabbbea, 2026-08-20)
- "~/.dolt" from allowWrite (added to claude/stacks/dolt.jsonc in the same commit; may just be an unenabled stack)

Confirmed live (2026-08-24): echo hi > /tmp/probe -> operation not permitted. So the base.jsonc /tmp allowance is a no-op, and bare-/tmp denials are still happening (43 in Jul-Aug).

claudeconfig.sh:220-231 already documents that Claude Code discards the whole allowedHosts array on its next settings.json rewrite if any entry is malformed. Same class of bug now appears to eat allowWrite entries too - note that every surviving allowWrite entry is ~/-rooted; the only non-~ entry (/tmp) is gone. Hypothesis: Claude Code drops non-home absolute paths on rewrite.

## Checklist
- [ ] Reproduce: re-run ./claudeconfig.sh, diff ~/.claude/settings.json before/after, then check again after Claude Code next rewrites it
- [ ] Confirm or refute the 'non-~ absolute paths get stripped' hypothesis
- [ ] Determine why allowedHosts vanished (network still works - likely because permissions.allow WebFetch(domain:...) entries cover the same hosts)
- [ ] Add a verification step or check to claudeconfig.sh that asserts the written entries are still present
- [ ] File upstream if it is a Claude Code bug

## Evidence from dotfiles-lbe4 (2026-08-24)

`claudeconfig.sh` had simply not been re-run since cabbbea. Re-running it restored
all three missing pieces at once:

    allowWrite ADDED:   ['/tmp', '~/.dolt', '~/worktrees']
    allowWrite REMOVED: []
    allowedHosts before: ABSENT
    allowedHosts after:  67 entries

So the "Claude Code strips entries" theory is only half right. `allowedHosts` was
definitely stripped at some point (its sibling scalars `enableWeakerNetworkIsolation`,
`allowAllUnixSockets`, `allowLocalBinding` all survived, so the file was generated and
then rewritten). `/tmp` and `~/.dolt` may simply never have been written.

The sharper finding: with `/tmp` AND `~/worktrees` both present in settings.json,
`~/worktrees` became writable but `/tmp` stayed denied:

    mkdir ~/worktrees/_probe   -> OK
    echo hi > /tmp/probe       -> operation not permitted

Every surviving allowWrite entry is `~/`-rooted. Strong support for: Claude Code
accepts `~`-rooted paths and ignores non-home absolute paths in allowWrite. If true,
`/tmp` can never be allowlisted this way, and neither can `/var/folders/...` for
[[dotfiles-b6gd]].

## Checklist (revised)
- [ ] Confirm the non-`~` hypothesis directly (try `$HOME`-expanded vs literal `/tmp`; check whether claudeconfig.sh's own `~`-expansion step at the end is what makes entries stick)
- [ ] Watch whether allowedHosts survives the next Claude Code rewrite now that it is back
- [ ] Add a verify step to claudeconfig.sh asserting written entries are still present
