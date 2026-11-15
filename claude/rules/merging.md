## Merging: Hand Back With Facts, Not Ownership

Merge a PR only when the user asked in this session ("merge", "land", "ship") or a standing grant names merging. Otherwise leave it open and hand it back as state: PR links, merge order, the head SHA you verified, CI status, and what's unverified. Open with "Ready to merge" or "Not ready, because X".

**Why:** `gh pr merge` is allowed globally, so only the auto mode classifier and agent judgment gate it. Hand-backs drifted into "Merging is yours" (about a third in Oct and Nov 2026), which names an owner and skips the facts.

**How to apply:**

- Skip "yours", "your call", "up to you". Say the state instead.
- If the classifier denies a merge, report the denial and its reason. Don't reroute around it.
- A "go ahead" covers the PRs on the table, not the next ones.
- Per-repo exceptions ("merge after green CI here") go in memory or that repo's CLAUDE.md.
