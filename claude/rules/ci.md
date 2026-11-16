## CI: Woodpecker for Private Repos, GitHub Actions for Public Ones

A private repo that needs CI gets Woodpecker (`.woodpecker.yml`, the self-hosted instance on the homelab). A public repo gets GitHub Actions. Don't offer Actions for a private repo or ask which to use. Say you're following this and write the Woodpecker pipeline.

**Why:** it's how the repos already run. Public repos with CI use Actions. The private repo with real CI runs only Woodpecker, including its image publish step (37 s on the homelab's slow CPU, 2026-11-15). Josh said "we use woodpecker for CI" on 2026-09-09, but only one project's memory kept it, so a session in another private repo offered Actions (2026-11-15). Two private repos don't follow it yet; ask before treating them as precedent.

**How to apply:**

- Pipelines: `woodpecker:woodpecker-authoring-pipelines`. Red or missing runs: `woodpecker:woodpecker-investigating-pipelines`.
- Images from a private repo: Woodpecker builds and pushes to GHCR by commit SHA, and the host only pulls (picklehome `docs/plans/2026-11-15-ghcr-image-publishing-design.md`). A private package needs a pull token on the host.
- Move a build to Actions only if it pushes a `main` build past about 10 minutes, or Josh says so. A repo's own CLAUDE.md wins.
