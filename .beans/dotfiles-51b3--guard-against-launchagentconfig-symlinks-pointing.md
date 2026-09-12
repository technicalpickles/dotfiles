---
# dotfiles-51b3
title: Guard against LaunchAgent/config symlinks pointing at PR worktrees
status: todo
type: task
priority: high
created_at: 2026-09-09T00:06:00Z
updated_at: 2026-09-12T13:00:53Z
---

Second confirmed occurrence 2026-09-12 (see dotfiles-pscz): ~/.ssh/config.d/agent-relay -- a completely different script (sshconfig.sh, via functions.sh's generic link()) hit the exact same failure mode as the 2026-09-08 LaunchAgent/gost incident below. sshconfig.sh was last run from inside a worktree (.claude/worktrees/github-ssh-relay, since removed), so link()'s $DIR-relative source pointed the symlink at the worktree instead of the main checkout. This silently broke agent SSH routing through the relay for EVERY host (not just the one being worked on), and the failure (\"Operation not permitted\" on port 22) looks identical to a sandbox/allowlist problem -- nothing about it points at a stale symlink.

This confirms the pattern is systemic, not a one-off: at least two independent linking code paths (symlinks.sh's LaunchAgent-specific repoint_dangling_launchagents, and functions.sh's generic link() used by sshconfig.sh) share the same root cause -- a symlink source resolved from the invoking script's own $DIR/cwd, which is wrong whenever the script last ran from inside a worktree. functions.sh's link() *does* detect a mismatched existing symlink, but the fix requires an interactive confirm() that defaults to skip when non-interactive (the common case for an agent session) -- so it can persist indefinitely without a loud signal.

Original report (2026-09-08, PR #34 agent-ssh-relay merge):

When PR #34 (agent-ssh-relay) merged, two symlinks were left dangling into the temporary PR worktree instead of the main checkout:

- ~/Library/LaunchAgents/com.technicalpickles.agent-ssh-relay.plist -> .claude/worktrees/github-ssh-relay/LaunchAgents/arm64-macos/...
- ~/.config/gost/agent-ssh-relay.yml -> .claude/worktrees/github-ssh-relay/config/gost/agent-ssh-relay.yml

Both still \"worked\" only because that worktree happened to still exist and be locked; if/when it's removed, both would break silently (LaunchAgent would fail to load, or load stale config). Manually repointed both to the main checkout, but two structural gaps let this happen:

1. symlinks.sh's LaunchAgent linking loop (and repoint_dangling_launchagents) only detects a plist that moved location within the repo -- not a plist that's correctly named but symlinked from a worktree copy instead of the canonical repo path.
2. config/gost/ has NO linking logic in symlinks.sh at all -- the ~/.config/gost/agent-ssh-relay.yml symlink was apparently created by hand during PR development, not by any script. Same gap could hit any future config/gost/* file.

## Checklist
- [ ] Add symlinks.sh support for config/gost/*.yml (mirror how config/herdr/config.toml is linked)
- [ ] Audit every script that calls functions.sh's link() (sshconfig.sh, others) or has its own repoint logic (symlinks.sh) for the same $DIR-relative-to-invocation footgun
- [ ] Make the non-interactive path louder: when confirm() can't prompt (no tty / CI / agent session) and a symlink mismatch is detected, don't silently skip -- at minimum print a prominent warning at the end of the script's run so it can't be missed in normal output
- [ ] Specifically flag (or auto-repoint) any symlink whose target resolves under .claude/worktrees/ or .git/wt/, even if the file exists and is otherwise \"valid\" -- that's a use-after-worktree-cleanup landmine by construction
- [ ] Re-run symlinks.sh and sshconfig.sh after this fix and confirm every generated symlink points at the main checkout with no manual intervention needed
