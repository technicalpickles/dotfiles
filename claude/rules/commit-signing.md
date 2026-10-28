<!-- dotpickles_role: home -->

## Commit Signing: Never Bypass It, Try a Plain Commit First

Run `git commit` as-is. Don't add `-c commit.gpgsign=false`, `--no-gpg-sign`, or any other signing override, and don't switch keys or edit git config to dodge it.

**Why:** signing works for agent sessions (Automic Vault signs via `av-gpg`, usually auto-approved within seconds). Agents have skipped signing on a guess that it would fail (seen 2026-10-17), which leaves unsigned commits that look signed-by-policy. Only a real failure tells you anything.

**How to apply:**

- Commit normally. If it fails or hangs, read the actual error and `av history --json --since 10m --no-pager` (see the `automic-vault:automic-vault-credentials` skill), then report it to the user instead of bypassing. `-25308` means the Mac is locked: ask the user to unlock.
- To check a commit is signed, use `git cat-file -p HEAD | grep -c 'BEGIN PGP'`. It skips signature verification, which is what made `git log --show-signature` and `%G?` hang when this role ran sandboxed.
