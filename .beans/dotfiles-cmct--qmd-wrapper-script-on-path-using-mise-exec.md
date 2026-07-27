---
# dotfiles-cmct
title: qmd wrapper script on PATH using mise exec
status: completed
type: task
priority: normal
created_at: 2026-06-30T00:59:13Z
updated_at: 2026-06-30T01:16:46Z
---

Add bin/qmd wrapper that runs @tobilu/qmd via 'mise exec node@24' so it resolves identically from interactive shells and launchd (no PATH/mise activation needed). The qmd-refresh LaunchAgent and docs now call bin/qmd instead of the hardcoded mise shims path.

Pinned to node 24 (matches the existing npx better-sqlite3 native-module ABI; node 22 would have needed an npx cache rebuild). Surfaced a latent bug: the agent was implicitly running on whatever 'lts' resolved to, which would silently break on better-sqlite3 ABI mismatch when lts flips. The pin removes that fragility.

## Checklist
- [x] Create bin/qmd wrapper (locates mise, execs 'mise exec node@24 -- npx @tobilu/qmd')
- [x] Update LaunchAgents/arm64-macos/com.technicalpickles.qmd-refresh.plist to call $HOME/.pickles/bin/qmd update/embed
- [x] Update LaunchAgents/README.md to reflect the wrapper
- [x] Document bin/qmd in bin/CLAUDE.md
- [x] Verify: bin/qmd works on PATH and under a launchd-like minimal env (qmd 2.5.3, update exit 0)
- [x] Reload LaunchAgent and confirm exit 0 (runs=1, last exit code=0)
- [x] npm run lint passes
