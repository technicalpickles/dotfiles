---
# dotfiles-dbvu
title: Set up versioned SSH config management with config.d/
status: completed
type: feature
priority: normal
created_at: 2026-03-15T19:18:01Z
updated_at: 2026-03-15T19:24:10Z
---

Create ssh/config.d/ structure with auth, term fragments. Add sshconfig.sh to manage ~/.ssh/config Include and generate local-only fragments (colima, hosts). Hook into install.sh.

## Checklist

- [ ] Create ssh/config.d/.gitignore
- [ ] Create ssh/config.d/auth
- [ ] Create ssh/config.d/term
- [ ] Create sshconfig.sh
- [ ] Wire sshconfig.sh into install.sh
- [ ] Migrate current ~/.ssh/config entries to new structure
