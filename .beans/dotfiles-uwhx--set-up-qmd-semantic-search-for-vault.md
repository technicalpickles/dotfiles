---
# dotfiles-uwhx
title: Set up qmd semantic search for vault
status: completed
type: task
priority: normal
created_at: 2026-06-27T15:35:03Z
updated_at: 2026-06-27T16:02:28Z
---

qmd tooling exists in repo (LaunchAgents/arm64-macos/com.technicalpickles.qmd-refresh.plist) but nothing was installed. Set it up against the real vault at ~/Vaults/pickled-knowledge/ (README/plan doc wrongly claimed a nested ~/Vaults/pickled-knowledge/pickled-knowledge path).

Note: qmd needs sandbox disabled (writes ~/.config/qmd, ~/.cache/qmd, fetches models from huggingface.co). Metal GPU shader compile fails under launchd -> CPU fallback (full embed ~13m; incremental hourly runs are ~1s so fine).

## Checklist
- [x] Create qmd collection second-brain -> ~/Vaults/pickled-knowledge (5712 files)
- [x] Build initial index (qmd update && qmd embed -> 10566 vectors)
- [x] Install LaunchAgent symlink
- [x] Load + verify the agent runs (first run embedded 2 changed docs, exit 0)
- [x] Fix wrong vault path in LaunchAgents/README.md
- [x] Mark stale doc/plans/2026-02-01-qmd-refresh-launchagent.md as superseded
