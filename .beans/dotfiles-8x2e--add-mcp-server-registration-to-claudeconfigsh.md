---
# dotfiles-8x2e
title: Add MCP server registration to claudeconfig.sh
status: completed
type: feature
priority: normal
created_at: 2026-07-01T14:55:16Z
updated_at: 2026-07-01T15:00:09Z
---

Made the qmd HTTP MCP server registration reproducible via claudeconfig.sh. Declarative claude/mcp-servers.jsonc manifest (single source of truth, like marketplaces.jsonc) + configure_mcp_servers() that idempotently registers each via the 'claude mcp' CLI (user scope, add-if-missing). Also fixed a read_json bug: the // comment stripper ate http:// inside URL strings.

## Checklist
- [x] Create claude/mcp-servers.jsonc manifest (qmd -> http://localhost:8181/mcp)
- [x] Fix read_json() // comment stripper to not eat // inside strings (http:// URLs)
- [x] Add configure_mcp_servers() to claudeconfig.sh, called after configure_marketplaces
- [x] Idempotent: skip if 'claude mcp get' succeeds; add-if-missing
- [x] Document in claude/README.md (architecture tree + MCP servers section)
- [x] Test: run 1 = already registered; removed qmd, run 2 = re-added + Connected; lint green
