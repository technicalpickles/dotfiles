---
# dotfiles-4yjf
title: Add localhost SSH relay so agent sessions can SSH to git hosts for real
status: in-progress
type: feature
priority: normal
created_at: 2026-09-07T19:51:07Z
updated_at: 2026-09-08T13:13:40Z
---

The Claude Code macOS sandbox (Seatbelt) blocks outbound port 22 at the TCP connect level but allows localhost. This adds a SOCKS5 relay run as an unsandboxed LaunchAgent, plus a generic ssh/config.d ProxyCommand fragment scoped to agent sessions (Match exec on $CLAUDECODE), so sandboxed SSH can do real SSH auth to any allowlisted host.

Motivation: bean dotfiles-187t switched agent transport to HTTPS via gh's credential helper to sidestep the same sandbox block, but that trades away ADR 0031's independently-revocable-per-role-key property since gh's credential helper uses a shared personal OAuth token. This relay lets agent sessions keep using the real per-role SSH key end to end instead. Not a replacement for the HTTPS fallback -- an alternative path, HTTPS stays as-is.

DESIGN PIVOT (2026-09-08): the first working version used socat, one LaunchAgent + one HostKeyAlias-rewriting ssh Match block per host (github.com only). Explored making it generic instead -- researched and empirically tested three real destination-ACL-capable relay tools (gost, dante/sockd, mitmproxy), all confirmed working end to end with a real allowlist rejecting a non-listed host. Settled on gost: single binary, config file support (YAML), and a one-line-per-host allowlist. Rebuilt around it: one generic `Match exec ... { ProxyCommand ncat --proxy 127.0.0.1:1080 --proxy-type socks5 %h %p }` block covers every destination via %h/%p, so known_hosts matches naturally and no HostKeyAlias is needed. Adding a new git host is now a one-line addition to config/gost/agent-ssh-relay.yml's allowlist -- no new LaunchAgent, no new ssh config block. Old per-host socat files (LaunchAgents/arm64-macos/com.technicalpickles.github-ssh-relay.plist, ssh/config.d/github-relay) removed and replaced by com.technicalpickles.agent-ssh-relay.plist + ssh/config.d/agent-relay + config/gost/agent-ssh-relay.yml.

Built and fully verified 2026-09-08 in worktree .claude/worktrees/github-ssh-relay: relay LaunchAgent loads and listens on 127.0.0.1:1080; plain SSH to github.com with zero manual overrides transparently routes through the relay from inside a sandboxed Bash call and authenticates for real; a real SSH-based remote listing against this repo succeeded through it; a non-allowlisted host (example.com) was correctly rejected by gost's ACL; confirmed non-agent sessions (CLAUDECODE unset) resolve with no ProxyCommand at all and go fully direct. npm run lint passes.

During local testing, symlinked the new files (LaunchAgent plist, ssh fragment, gost config) directly from the worktree path rather than running the full symlinks.sh/sshconfig.sh (which would have repointed unrelated existing symlinks like ~/.mackup to the worktree). After merging to main, these should be repointed to the main checkout by re-running symlinks.sh/sshconfig.sh from there.

## Checklist
- [x] Manually validate socat relay + HostKeyAlias mechanism works end to end (original per-host design)
- [x] Research and empirically validate generic destination-ACL relay alternatives (gost, dante, mitmproxy) -- all three confirmed working with a real allowlist
- [x] Confirm a single generic ProxyCommand block (%h/%p) works across multiple hosts with the ACL enforced by the relay, not ssh config
- [x] Rebuild the real implementation around gost: LaunchAgents/arm64-macos/com.technicalpickles.agent-ssh-relay.plist, ssh/config.d/agent-relay, config/gost/agent-ssh-relay.yml
- [x] Remove the superseded per-host socat files
- [x] Add gost to Brewfile
- [x] Document in ssh/CLAUDE.md (fragments table + rewritten relay section, including why gost was chosen over dante/mitmproxy)
- [x] Symlink LaunchAgent + ssh fragment + gost config locally (scoped, not via full symlinks.sh) and load the LaunchAgent
- [x] Verify LaunchAgent loads and listens
- [x] Verify a real remote-listing operation against technicalpickles/dotfiles over SSH from inside a sandboxed agent Bash call
- [x] Verify a non-allowlisted host is rejected by the relay's ACL
- [x] Verify interactive (non-agent) ssh to any host is unaffected (no ProxyCommand at all, goes direct)
- [x] npm run lint passes
- [ ] Repoint local symlinks from main checkout (run symlinks.sh/sshconfig.sh from main, not the worktree) once this branch is merged
