---
# dotfiles-i6rc
title: gitconfig.sh + other setup scripts fail when DOTPICKLES_ROLE unset in shell
status: completed
type: bug
priority: high
created_at: 2026-06-27T01:52:27Z
updated_at: 2026-06-27T03:03:18Z
---

Running ./gitconfig.sh standalone with DOTPICKLES_ROLE unset in the shell hit '*) Unexpected role:' (empty) and bailed. Unlike claudeconfig.sh it had no default and assumed the env var was pre-exported by install.sh. Fix: centralize detection in functions.sh (sourced by all setup scripts) so the role is detected+exported at source time. Respects an already-set value (env or .env).

## Checklist

- [x] Add dotpickles_detect_role() to functions.sh, run at source time (home/work/container, canonical per ADR 0035)
- [x] Remove duplicate inline detection from install.sh (now relies on functions.sh)
- [x] Verify: unset->home, preset work respected, empty->home, gitconfig.sh hits home) branch
- [x] npm run lint (functions.sh + install.sh pass prettier)

Narrower than dotfiles-h7kh (which proposes a shared bin/dotpickles-role exec'd by all 3 shells). This covers the bash setup scripts that source functions.sh; the cross-shell unification remains h7kh's scope.
