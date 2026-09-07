---
# dotfiles-4yjf
title: Add localhost SSH relay so agent sessions can SSH to GitHub over real SSH
status: in-progress
type: feature
priority: normal
created_at: 2026-09-07T19:51:07Z
updated_at: 2026-09-07T19:54:25Z
---

The Claude Code macOS sandbox (Seatbelt) blocks outbound port 22 at the TCP connect level but allows localhost. This adds a socat-based relay (127.0.0.1:2222 -> github.com:22), run as an unsandboxed LaunchAgent, plus an ssh/config.d fragment that rewrites Host github.com to the relay only inside agent sessions (Match exec on $CLAUDECODE), with HostKeyAlias github.com so known_hosts still matches on the real hostname.

Motivation: bean dotfiles-187t switched agent transport to HTTPS via gh's credential helper to sidestep the same sandbox block, but that trades away ADR 0031's independently-revocable-per-role-key property since gh's credential helper uses a shared personal OAuth token. This relay lets agent sessions keep using the real per-role SSH key end to end instead. Not a replacement for the HTTPS fallback -- an alternative path, HTTPS stays as-is.

Built and fully verified 2026-09-07 in worktree .claude/worktrees/github-ssh-relay: relay LaunchAgent loads and listens on 127.0.0.1:2222; plain SSH to github.com with zero manual overrides transparently routes through the relay from inside a sandboxed Bash call and authenticates for real (GitHub's normal no-shell-access response); a real remote-listing operation against technicalpickles/dotfiles over SSH succeeded through the relay; confirmed non-agent sessions (CLAUDECODE unset) resolve github.com directly on port 22, untouched. npm run lint passes.

During local testing, symlinked the two new files (LaunchAgent plist + ssh/config.d/github-relay) directly from the worktree path rather than running the full symlinks.sh/sshconfig.sh (which would have repointed unrelated existing symlinks like ~/.mackup to the worktree). After merging to main, these should be repointed to the main checkout by re-running symlinks.sh/sshconfig.sh from there.

## Checklist
- [x] Manually validate socat relay + HostKeyAlias mechanism works end to end (both in a sandboxed Claude Code Bash call and independently by the user in their own terminal)
- [x] Add LaunchAgents/arm64-macos/com.technicalpickles.github-ssh-relay.plist (RunAtLoad + KeepAlive, socat TCP-LISTEN:2222 -> github.com:22)
- [x] Add ssh/config.d/github-relay fragment (Match host github.com exec, Hostname 127.0.0.1, Port 2222, HostKeyAlias github.com)
- [x] Document in ssh/CLAUDE.md (fragments table + new section explaining the relay and its relationship to the HTTPS fallback)
- [x] Symlink LaunchAgent + ssh fragment locally (scoped, not via full symlinks.sh) and load the LaunchAgent
- [x] Verify LaunchAgent loads and listens: status + port check
- [x] Verify a real remote-listing operation against technicalpickles/dotfiles over SSH from inside a sandboxed agent Bash call
- [x] Verify interactive (non-agent) ssh to github.com is unaffected (goes direct, not through relay)
- [x] npm run lint passes
- [ ] Repoint local symlinks from main checkout (run symlinks.sh/sshconfig.sh from main, not the worktree) once this branch is merged
