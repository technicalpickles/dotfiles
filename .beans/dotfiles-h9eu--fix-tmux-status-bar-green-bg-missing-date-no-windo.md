---
# dotfiles-h9eu
title: 'Fix tmux status bar: green bg, missing date, no window pills'
status: completed
type: bug
priority: normal
created_at: 2026-03-24T13:19:14Z
updated_at: 2026-03-24T13:26:55Z
---

Status bar has several visual issues:

1. Entire bar background is green (tmux default) because status-style is never set
2. Green spot between session and mode pills (same cause - #[default] falls back to status-style bg=green)
3. Date pill shows empty because @catppuccin_date_time_text is never set/populated
4. Window names show raw format (0:fish\*) without catppuccin rounded pills
