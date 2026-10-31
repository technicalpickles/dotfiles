# 69. Shared av-load-from-op tool instead of per-repo load-secrets scripts

Date: 2026-10-31

## Status

Proposed

## Context

Plaintext `.env` secrets are moving into Automic Vault (`av`), read back through varlock. Each repo needs its values copied in from 1Password once, and again when they rotate.

So far each repo carries its own `scripts/load-secrets`. They all do the same thing, `op read -n "$ref" | av save --stdin --project-directory=. KEY`, and drift in the parts around it: one hardcodes a map, another derives references from `.env.template` with the same sed `service-env` uses and takes `KEY...` subset args, a third has its own TODO handling. Every new repo copies one and tweaks it, and a fix in one (say, remembering `-n`, because `--stdin` saves exactly what it reads, trailing newline included) doesn't reach the others.

The per-repo part is small: which keys and which references. Everything else is the same.

## Decision

Add one tool, `bin/av-load-from-op`, and have repos hand it their key list instead of carrying a script.

- **Input** is either a map file of `KEY=<op reference>` lines (`--map FILE`, comments allowed) or an existing `.env.template` with `KEY={{ <op reference> }}` lines (`--template FILE`). Repos with a template point at it, so references stay in one place.
- **Run from the repo**, or pass `-C DIR`. `av save --project-directory=.` binds a key to the cwd, so this is not optional.
- **Positional `KEY...`** loads a subset. Unknown keys fail before anything loads.
- **`TODO` references** are refused when a key is named, and skipped with a note when loading everything.
- **`--dry-run`** lists what would happen without calling `op` or `av`.
- **Values** go from `op read -n` straight into `av save --stdin`. Output is one status line per key and never includes a value. Any failure means a nonzero exit, though remaining keys still get tried.
- **Tests** are `scripts/test-av-load-from-op.sh`, run in CI with stub `op` and `av` shims on PATH, matching `scripts/test-agent-gitconfig.sh`. The real tools are never called.

`--missing` (skip keys `av` already has) is left out. It needs the output format of `av list`, which `av list --help` doesn't document and which hasn't been confirmed. When it is, the check belongs in one small function.

### Alternatives Considered

1. **Keep per-repo scripts**
   - Pros: each repo is self-contained and works without dotfiles installed.
   - Cons: the drift described above, and every repo re-solves template parsing and TODO handling.
2. **A mise task or shared library each repo sources**
   - Pros: still one implementation.
   - Cons: repos need to know where dotfiles lives. A PATH tool is already how the other helpers in `bin/` are used.

## Consequences

- A repo's secret setup shrinks to a map file or its existing template, plus one command.
- Repos that clone to a machine without dotfiles (CI, containers) can't use it. They weren't going to reach `op` and `av` there either.
- The existing per-repo scripts keep working until each repo moves over. Migrating them is separate work.

## Open question

Does `av` replace fnox ([ADR 0032](0032-use-fnox-for-secrets.md)) or sit beside it? This ADR doesn't answer that. It only makes loading into `av` cheap. If `av` replaces fnox for project secrets, 0032 gets superseded for that scope. If they coexist, something should say which kind of secret goes where. Undecided.
