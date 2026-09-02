# 52. role-scoped-claude-rules

Date: 2026-09-02

## Status

Accepted

## Context

`claude/rules/*.md` are global Claude Code instructions, loaded into context in every session regardless of repo or role -- `claudeconfig.sh` established this with a single directory symlink, `link "claude/rules" "$HOME/.claude/rules"`.

`taskwarrior.md` doesn't belong on every machine. It documents a personal backlog tool (`task`, TaskChampion sync via the `picklehome` 1Password vault) that has no meaning under the `work` role -- `task` isn't even installed there. It still loaded on every work-role session, burning context on instructions for a tool that can't run.

[ADR 0049](0049-role-gated-launchagents.md) hit the identical shape of problem for LaunchAgents (`task-sync`'s plist has no meaning on `work`) and solved it with a subdirectory-per-role (`LaunchAgents/home/`) plus a predicate-gated linking loop. LaunchAgents are whole-file units already partitioned by directory, so a subdirectory maps one-to-one onto "which agents get linked on this role." Rules don't partition as cleanly: they're a flat, actively-curated directory (`claude/rules/claude-config.md` holds `worktrees.md`'s 12 lines up as the target length, and reviewing/trimming them as a set is routine), and a rule that needs "home + container but not work" would need its own subdirectory too, multiplying directories per role combination instead of per role.

## Decision

Symlink `claude/rules/*.md` into `~/.claude/rules/` individually instead of as one directory symlink (`link_rules` in `claudeconfig.sh`). A rule opts out of roles it doesn't apply to with a marker comment on its first line:

```
<!-- dotpickles_role: home -->
```

Comma-separated for multiple roles (`home,container`). No marker means the file links for every role, matching prior behavior for every existing rule except `taskwarrior.md`, which gets tagged `dotpickles_role: home`.

`link_rules` resolves the marker against `$ROLE` at generation time and only calls the existing `link()` helper (per-file symlink, with `link()`'s usual confirm/backup handling of unexpected existing state) for files that qualify. It also migrates the old whole-directory symlink in place on first run, and removes a previously-linked role-scoped file if a later run finds the marker (or `$DOTPICKLES_ROLE`) no longer matches -- so a role change on a machine, or retagging a rule, self-corrects on the next `./claudeconfig.sh` instead of leaving a stale link.

The marker itself is resolved by the generator, not stripped from the file. A rule that does qualify for the current role still carries the `<!-- dotpickles_role: ... -->` line in what loads into context -- a small, accepted cost against rewriting the symlink as a generated copy, which would lose the "content edits are live immediately" property of the current symlink-based rules.

One side effect: pickletown's project-rules nesting (`~/pickleton/.claude/rules` symlinked in as `pickletown`) previously worked by placing that symlink _inside this repo's own `claude/rules/`_ (gitignored), relying on the whole-directory symlink to carry it through to `~/.claude/rules/pickletown`. With `~/.claude/rules` now a real directory of individual symlinks, that indirection no longer reaches anywhere -- the nesting step now symlinks directly into `~/.claude/rules/pickletown`, and the now-pointless `.gitignore` entry for `claude/rules/pickletown` is removed.

### Alternatives Considered

1. **Subdirectory-per-role, mirroring ADR 0049** (`claude/rules-home/taskwarrior.md`, linked only under `home`)

   - Pros: consistent with the established LaunchAgents pattern; no frontmatter-style parsing needed.
   - Cons: `~/.claude/rules` still can't stay a single directory symlink (a symlink can't merge two source directories into one destination), so this needs the identical per-file-symlink restructuring as the marker approach -- no cost savings for adopting it. Doesn't scale to a rule needing more than one role without either a combinatorial subdirectory per role-set or falling back to a list anyway.

2. **Local-only override on this machine, no source change**
   - Pros: zero engineering.
   - Cons: not durable. `~/.claude/rules` is a symlink into this repo; there is no way to unlink one file from within it without either deleting `taskwarrior.md` from the repo (breaking it for `home`) or replacing the whole-directory symlink locally with a hand-built directory. The latter doesn't survive: `claudeconfig.sh`'s `link()` helper, run non-interactively (`DOTPICKLES_YES=1`, the normal automated-run mode), auto-confirms replacing a stray real directory back with the standard symlink -- the next routine `./claudeconfig.sh` run silently reverts the override with no signal that it happened.

## Consequences

### Positive

- `taskwarrior.md` no longer loads on work-role machines, removing a rule that was pure dead weight there (the tool it documents isn't installed).
- General, reusable mechanism: the next personal- or work-only rule declares it with a one-line marker instead of improvising a workaround (as `karabiner-wake-fix` did for LaunchAgents before ADR 0049, per that ADR's own context section).
- Fixes a latent smell in the pickletown-rules nesting: the symlink now lives in the same real destination directory it's meant to appear in (`~/.claude/rules/pickletown`), rather than in a gitignored spot inside this repo's own source tree that only worked by riding along on the (now-removed) whole-directory symlink.
- Role changes and marker edits self-correct on the next `./claudeconfig.sh` run instead of requiring manual link cleanup.

### Negative

- `~/.claude/rules` is no longer literally one directory symlink -- `claude-config.md`'s "Applying Changes" section (and any future reader's mental model) needs to know it's per-file now, with per-file symlink establishment/removal gated by role and requiring a generator run, even though content edits to an already-linked file are still live immediately.
- The `dotpickles_role:` marker line itself is not stripped, so it's visible (as an HTML comment) in the loaded rule content on a role where the file does apply -- a small, accepted context cost for the roles that do use it.
- Two independent role-gating mechanisms now exist in this repo for the same underlying need (ADR 0049's subdirectory+predicate for LaunchAgents, this ADR's marker+generator-loop for rules), rather than one shared implementation. Acceptable at current scale (one role-scoped item per mechanism); worth unifying if a third surface needs role-scoping.
