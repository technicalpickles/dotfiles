---
# dotfiles-4aty
title: Fix read_json() sed fallback for block-comment JSONC
status: todo
type: bug
priority: low
created_at: 2026-07-01T15:00:09Z
updated_at: 2026-07-01T15:00:09Z
---

The non-node fallback branch of read_json() in functions.sh (used only when node is absent) is already broken for multi-line JSONC: comment lines containing quotes defeat its 'sed //[^"]*$' guard, and trailing-comma handling fails too. Confirmed it errors on the existing claude/marketplaces.jsonc (jq parse error, exit 5), so it's pre-existing dead code (node is always present on these machines, so the node branch always runs).

Not urgent since node is always available. If fixed, mirror the node branch's approach: only strip // when at line-start or preceded by whitespace (so http:// URLs survive), and fix trailing-comma stripping. Or just drop the fallback and require node.
