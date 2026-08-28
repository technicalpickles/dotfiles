---
# dotfiles-1iso
title: Watch whether sandbox allowedHosts survives Claude Code rewrites
status: todo
type: task
priority: low
created_at: 2026-08-24T13:45:42Z
updated_at: 2026-08-24T13:45:42Z
---

Split out of dotfiles-uxr8.

allowedHosts was genuinely absent from ~/.claude/settings.json at one point while its sibling scalars (enableWeakerNetworkIsolation, allowAllUnixSockets, allowLocalBinding) survived -- so the file was generated and then rewritten with the array dropped. Re-running claudeconfig.sh restored it to 67 entries (confirmed again 2026-08-24 after the ADR 0050 work).

claudeconfig.sh:230 already guards against the known cause: a malformed entry (a stray 'domain:' prefix from WebFetch permission syntax, or a URL path) makes Claude Code discard the WHOLE array on its next rewrite. The guard exits nonzero on bad entries, so if it ever vanishes again with all entries well-formed, that is a different bug worth filing upstream.

## Checklist
- [ ] Periodically check: jq '.sandbox.network.allowedHosts | length' ~/.claude/settings.json (expect 67+)
- [ ] If it drops to 0/absent with the guard passing, capture the settings.json before/after and file upstream
