---
# dotfiles-y9zc
title: Re-apply personal->home role rename reverted by ee2ff1c
status: completed
type: bug
priority: high
created_at: 2026-06-23T19:00:46Z
updated_at: 2026-06-27T03:03:18Z
---

Commit ee2ff1c ("more personal vs home checks") reverted the rename e3e5027 landed, re-breaking the home role per ADR 0035. Re-applied on top of HEAD (preserving ee2ff1c other changes).

## Checklist

- [x] git mv claude/roles/personal.jsonc -> home.jsonc
- [x] git mv home/.gitconfig.d/claude-agent-personal -> claude-agent-home
- [x] git mv Brewfile.personal -> Brewfile.home (kept working-tree mods)
- [x] git mv home/.gitconfig.d/personal-identity -> home-identity (mirror work-identity)
- [x] gitconfig.sh: case personal) -> home), include ref -> home-identity
- [x] home/.gitconfig: path personal-identity -> home-identity
- [x] claudeconfig.sh: default personal -> home
- [x] config/starship.toml: default personal -> home
- [x] work.jsonc comment: mirrors personal.jsonc -> home.jsonc
- [x] Docs: CLAUDE.md, claude/README.md, doc/architecture.md, doc/adr/0034
- [x] npm run lint (prettier-formatted edited shell files)
- [ ] User re-runs install.sh / claudeconfig.sh to regenerate ~/.gitconfig.local + ~/.claude/settings.json

Left as-is (intentional per ADR 0035): agent identity name personal (~/.ssh/agents/personal/, joshua.nichols+personal-agent). bin/setup-agent-ssh-key + check-agent-ssh-key example role personal refers to the identity.

Separate follow-up: bin/claude-permissions references nonexistent permissions.{personal,work}.json and a stale ~/workspace/dotfiles path (pre-roles model, dead code).
