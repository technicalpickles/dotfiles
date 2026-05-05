---
# dotfiles-uvp6
title: Create a merge-conflict resolution skill
status: todo
type: feature
created_at: 2026-04-18T22:11:35Z
updated_at: 2026-04-18T22:11:35Z
---

A Claude Code skill that handles git merge conflicts, with the core insight that textual 3-way merges can produce syntactically valid-looking but semantically broken output for non-plain-text files.

## Motivation

Two past cases showed the failure mode:

- **pickled-claude-plugins 2026-04-10** (`feat/sandbox-plugin`, commit `31bc5ff`): a marketplace.json merge produced valid-looking JSON with a duplicated `"version"` key. The resolution wasn't caught until the commit message was rewritten; the structural bug was incidental.
- **pickled-finances 2026-04-09** (`feature/task-management`): used `git merge-tree` to _predict_ conflicts on a parked branch before merging — a useful pre-flight pattern.

No current skill covers this (confirmed via `/cq` search and the skill list in session `55d958e4`).

## Core idea

The skill's real value is not detecting conflicts (trivial with `git diff --name-only --diff-filter=U`) but **validating the resolution per file type**. Any file that isn't plain text needs to be parsed/compiled/linted after conflict resolution to confirm the merge didn't produce garbage.

## Checklist

- [ ] Draft the skill with `superpowers:writing-skills` (rigid discipline applies)
- [ ] Define the detection step: `git diff --name-only --diff-filter=U` to find conflicted files
- [ ] Define the pre-flight option: `git merge-tree $(git merge-base A B) A B | grep -c "CONFLICT"` for conflict prediction before attempting merge
- [ ] Define a validator-per-type table (extensible):
  - [ ] JSON → `jq empty <file>`
  - [ ] YAML → `yq eval . <file>` or `yamllint`
  - [ ] TOML → `toml check` or Python `tomllib`
  - [ ] TypeScript → `tsc --noEmit`
  - [ ] Shell → `bash -n <file>` + optionally `shellcheck`
  - [ ] Ruby → `ruby -c <file>`
  - [ ] Go → `gofmt -e` or `go vet`
  - [ ] Python → `python -m py_compile`
  - [ ] Markdown/plain text → skip (eyeball diff is fine)
- [ ] Capture the CI-validator lesson: before committing the resolution, check if the repo has conventional-commit scope validators or similar (from the `feat/sandbox-plugin` case where an unscoped `fix:` was rejected — CI wins over CLAUDE.md guidance)
- [ ] Decide whether the skill auto-runs validators or just lists the right command for the human to run
- [ ] Decide: does the skill also handle the `--force-with-lease` vs `--force` choice when a rewrite is needed post-resolution? (Probably out of scope — leave to git guidance.)
- [ ] Write the skill per `superpowers:writing-skills` conventions
- [ ] Test against a synthetic JSON conflict with a duplicate key (the canonical failure mode)

## References

- Session `7fd6d422` — marketplace.json resolution, the duplicate `"version"` key case
- Session `5fa3a4ab` — `git merge-tree` pre-flight on `feature/task-management`
- Session `55d958e4` — confirmed no existing skill covers this
- Taskwarrior: pre-existing task "Investigate/create a skill for resolving git merge conflicts" (project:dotfiles, +claude +skills) — this bean supersedes it
