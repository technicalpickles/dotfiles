---
# dotfiles-413h
title: Document role-name convention + fail-loud role resolution (ADRs) and finish personal->home drift
status: completed
type: task
priority: high
created_at: 2026-06-12T23:34:48Z
updated_at: 2026-06-12T23:37:31Z
---

Captured the role-name convention as a foundational ADR and the fail-loud guard as a change, plus finished the personal->home drift in code/docs.

## Checklist

- [x] Fix install.sh: personal -> home (was still emitting the dead name)
- [x] Fix doc/architecture.md prose: personal -> home + detection/duplication note
- [x] Write ADR 0035: canonical DOTPICKLES_ROLE names (home/work/container, personal retired)
- [x] Write ADR 0036: fail-loud role resolution guard (amends 0031 + 0035)
- [x] Correct stale personal refs in ADR 0031 + amendment note
- [x] Update doc/adr/README.md index for 0035 + 0036
- [x] Detection-duplication documented as accepted cross-shell wart in 0035/0036 (not a TODO)
- [x] Prettier clean on all touched markdown
