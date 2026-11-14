---
# dotfiles-6e12
title: Turn off the command sandbox for the home role
status: completed
type: task
created_at: 2026-10-26T14:24:18Z
updated_at: 2026-10-26T14:24:18Z
---

Set sandbox.enabled false in claude/roles/home.jsonc (ADR 0066). Sandbox-caused friction (mise run ci pip proxy, Keychain writes, .git/config half-failures, ~/.claude/skills copy-backs) kept costing a retry per occurrence. Allowlists kept inert for a one-line rollback. Bash now gated only by the auto-mode classifier.
