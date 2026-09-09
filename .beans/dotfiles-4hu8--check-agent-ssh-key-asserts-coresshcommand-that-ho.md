---
# dotfiles-4hu8
title: check-agent-ssh-key asserts core.sshCommand that home role deliberately dropped
status: completed
type: bug
priority: normal
created_at: 2026-09-09T01:30:42Z
updated_at: 2026-09-09T01:53:44Z
---

`./claudeconfig.sh` applies all config successfully, then fails its final validation step:

```
✗ /Users/technicalpickles/.gitconfig.d/claude-agent-home missing core.sshCommand using /Users/technicalpickles/.ssh/agents/home/id_ed25519
  got: ''
1 failed, 7 passed
✗ Agent SSH key validation failed (see above).
```

The check is stale, not the config. `home/.gitconfig.d/claude-agent-home` has no `core.sshCommand` **on purpose**, and says so in its own comment: "No core.sshCommand override: ssh/config.d/auth's Match block" handles key selection. claude/roles/home.jsonc explains the same thing at length: `GIT_SSH_COMMAND` is injected by the harness and resolves ahead of `core.sshCommand`, so a `core.sshCommand` override could never win. That design landed in d865817 ("fix(git): make home-role agent git actually use the SSH relay from #34").

`bin/check-agent-ssh-key` never got the memo. It still asserts the value at line 295-304.

Effect is cosmetic but noisy: every `./claudeconfig.sh` run ends in a red failure and a non-zero exit, after having applied everything correctly. That trains you to ignore the script's exit status, which is the actual cost.

## Checklist
- [x] Decide whether the home role should still assert anything about key selection, and if so what (the ssh/config.d/auth Match block, maybe)
- [x] Update or drop the core.sshCommand assertion in bin/check-agent-ssh-key
- [x] Confirm the work role's expectations are unchanged (it may still legitimately set core.sshCommand)
- [x] Re-run ./claudeconfig.sh and confirm a clean exit (All 8 checks passed)
