---
# dotfiles-w9y9
title: Investigate why DOTPICKLES_ROLE=personal needs explicit specification
status: completed
type: task
priority: normal
created_at: 2026-04-18T23:45:00Z
updated_at: 2026-06-27T15:38:08Z
---

RESOLVED (opposite to this bean recommendation). This correctly diagnosed the personal/home naming mismatch breaking claudeconfig role loading, but recommended option 2 (switch fish to personal). The repo went the other way: home/work became canonical (ADR 0035), personal.jsonc -> home.jsonc, plus the fail-loud guard when a role file is missing (ADR 0036), and the agent key dir moved agents/personal -> agents/home (ADR 0039). The bash role-detection was also centralized in functions.sh (dotfiles-i6rc). All three checklist concerns (naming decision, the change, the loud warning) are addressed. Closing as done.
