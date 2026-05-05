---
# dotfiles-sdnt
title: 'Starship: custom context module showing role and devcontainer status'
status: completed
type: feature
priority: normal
created_at: 2026-04-26T14:44:35Z
updated_at: 2026-04-26T18:09:17Z
---

Add a custom Starship module that always shows the current dotpickles role and devcontainer status, prefixing the directory segment.

Shows: role (personal/work/etc), 'devcontainer' when inside Docker, or both combined.
No separate config file needed -- single module in starship.toml.

## Checklist

- [x] Add `${custom.ctx}` before `$directory` in the format string
- [x] Add `[custom.ctx]` section to config/starship.toml
