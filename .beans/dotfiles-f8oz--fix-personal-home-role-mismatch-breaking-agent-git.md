---
# dotfiles-f8oz
title: Fix personal->home role mismatch breaking agent git identity
status: todo
type: bug
priority: high
created_at: 2026-06-12T01:53:13Z
updated_at: 2026-06-23T19:03:31Z
---

REOPENED 2026-06-23: commit ee2ff1c ("more personal vs home checks") reverted the e3e5027 rename, re-breaking everything this bean claimed fixed (home.jsonc->personal.jsonc, claude-agent-home->personal, gitconfig.sh case, claudeconfig default). Re-applied in dotfiles-y9zc. This bean was marked completed but the renames did not survive in main.
