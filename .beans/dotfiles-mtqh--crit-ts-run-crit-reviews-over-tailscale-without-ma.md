---
# dotfiles-mtqh
title: "crit-ts: run crit reviews over Tailscale without managing ports"
status: in-progress
type: feature
created_at: 2026-11-08T17:48:43Z
updated_at: 2026-11-08T17:48:43Z
---

bin/crit-ts wraps crit so each live review gets a stable port, a tailscale serve entry and a matching --public-url. Alternative considered: self-hosted crit-web (works over the tailnet but is share/fetch polling, no live local loop).

## Checklist

- [x] Start, reuse and cleanup verified against a live daemon
- [ ] Tailnet URL reachable from another device
- [x] Index entry in bin/CLAUDE.md
