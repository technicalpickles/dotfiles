# 57. Local cross-repo filesystem access

Date: 2026-09-14

## Status

Accepted

## Context

A `cq` audit of unsandboxed Bash commands over a week (2026-09-07 to
2026-09-14) found 671 calls run with `dangerouslyDisableSandbox`, 144 of them
git-related. The single largest identifiable cause (~60 of the 144, across
sessions in `pickleclaw`, `picklehome`, and `openclaw-workspace`) was a
session rooted in one personal repo running a git command against a
_different_ sibling repo -- e.g. a `pickleclaw` session doing
`cd ~/github.com/technicalpickles/picklehome && git commit ...` to land a
homelab config change, or a `picklehome` bridge worktree merging back into
`pickleclaw`.

The sandbox's default write grant covers only a session's own working
directory (plus, for a linked git worktree, its main repo's shared `.git` --
built into Claude Code itself, no config needed). A command that `cd`s or
`git -C`s into an unrelated repo entirely falls outside both, and fails with
`Operation not permitted` on that repo's `.git/index.lock`, `.git/config`, or
`.git/FETCH_HEAD`. The retry is `dangerouslyDisableSandbox`, every time,
forever, because nothing about the failure is transient.

This is a different problem from the one [ADR 0041](0041-project-level-claude-plugin-bootstrap.md)
solved. That ADR's `cloud-project-setup.sh` stamps a repo's **committed**
`.claude/settings.json` with plugin config, because a cloud session clones a
repo fresh with no global `~/.claude` and can only see what's checked in.
Cross-repo filesystem access is the opposite: the correct path
(`~/github.com/technicalpickles/picklehome` on this Mac,
`~/projects/picklehome` on the `pickled-coi` VM) is inherently
machine-specific. Checking an absolute path like that into a repo's committed
settings would be silently wrong wherever the layout differs -- exactly the
failure mode ADR 0041 rejected `settings.local.json` to avoid, just pointed
the other direction.

## Decision

Add `claude/cross-repo-access.jsonc`, a manifest mapping a repo name to the
sibling repos its sessions are known to reach into directly (currently
`pickleclaw` -> `[picklehome, openclaw-workspace]`, `picklehome` ->
`[pickleclaw]`, derived from the `cq` audit).

Add `local-project-setup.sh [TARGET_DIR] [--dry-run]`, mirroring
`cloud-project-setup.sh`'s shape (manifest-driven, `jq` merge preserving
other keys, atomic write + `jq empty` validation, one-time `.backup`) but
writing `permissions.additionalDirectories` into `TARGET_DIR`'s **gitignored**
`.claude/settings.local.json` instead. Each declared sibling resolves to a
directory alongside `TARGET_DIR`, so the same manifest entry produces the
right path under any parent directory convention without role-detection
logic. `additionalDirectories` (not `sandbox.filesystem.allowWrite`) is the
right primitive here: it grants ordinary read+write to the whole sibling
tree, matching what a command doing real work there needs, rather than
chasing individual `.git/*` paths one at a time.

Renamed `claude-project-setup.sh` to `cloud-project-setup.sh` to make the
split legible: `cloud-project-setup.sh` writes what a cloud session needs to
see (must be committed), `local-project-setup.sh` writes what only this
machine needs (must not be committed). See the note added to ADR 0041.

Because `settings.local.json` is gitignored, this manifest only takes effect
once `local-project-setup.sh` is run against each affected repo on each
machine -- it does not propagate through `claudeconfig.sh` or `git pull`. It
is deliberately not wired into `claudeconfig.sh`'s automatic run, matching
`cloud-project-setup.sh`'s existing manual-per-repo pattern (ADR 0041): the
set of repos that need this is small and known, not every clone.

### Alternatives Considered

1. **Wildcard `sandbox.filesystem.allowWrite` for all personal repos**
   (`~/github.com/technicalpickles/*/.git` or broader) in the global `home`
   role.

   - Pros: covers any future repo automatically, no manifest to maintain.
   - Cons: removes isolation between every personal repo for every session,
     not just the specific pairs that actually cross-reference each other.
     Widens `allowWrite`, which per the sandboxing docs is meant for narrow
     tool-state paths, not general read+write to whole repos.
   - Rejected: blast radius too broad for the actual, small set of repos
     involved.

2. **Narrow `allowWrite` entries for the specific failing paths**
   (`.git/index.lock`, `.git/config`, `.git/FETCH_HEAD`,
   `.git/worktrees/*/index.lock`).

   - Pros: minimal new write access.
   - Cons: whack-a-mole -- any new cross-repo operation (reading a file,
     running a script in the sibling repo, `just deploy-*`) hits a path not
     on the list. `additionalDirectories` already exists as the primitive for
     "treat this directory like a working directory."
   - Rejected: solves the symptom, not the shape of the actual workflow.

3. **Global `home` role entry, same as the SSH relay fix**
   (`claude/roles/home.jsonc`).
   - Pros: one place, consistent with how the SSH-over-relay fix was applied.
   - Cons: `home.jsonc` is user-scope and applies to _every_ project
     regardless of whether it has anything to do with `picklehome` or
     `pickleclaw`. The access is a property of a specific pair of repos, not
     of the role.
   - Rejected: wrong scope; per-repo project settings is what
     `additionalDirectories` and workspace trust are designed around.

## Consequences

### Positive

- Removes the largest single identified cause of `dangerouslyDisableSandbox`
  git usage (per the `cq` audit), without widening sandbox access beyond the
  specific repo pairs that need it.
- `claude/cross-repo-access.jsonc` is one place to see (and extend) which
  repos are known to cross-reference each other.
- Consistent with the existing `cloud-project-setup.sh` pattern; the rename
  makes the cloud/local split self-explanatory instead of needing this ADR
  read first.

### Negative

- Gitignored means it does not propagate: a fresh clone or a new machine
  needs `local-project-setup.sh` re-run by hand. No automation runs it
  today.
- The manifest can drift from reality -- a new cross-repo workflow needs a
  manual addition, the same maintenance cost `marketplaces.jsonc` already
  has.
- Bootstrapping `local-project-setup.sh` itself needs
  `dangerouslyDisableSandbox` when run from a session not rooted in
  `TARGET_DIR` (e.g. a dotfiles session writing into `pickleclaw`'s
  settings), since that write is itself a cross-repo write. Run it from
  inside `TARGET_DIR` to avoid that.
