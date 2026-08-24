---
# dotfiles-emgv
title: finicky.md path-scoping frontmatter is likely a no-op
status: todo
type: bug
priority: normal
created_at: 2026-08-24T14:13:19Z
updated_at: 2026-08-24T14:13:19Z
---

'.claude/rules/finicky.md' declares:

    ---
    paths: home/.finicky.ts, home/finicky.d.ts
    ---

That parses as a YAML *string*, not a list:

    paths type: str
    value: 'home/.finicky.ts, home/finicky.d.ts'

Claude Code docs (https://code.claude.com/docs/en/memory#path-specific-rules) document 'paths' as a YAML list of glob patterns:

    ---
    paths:
      - "src/api/**/*.ts"
    ---

A single string containing a comma is not a valid glob for any real file, so it matches nothing. Docs: 'Rules without a paths field are loaded unconditionally.' Having a paths field that matches nothing means the opposite: the rule loads NEVER. So all that hard-won finicky knowledge (Chrome PWA shims, Slack deep links, the verification checklist) is probably invisible to agents.

NOT yet confirmed at runtime -- this is from YAML parsing plus the documented schema. Claude Code might normalize a string to a single-element list, or split on commas. Verify before assuming.

## Checklist
- [ ] Confirm with the InstructionsLoaded hook, which the docs call out for exactly this ('useful for debugging path-specific rules'): does finicky.md load when reading home/.finicky.ts?
- [ ] If broken, convert to a YAML list:
      paths:
        - "home/.finicky.ts"
        - "home/finicky.d.ts"
- [ ] Audit any other rules files for the same inline-comma form
- [ ] Consider whether these globs should be broader (home/finicky* covers both)
