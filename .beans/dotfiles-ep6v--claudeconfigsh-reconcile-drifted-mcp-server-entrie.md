---
# dotfiles-ep6v
title: 'claudeconfig.sh: reconcile drifted MCP server entries'
status: completed
type: bug
priority: normal
created_at: 2026-11-10T13:57:15Z
updated_at: 2026-11-10T14:01:01Z
---

configure_mcp_servers was add-if-missing only, so when qmd moved 8181 -> 18181 (9c4dfc8) ~/.claude.json kept the dead URL and the server failed with ECONNREFUSED. Compare the registered url (or command+args) to the manifest and re-register on drift.

## Checklist
- [x] Compare user-scope entry to manifest, remove + re-add on mismatch
- [x] Verify idempotent run and induced-drift run
- [x] Update comment/docs that say add-if-missing (claude/README.md)
- [x] npm run lint (only scratch/automode-denials-2026-10-26.md fails, untouched and pre-existing)
