---
# dotfiles-7n69
title: Restore typecheck/format scripts dropped in devcontainer refactor
status: in-progress
type: bug
priority: normal
created_at: 2026-05-08T16:36:14Z
updated_at: 2026-05-08T16:44:35Z
---

CI has been failing since 60c24bc (Nov 25, 2025) — refactor that extracted the devcontainer to pickled-devcontainer over-deleted from package.json: it stripped the entire scripts block (typecheck, format, format:check, lint, test) and dropped typescript from devDependencies, when it only meant to remove the devcontainer:\* scripts.

The .github/workflows/ci.yml workflow still calls npm run typecheck and npm run format:check, and CLAUDE.md still documents these scripts as the test suite. tsconfig.json + home/.finicky.ts also still exist.

## Checklist

- [x] Diagnose root cause (package.json scripts deleted by 60c24bc)
- [x] Restore scripts block to package.json
- [x] Re-add typescript to devDependencies
- [x] Run npm install to regenerate lockfile
- [x] Run npm run lint locally to verify (typecheck passes; format:check fixed 35 drifted files)
- [ ] Push branch, open PR, watch CI go green
