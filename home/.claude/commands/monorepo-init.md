---
description: Initialize monorepo configuration and activate working-in-monorepos skill
---

I'm activating the **working-in-monorepos** skill to help you work in this monorepo.

Let me check if you already have a `.monorepo.json` configuration file at the repository root, and if not, I'll offer to auto-detect your subprojects and generate one.

First, let me check for existing configuration:

```bash
test -f .monorepo.json && echo "Config exists" || echo "No config found"
```

If no config exists, I'll run the detection script to identify subprojects:

```bash
~/.claude/skills/working-in-monorepos/scripts/monorepo-init --dry-run
```

Would you like me to write this configuration to `.monorepo.json`? If so, I'll run:

```bash
~/.claude/skills/working-in-monorepos/scripts/monorepo-init --write
```

From now on, I'll use **absolute paths** for all commands to ensure they execute from the correct location, following the Iron Rule of the working-in-monorepos skill.
