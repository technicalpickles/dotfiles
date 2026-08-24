---
# dotfiles-3vm4
title: claude/rules/ in sandbox deny list breaks prettier and git ops on it
status: todo
type: bug
priority: normal
created_at: 2026-08-24T14:02:03Z
updated_at: 2026-08-24T14:02:03Z
---

The sandbox deny list covers dotfiles/claude/rules/, so any Bash-side tool that needs to WRITE there EPERMs, even though the Edit/Write tools handle it fine.

Confirmed 2026-08-24 while adding claude/rules/sandbox-paths.md:

    bin/prettier --write claude/rules/sandbox-paths.md
    [error] EPERM: operation not permitted, open '.../claude/rules/sandbox-paths.md'

Previously seen (same session family): 'git stash pop' failed with 'unable to unlink old claude/rules/worktrees.md'.

Practical impact: 'npm run format' cannot fix a rules file sandboxed, and the lefthook pre-commit prettier hook will fail on any staged rules file that needs reformatting. Workaround is dangerouslyDisableSandbox for that one command.

The deny entry presumably exists because ~/.claude/rules is a symlink INTO this repo, and Claude Code protects its own config paths (~/.claude/rules is in the 'denied within allowed' set). So the protection is following the symlink back into the working tree. That may be intended upstream behavior, but it makes the source-of-truth files in this repo awkward to edit with normal tooling.

## Checklist
- [ ] Confirm the deny is via the ~/.claude/rules symlink resolving into the repo (compare with a rules file copied elsewhere in the tree)
- [ ] Decide: live with it, or restructure so the repo path is not the symlink target
- [ ] If it stays, note the dangerouslyDisableSandbox workaround in claude/README.md
- [ ] Consider whether this is worth reporting upstream
