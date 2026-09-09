---
# dotfiles-51b3
title: Guard against LaunchAgent/config symlinks pointing at PR worktrees
status: todo
type: task
priority: normal
created_at: 2026-09-09T00:06:00Z
updated_at: 2026-09-09T00:06:00Z
---

When PR #34 (agent-ssh-relay) merged, two symlinks were left dangling into the temporary PR worktree instead of the main checkout:

- ~/Library/LaunchAgents/com.technicalpickles.agent-ssh-relay.plist -> .claude/worktrees/github-ssh-relay/LaunchAgents/arm64-macos/...
- ~/.config/gost/agent-ssh-relay.yml -> .claude/worktrees/github-ssh-relay/config/gost/agent-ssh-relay.yml

Both still "worked" only because that worktree happened to still exist and be locked; if/when it's removed, both would break silently (LaunchAgent would fail to load, or load stale config). Manually repointed both to the main checkout (see this session's fix), but two structural gaps let this happen:

1. symlinks.sh's LaunchAgent linking loop (and repoint_dangling_launchagents) only detects a plist that moved location within the repo -- not a plist that's correctly named but symlinked from a worktree copy instead of the canonical repo path.
2. config/gost/ has NO linking logic in symlinks.sh at all -- the ~/.config/gost/agent-ssh-relay.yml symlink was apparently created by hand during PR development, not by any script. Same gap could hit any future config/gost/* file.

## Checklist
- [ ] Add symlinks.sh support for config/gost/*.yml (mirror how config/herdr/config.toml is linked)
- [ ] Consider having repoint_dangling_launchagents (or a new check) also flag/repoint a symlink whose target lives under .claude/worktrees/ even if the file exists and is "valid" -- since that's a use-after-worktree-cleanup landmine
- [ ] Re-run symlinks.sh after this fix and confirm both symlinks point at the main checkout with no manual intervention needed
