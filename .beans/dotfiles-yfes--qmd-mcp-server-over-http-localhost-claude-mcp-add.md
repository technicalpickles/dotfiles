---
# dotfiles-yfes
title: qmd MCP server over HTTP (localhost) + claude mcp add
status: completed
type: feature
priority: normal
created_at: 2026-06-30T01:49:22Z
updated_at: 2026-06-30T01:51:47Z
---

Run qmd as an HTTP MCP server bound to localhost:8181 via a KeepAlive LaunchAgent, registered with Claude using 'claude mcp add' (user scope, ~/.claude.json). Not wired into claudeconfig.sh roles/stacks (could add later).

Port 8181 = qmd's own default. Server binds localhost only (verified in source). MCP endpoint POST /mcp, plus GET /health and a /query REST route.

## Checklist
- [x] Models already cached (embed/rerank/generation) -- no pull needed
- [x] Create LaunchAgents/arm64-macos/com.technicalpickles.qmd-mcp.plist (KeepAlive + RunAtLoad, QMD_METAL_KEEP_RESIDENCY=1, runs bin/qmd mcp --http --port 8181)
- [x] Symlink + bootstrap agent; GET /health returns {"status":"ok"}
- [x] claude mcp add --transport http qmd http://localhost:8181/mcp --scope user
- [x] Verify: claude mcp get qmd -> Connected; POST /query returns scored results; no CPU fallback (GPU under launchd)
- [x] Document in LaunchAgents/README.md and bin/CLAUDE.md
