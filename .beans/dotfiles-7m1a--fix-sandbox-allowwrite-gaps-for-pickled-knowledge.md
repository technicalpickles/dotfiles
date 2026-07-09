---
# dotfiles-7m1a
title: Fix sandbox allowWrite gaps for pickled-knowledge vault and superpowers-chrome cache
status: in-progress
type: bug
priority: normal
created_at: 2026-07-09T20:02:45Z
updated_at: 2026-07-09T20:04:54Z
---

Found via cq query of the last week's Claude Code session transcripts: 13 sandbox EPERM failures, two of which are genuine allowlist gaps.

1. sb note create EPERM on ~/Vaults/pickled-knowledge (hit 4x across pickleton/groot/claude-code sessions). claude/stacks/obsidian.jsonc's sandbox.filesystem.allowWrite only had ~/.cache/qmd/ -- the vault write path itself was never added. Its permissions.allow also still pointed at the old /Users/technicalpickles/Documents/pickled-knowledge path from a previous machine/username, which doesn't exist on this machine at all.

2. superpowers-chrome mkdir EPERM on ~/.cache/superpowers/browser-profiles/superpowers-chrome. claude/stacks/skills.jsonc only had a Read permission for ~/Library/Caches/superpowers/** (macOS-style path). Checked the plugin source (chrome-launcher-helpers.js, getXdgCacheHome()) -- it actually always uses the XDG ~/.cache/superpowers path, so the Library/Caches entry didn't correspond to anything the plugin writes.

## Checklist
- [x] obsidian.jsonc: add ~/Vaults/pickled-knowledge to sandbox.filesystem.allowWrite
- [x] obsidian.jsonc: fix stale technicalpickles permissions.allow paths to ~/Vaults/pickled-knowledge
- [x] skills.jsonc: add ~/.cache/superpowers to sandbox.filesystem.allowWrite (and fix the stale Read path)
- [x] regenerate settings.json via claudeconfig.sh and verify the two paths land
- [x] npm run lint (prettier clean on both files; pre-existing unrelated tsconfig deprecation warning confirmed via git stash)
