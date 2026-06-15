---
# dotfiles-w4tk
title: Add per-org SAML SSO probe to check-agent-ssh-key (work role only)
status: completed
type: task
priority: normal
created_at: 2026-06-15T17:35:52Z
updated_at: 2026-06-15T17:45:50Z
---

`bin/check-agent-ssh-key` step 7 verifies plain `ssh -T git@github.com` auth, but
that only proves the key authenticates as the user. It does NOT verify per-org
SAML SSO authorization, which is a separate, per-org, browser-only grant.

## Why this matters (found 2026-06-15)

After the June 13 fix (`dotfiles-niec`, sshCommand `-F /dev/null`) made the work
agent genuinely use `~/.ssh/agents/work/id_ed25519` instead of leaking the laptop
key, the dedicated key authenticated to github.com fine but was not SSO-authorized
for **guideline-app**. `git ls-remote git@github.com:guideline-app/bamboo-cli.git`
returned:

    ERROR: The 'guideline-app' organization has enabled or enforced SAML SSO.

Gusto was already authorized (`Gusto/web` ls-remote returned a SHA). The existing
check passed clean the whole time because it never probes an org repo. SSO grant is
browser-only (github.com/settings/keys -> Configure SSO -> Authorize); not exposed
via gh/API.

## What to add

A new check that runs `git ls-remote` against one known repo per org and detects
the SAML SSO error string ("enabled or enforced SAML SSO"). Pass = SHA returned,
fail = SSO error (point at github.com/settings/keys -> Configure SSO).

## Scope: work role ONLY

Only the **work** role has org-scoped access (Gusto, guideline-app). The home/
personal role uses the gmail identity against personal repos with no org SSO. Gate
the new check on `ROLE == work` (or skip cleanly for any role with no configured
org list) so the personal role doesn't false-fail.

## Implementation notes

- Reuse the live sshCommand shape: `ssh -F /dev/null -i $KEY_PATH -o IdentitiesOnly=yes -o IdentityAgent=SSH_AUTH_SOCK -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10`.
- Org -> probe-repo map (small, in-script or configurable): Gusto -> Gusto/web, guideline-app -> guideline-app/bamboo-cli.
- Treat a returned HEAD SHA as pass; grep stderr for "SAML SSO" as the fail signal.

## Resolution (shipped 2026-06-15)

Added step 8 to `bin/check-agent-ssh-key`: a per-org SAML SSO probe gated on
`ROLE == work`. Runs `git ls-remote` against a canary repo per org using the live
agent sshCommand shape (`-F /dev/null -i $KEY_PATH ... IdentityAgent=SSH_AUTH_SOCK
BatchMode=yes`), then:

- returned 40-hex HEAD SHA -> pass ("authorized for SAML SSO")
- "enabled or enforced SAML SSO" -> fail (points at github.com/settings/keys -> Configure SSO -> <org>)
- anything else -> inconclusive (could not reach repo)

Org canaries: `Gusto -> Gusto/web`, `guideline-app -> guideline-app/bamboo-cli`.
Non-work roles get an empty org list and skip the block entirely.

Also updated the top-of-file checklist comment and `bin/CLAUDE.md`.

Verified live: `bin/check-agent-ssh-key work --email josh.nichols+agent@gusto.com`
reports both orgs authorized. (The unrelated `user:email` gh-scope failure is a
local gh token issue, not this change.)

## Also fixed: step 7 was a false pass

While verifying step 8, found step 7 (`ssh -T github.com`) had the same
laptop-key leak that `dotfiles-niec` fixed in the live sshCommand: it omitted
`-F /dev/null`, so `~/.ssh/config`'s additive `Host *` `IdentityFile ~/.ssh/id_ed25519`
stayed a candidate (IdentitiesOnly=yes does NOT drop config-supplied identities).
Proved with `ssh -v`: the server accepted the laptop key `SHA256:bo+XtP6...`, not
the agent key `SHA256:mwyw...`. Because both keys are on the same `technicalpickles`
account, the "Hi <user>!" greeting was identical, so step 7 reported a green check
even though the agent key was never exercised -- it would pass even for a broken or
unregistered agent key.

Fix: added `-F /dev/null` to step 7's ssh, plus a fingerprint assertion that parses
the `-v` "Server accepts key" line and requires the accepted fingerprint to equal
this key's `$LOCAL_FP`. Now step 7 genuinely tests the agent key and fails loudly if
the wrong key satisfies auth. Verified: reports "works with this key".
