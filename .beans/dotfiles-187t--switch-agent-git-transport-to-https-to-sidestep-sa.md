---
# dotfiles-187t
title: Switch agent git transport to HTTPS to sidestep sandbox SSH block
status: in-progress
type: feature
priority: normal
created_at: 2026-08-26T18:19:06Z
updated_at: 2026-08-26T18:21:43Z
---

Add url.insteadOf + credential.helper to the claude-agent-{work,home} gitconfig fragments so agent git push/fetch/pull over github.com use HTTPS instead of SSH. The Claude Code sandbox denies outbound port 22 at the TCP connect level (confirmed in pickletown bean gt-o2jy), so every SSH-based git op fails sandboxed and needs dangerouslyDisableSandbox as a workaround. HTTPS via gh's credential helper (gh auth git-credential) is already proven to work sandboxed for push+fetch.

Scope: agent-only, via the existing GIT_CONFIG_GLOBAL role-scoped fragments (ADR 0031) — home/.gitconfig.d/claude-agent-work and claude-agent-home. Does not touch the user's normal interactive git config or pt track's SSH default (that's a separate pickletown bean, gt-rv0z, and doesn't need to change).

Known tradeoff, accepted: the only proven HTTPS auth path (gh auth git-credential) uses gh's shared personal OAuth token, not a role-scoped credential. This weakens ADR 0031's 'independently revocable' property for push authorization (though commit signing/attribution stays per-role, since that's local and unaffected). Decided to accept this for now rather than provision per-role PATs.

## Checklist
- [x] Add [url "https://github.com/"] insteadOf = git@github.com: to claude-agent-work
- [x] Add [credential "https://github.com"] helper = !gh auth git-credential to claude-agent-work
- [x] Same two additions to claude-agent-home
- [x] Verify push+fetch work sandboxed against a real repo using the new config (tested against technicalpickles/dotfiles with a scratch branch, cleaned up)
- [x] Verify commit signing still works unchanged (confirmed Good signature for josh.nichols+agent@gusto.com)
- [ ] Update pickleton's .claude/rules/sandbox-git-writes.md to reflect the fix (once merged)
