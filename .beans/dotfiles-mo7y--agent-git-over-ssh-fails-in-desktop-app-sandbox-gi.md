---
# dotfiles-mo7y
title: Agent git over SSH fails in desktop-app sandbox (GIT_SSH_COMMAND clobbers relay)
status: todo
type: bug
priority: high
created_at: 2026-09-09T00:06:00Z
updated_at: 2026-09-09T00:06:00Z
---

Pushing home/.gitconfig.d/claude-agent-home's SSH relay fix (commit d865817) required dangerouslyDisableSandbox to actually push -- inside a normal sandboxed Bash tool call, \`git push\`/\`ls-remote\` over SSH fails with:

    ssh_dispatch_run_fatal: Connection to UNKNOWN port 65535: Broken pipe

Root cause: this session's sandboxed Bash tool sets an ambient \`GIT_SSH_COMMAND\` env var (pointed at the harness's own generic egress proxy, e.g. \`ssh -o ProxyCommand='nc -X 5 -x localhost:PORT %h %p'\`). Git always prefers \`GIT_SSH_COMMAND\` over \`core.sshCommand\`/ssh_config, so it overrides our agent-ssh-relay setup entirely and routes through the harness's own proxy instead -- which apparently can't tunnel raw SSH (broken pipe).

Plain \`ssh\` commands (not invoked via git) are NOT affected, since \`GIT_SSH_COMMAND\` only applies to git's own ssh invocations -- confirmed \`ssh -T git@github.com\` succeeds sandboxed while \`git ls-remote git@github.com:...\` fails sandboxed, both succeed unsandboxed.

PR #34's own test plan claimed a sandboxed \"real SSH-based git remote query succeeds\" -- worth checking whether that was tested from the terminal Claude Code CLI rather than this desktop app's Code tab, since they may sandbox networking differently (this env also sets a bunch of other proxy env vars: http_proxy, ALL_PROXY, CLOUDSDK_PROXY_*, DOCKER_*_PROXY, etc. -- looks like a generic corporate-style egress proxy layer, not just the port-22 TCP block described in ssh/CLAUDE.md).

## Checklist
- [ ] Reproduce in a terminal-based Claude Code CLI session (not desktop app) to see if GIT_SSH_COMMAND is also set there
- [ ] If desktop-app-specific: figure out if there's a way to unset/override GIT_SSH_COMMAND from within a role's env config (claude/roles/home.jsonc), or if the harness always re-injects it after user env
- [ ] If not fixable, document the caveat in ssh/CLAUDE.md's Agent-Session SSH Relay section so it's not a mystery next time
