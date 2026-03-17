---
# dotfiles-y91h
title: Remove unused git templatedir config
status: completed
type: task
priority: normal
created_at: 2026-03-17T12:48:50Z
updated_at: 2026-03-17T12:53:12Z
---

The init.templatedir=~/.git-template in home/.gitconfig points to a directory that doesn't exist, causing warnings on git clone/init. Removing the config line.
