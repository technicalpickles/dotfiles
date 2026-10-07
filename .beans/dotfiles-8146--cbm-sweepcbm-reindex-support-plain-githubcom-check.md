---
# dotfiles-8146
title: 'cbm-sweep/cbm-reindex: support plain ~/github.com checkouts as corpus'
status: completed
type: task
priority: normal
created_at: 2026-10-07T02:28:13Z
updated_at: 2026-10-07T02:38:10Z
---

On the home Mac there's no ~/pickleton/repos, so cbm-sweep (PR #50) and cbm-reindex index nothing. Add a plain-checkout layout (<root>/<repo>/.git) and a CBM_REPOS override, falling back to ~/github.com/technicalpickles when ~/pickleton/repos is absent.

## Checklist
- [x] Fast-forward main, mise install codebase-memory-mcp on this machine
- [x] Repo discovery: plain layout + CBM_REPOS + fallback in cbm-sweep and cbm-reindex
- [x] Update docs (script headers, LaunchAgents/README.md)
- [x] Smoke-test cbm-sweep (full run: 40/40 ok in 357s, 2026-10-06)
