---
# dotfiles-9972
title: 'Renovate: look up 1Password CLI from its update feed'
status: in-progress
type: task
created_at: 2026-11-13T07:45:36Z
updated_at: 2026-11-13T07:45:36Z
---

The mise dep aqua:1password/cli resolves to github-tags 1password/cli, which doesn't exist (the CLI is closed source), so the Dependency Dashboard shows a no-result lookup warning and the pin never gets updates. Point it at 1Password's update feed via a Renovate custom datasource.

## Checklist

- [x] Custom datasource + packageRule override in renovate.json
- [x] Verified locally: Renovate dry-run finds 2.41.1 -> 2.42.0, no lookup warning
- [ ] PR merged, dashboard warning gone
