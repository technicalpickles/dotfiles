---
# dotfiles-1bx8
title: Create work-machine auto mode private overlay
status: in-progress
type: task
priority: normal
created_at: 2026-09-09T01:24:44Z
updated_at: 2026-09-09T16:27:47Z
---

On the work machine, the `work` role generates with base.jsonc's placeholder autoMode environment ("Organization: None configured" and friends). That is wrong there: a classifier told there is no organization reads an upload to an internal host as an upload to a stranger.

claudeconfig.sh warns about this on every run, because work.jsonc sets `requiresPrivateOverlay: true`.

## Steps
- [ ] On the work machine, run `/auto-mode-setup`
- [ ] Move the `autoMode` block it writes into `~/.config/dotpickles/roles/work.jsonc` (a full role file, same schema as claude/roles/*.jsonc)
- [ ] Re-run `./claudeconfig.sh` and confirm the overlay line appears and the warning is gone
- [ ] Sanity check `claude auto-mode config` shows the merged result

Kept outside the dotfiles repo on purpose: this repo is public and the block names internal infrastructure. See doc/adr/0055-auto-mode-classifier-rules-in-role-sources.md.
