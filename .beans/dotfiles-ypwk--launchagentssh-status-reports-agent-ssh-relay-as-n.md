---
# dotfiles-ypwk
title: launchagents.sh status reports agent-ssh-relay as not loaded when it is
status: todo
type: bug
priority: low
created_at: 2026-09-09T00:06:00Z
updated_at: 2026-09-09T00:06:00Z
---

\`./launchagents.sh status com.technicalpickles.agent-ssh-relay\` prints:

    ⚠ Agent is not loaded

even when \`launchctl print gui/$(id -u)/com.technicalpickles.agent-ssh-relay\` shows \`state = running\` and \`active count = 1\`. Confirmed the LaunchAgent is genuinely loaded and gost is listening on 127.0.0.1:1080.

ssh/CLAUDE.md tells people to check relay health with this exact command, so a false negative here is actively misleading.

Likely cause: launchagents.sh's loaded-check pipes \`launchctl list | grep ...\` into a \`while read\` loop (see launchagents.sh:150) -- classic bash subshell bug where state set inside the loop doesn't escape to the caller. Worth checking the check at line ~146 and the one at ~227 too, both use the same \`launchctl list | grep -q\` pattern which should be fine on its own, but something in the surrounding logic is producing the wrong verdict for this specific agent.

## Checklist
- [ ] Reproduce and isolate which check is misfiring (line 146 vs 150 vs 227 in launchagents.sh)
- [ ] Fix the subshell/pipe issue if that's the cause
- [ ] Re-verify status output against launchctl print for agent-ssh-relay and at least one other known-loaded agent
