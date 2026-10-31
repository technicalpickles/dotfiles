---
# dotfiles-rsor
title: Shared av-load-from-op tool for moving op secrets into Automic Vault
status: in-progress
type: feature
created_at: 2026-10-31T22:39:58Z
updated_at: 2026-10-31T22:39:58Z
---

Replace per-repo scripts/load-secrets with bin/av-load-from-op (map file or env template, dry-run, subset). Open: av beside or instead of fnox (ADR 0032).

## Checklist
- [x] tool and stub-shim tests
- [x] ADR 0069 draft
- [x] CI job and bin/CLAUDE.md entry
- [ ] decide --missing once av list format is confirmed
