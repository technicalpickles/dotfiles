---
# dotfiles-g21j
title: Document fish no-query-term for Claude desktop panel
status: in-progress
type: task
created_at: 2026-11-13T14:53:09Z
updated_at: 2026-11-13T14:53:09Z
---

Claude desktop's terminal panel never answers fish's startup Primary Device Attributes query, so each panel tab stalls 10s. Fix in use on the Mac: universal fish_features=no-query-term. Measured what it turns off; document it (ADR + config/fish/CLAUDE.md). Upstream issue: anthropics/claude-code#109546.

## Checklist

- [x] ADR with measured impact (doc/adr/0070)
- [x] Note in config/fish/CLAUDE.md
- [ ] Decide whether fish.sh should apply the universal var idempotently
