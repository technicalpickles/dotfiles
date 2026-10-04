---
# dotfiles-i4a9
title: 'Hardened bash login: keep user bin dirs ahead of /usr/local/bin'
status: todo
type: bug
priority: low
created_at: 2026-10-04T18:35:18Z
updated_at: 2026-10-04T18:35:18Z
---

From the hardened-brew final review: in hardened mode, home/.bash_profile moves the launcher dir (/usr/local/bin) to the front of PATH after .bashrc has already prepended ~/.local/bin etc. So in bash login shells, anything in /usr/local/bin shadows ~/.local/bin. zsh doesn't have this problem because .zshenv re-prepends the user dirs after the reorder. Fix: re-prepend the user dirs after the reorder in .bash_profile, or do the reorder before .bashrc's prepends. Low priority, since the login shell is fish.
