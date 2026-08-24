---
paths:
  - '.github/workflows/**'
  - 'lefthook.yml'
---

# Keeping CI and Pre-Commit in Sync

When adding or changing a CI check, add a matching `lefthook.yml` pre-commit command if the check is fast and cheap (typecheck, lint) -- so failures surface before pushing, not after. Skip it for slow/expensive checks (full test suites, builds) where CI-only is the right tradeoff.

**Why:** CI and `lefthook.yml` are edited independently, so they drift silently -- a check added to one doesn't imply it's mirrored in the other. This bit us once: CI ran `tsc --noEmit` but pre-commit only ran prettier, so type errors reached `main` before being caught (fixed in commit `763ae77`).

**How to apply:** when editing either file, diff the checks each one runs. A check present in CI but missing from pre-commit (or vice versa) is worth a second look, not necessarily a bug -- some checks are deliberately CI-only.
