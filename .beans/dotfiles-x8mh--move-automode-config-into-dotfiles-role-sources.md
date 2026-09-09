---
# dotfiles-x8mh
title: Move autoMode config into dotfiles role sources
status: completed
type: task
priority: normal
created_at: 2026-09-09T00:58:54Z
updated_at: 2026-09-09T01:30:49Z
---

The `autoMode` block written by /auto-mode-setup lives in ~/.claude/settings.json, which claudeconfig.sh regenerates. Only enabledPlugins and extraKnownMarketplaces survive regeneration (claudeconfig.sh:170), so the whole auto mode classifier config gets silently wiped on the next run.

Move it into claude/roles/ so it is version-controlled and role-aware.

## Checklist
- [x] Teach claudeconfig.sh to merge autoMode.{allow,soft_deny,hard_deny,environment} across base/role/stacks
- [x] Split current rules between base.jsonc, home.jsonc, beans.jsonc, taskwarrior.jsonc
- [x] Support a private overlay at ~/.config/dotpickles/roles/<role>.jsonc, merged last
- [x] Loud guard via requiresPrivateOverlay when the overlay is missing
- [x] Document the generated-key contract in claude/README.md
- [x] ADR 0055
- [x] Verify merge/override/regroup with a redirected-output probe
- [x] Run ./claudeconfig.sh for real (autoMode landed; `claude auto-mode config` confirms the merge)
- [x] Work-machine overlay split out to dotfiles-1bx8

## Notes

The live autoMode block disappeared from ~/.claude/settings.json mid-session on 2026-09-08,
before any claudeconfig.sh run. Recovered from the session transcript. Cause not established.

Followup: the taskwarrior autoMode allow rule is scoped `in technicalpickles/dotfiles` but
taskwarrior is the backlog system everywhere. Left as-is rather than silently widening a
classifier allow rule.

The regeneration exposed an unrelated stale assertion in bin/check-agent-ssh-key: dotfiles-4hu8.
