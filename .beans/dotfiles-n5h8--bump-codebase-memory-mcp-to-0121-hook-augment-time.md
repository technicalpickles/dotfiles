---
# dotfiles-n5h8
title: Bump codebase-memory-mcp to 0.12.1 (hook-augment timeouts)
status: completed
type: task
priority: normal
created_at: 2026-11-09T15:34:13Z
updated_at: 2026-11-09T15:39:27Z
---

hook-augment on 0.11.0 hashes its 289MB binary in software on every call: ~1.6s CPU, hits the 2000ms deadline about half the time (2,421 entries in ~/.cache/codebase-memory-mcp/logs/hook-augment-timeouts.log), so nudge hooks inject nothing. 0.12.1 notes (#2575) cite hardware SHA-256, hook session start 1.448s to 0.376s.

## Checklist
- [x] Bump pin in config/mise/conf.d/dotfiles.toml
- [x] mise install, stop old daemon and 0.11.0 processes
- [x] cbm-reindex run clean on 0.12.1
- [x] hook-augment under 2s consistently
