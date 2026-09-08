---
# dotfiles-1iso
title: Watch whether sandbox allowedHosts survives Claude Code rewrites
status: completed
type: task
priority: low
created_at: 2026-08-24T13:45:42Z
updated_at: 2026-08-31T13:54:57Z
---

Split out of dotfiles-uxr8.

RESOLVED 2026-08-31: root cause found, not a rewrite bug. `sandbox.network.allowedHosts`
was never a valid settings key in Claude Code -- the real key is `allowedDomains`
(confirmed against https://code.claude.com/docs/en/settings-reference, which doesn't
mention `allowedHosts` at all, not even as legacy/deprecated). claudeconfig.sh had been
writing the wrong key name since the beginning. Claude Code silently drops unrecognized
keys on its own settings.json rewrites (it rewrites the file as sessions run, not just
when claudeconfig.sh regenerates it) -- no warning, the array just vanishes on the next
rewrite. That explains every prior "it was there, then it wasn't" observation in this
bean and in dotfiles-uxr8: the array was never actually taking effect for sandboxed Bash
commands, across every stack (git, github, docker, buildkite, etc. -- ~67 hostnames
total), for as long as this repo has managed sandbox settings.

Fixed: renamed allowedHosts -> allowedDomains throughout claudeconfig.sh, every
claude/roles/*.jsonc and claude/stacks/*.jsonc that had the key, and claude/README.md.
Regenerated ~/.claude/settings.json and confirmed `sandbox.network.allowedDomains` now
holds 67 entries under the correct key, with no `allowedHosts` key present anywhere.

Original text preserved below for context.

---

allowedHosts was genuinely absent from ~/.claude/settings.json at one point while its sibling scalars (enableWeakerNetworkIsolation, allowAllUnixSockets, allowLocalBinding) survived -- so the file was generated and then rewritten with the array dropped. Re-running claudeconfig.sh restored it to 67 entries (confirmed again 2026-08-24 after the ADR 0050 work).

claudeconfig.sh:230 already guards against the known cause: a malformed entry (a stray 'domain:' prefix from WebFetch permission syntax, or a URL path) makes Claude Code discard the WHOLE array on its next rewrite. The guard exits nonzero on bad entries, so if it ever vanishes again with all entries well-formed, that is a different bug worth filing upstream.

## Checklist
- [x] Periodically check: jq '.sandbox.network.allowedHosts | length' ~/.claude/settings.json (expect 67+) -- superseded, see resolution above
- [x] If it drops to 0/absent with the guard passing, capture the settings.json before/after and file upstream -- superseded, root cause found instead
