---
# dotfiles-fyjp
title: Fix 1Password allowlist socket gate in sshconfig.sh
status: completed
type: bug
created_at: 2026-06-22T13:36:25Z
updated_at: 2026-06-22T13:36:25Z
---

sshconfig.sh gated the 1Password agent.toml allowlist symlink on the agent SOCKET existing ([ -S op_socket ]). The socket only exists when 1Password.app is running with the SSH agent enabled, which is usually false during install (esp. fresh installs where brew just installed 1Password). Result: the allowlist was silently skipped on exactly the runs that need it (confirmed on this machine: sshconfig ran at 18:17, socket came up at 18:39). ADR 0033 actually specified gating on the app dir being present, not the socket -- so this was a misimplementation. Fix: gate on the 1Password app container dir (~/Library/Group Containers/2BUA8C4S2C.com.1password) existing instead. 1Password reads agent.toml when it next starts, so the symlink is safe to create ahead of the agent. Commit sshconfig.sh with this bean.
