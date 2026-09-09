---
# dotfiles-11qr
title: Extend agent-ssh-relay to work role (mirror ADR 0055)
status: in-progress
type: task
created_at: 2026-09-09T16:27:47Z
updated_at: 2026-09-09T16:27:47Z
---

ADR 0055 switched the home role's agent git to real SSH through the agent-ssh-relay, but explicitly left work on the HTTPS+gh-credential-helper path (claude-agent-work still sets core.sshCommand with -F /dev/null). Mirror the home setup for work:

- Drop the -F /dev/null + HTTPS insteadOf rewrite from home/.gitconfig.d/claude-agent-work (or split shared bits into home/.gitconfig.d/common the way d865817 did for home)
- Add the GIT_SSH_COMMAND=ssh SessionStart hook to claude/roles/work.jsonc (currently only in home.jsonc)
- Verify sandboxed git fetch/push over SSH works for work role once the relay LaunchAgent is approved and guideline-app SSO is fixed

Discovered while running this on a work machine for the first time: the agent-relay ssh config.d fragment, ~/.config/gost symlink, and the agent-ssh-relay LaunchAgent plist were all unlinked/unloaded here (fixed via sshconfig.sh + symlinks.sh --yes), and loading the LaunchAgent is currently blocked on macOS Background Task Management approval (System Settings > Login Items & Extensions) -- needs the user, not scriptable.

Also blocked on: guideline-app SAML SSO authorization for the work agent key (github.com/settings/keys).
