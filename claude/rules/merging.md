## Merging: Hand Back With Facts, Not Ownership

Merge a PR only when the user asked in this session ("merge", "land", "ship") or a standing grant names merging. Otherwise leave it open and hand it back as state: PR links, merge order, the head SHA you verified, CI status, and what's unverified. Open with "Ready to merge" or "Not ready, because X".

**Why:** `gh pr merge` is allowed globally, so only the auto mode classifier (Merge Without Review) and my judgment gate it. Hand-backs drifted into "Merging is yours" and "your call" (about a third of them in Oct and Nov 2026). That claims the button without saying what's needed to press it.

**How to apply:**

- Skip "yours", "your call", "up to you". Say the state instead.
- If the classifier denies a merge, report the denial and its reason. Don't reroute around it.
- A "go ahead" covers the PRs on the table, not the next ones.
- Per-repo exceptions ("merge after green CI here") go in memory or that repo's CLAUDE.md.
