---
# dotfiles-f8oz
title: Fix personal->home role mismatch breaking agent git identity
status: completed
type: bug
priority: high
created_at: 2026-06-12T01:53:13Z
updated_at: 2026-06-27T03:03:32Z
---

Superseded by dotfiles-y9zc. The personal->home rename this bean described was reverted by commit ee2ff1c, then re-applied and verified in y9zc (commit a924a05) plus the follow-on fixes (i6rc role detection, c4o0 key-path validation, qybw agents/personal->home). Agent git identity now works: home role loads claude-agent-home, signs as the personal-agent email with the key at ~/.ssh/agents/home, no 1Password prompt.
