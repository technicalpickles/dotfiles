---
# dotfiles-936b
title: Tighten agent ssh key check to require exactly one resolved identity
status: todo
type: task
created_at: 2026-09-09T02:02:37Z
updated_at: 2026-09-09T02:02:37Z
---

`bin/check-agent-ssh-key`'s `ssh -G` branch (home role, no core.sshCommand) currently substring-matches the agent key against the resolved identityfile list:

```bash
if [[ "${resolved_ids//\~\//$HOME/}" == *"$KEY_PATH"* && "$resolved_only" == "yes" ]]; then
```

That passes when the agent key is present *alongside* others. It should require exactly one.

**Why it matters:** `IdentityFile` is additive, and `IdentitiesOnly=yes` does not drop config-supplied identities, only extra agent-offered ones. So a second identity in the resolved set means ssh still offers the human laptop key, and GitHub will happily accept it. Both keys live on the same account, so the "Hi <user>!" greeting is identical either way and check 7 cannot catch it. The script's own comment at check 7 makes exactly this argument about why `-F /dev/null` is needed there.

Right now the home role does resolve to exactly one (verified 2026-09-08), so this is defense against a future `~/.ssh/config` change quietly widening it.

The work role takes the `core.sshCommand` branch instead, so it is unaffected.

## Checklist
- [ ] Replace the substring match with a count check (exactly 1) plus an equality check against $KEY_PATH
- [ ] Keep the existing `key_got` detail message, which already prints the full resolved list
- [ ] Verify home still passes, and that adding a stray IdentityFile makes it fail
