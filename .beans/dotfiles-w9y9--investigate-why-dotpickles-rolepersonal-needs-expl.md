---
# dotfiles-w9y9
title: Investigate why DOTPICKLES_ROLE=personal needs explicit specification
status: todo
type: task
priority: normal
created_at: 2026-04-18T23:45:00Z
updated_at: 2026-04-18T23:47:14Z
---

While regenerating `~/.claude/settings.json` during dotfiles-0mlm, running `./claudeconfig.sh` without `DOTPICKLES_ROLE=personal` prefix didn't load the personal role.

## Root cause (found 2026-04-18)

`config/fish/config.fish` sets `DOTPICKLES_ROLE` based on hostname:

```fish
if string match --quiet --regex '^josh-nichols-' (hostname)
    set -gx DOTPICKLES_ROLE work
else
    set -gx DOTPICKLES_ROLE home
end
```

So on this host, `DOTPICKLES_ROLE=home`. But `claude/roles/` only has `base.jsonc`, `personal.jsonc`, and `work.jsonc`. claudeconfig.sh's fallback `ROLE="${DOTPICKLES_ROLE:-personal}"` does not trigger (`home` is set, not empty). And:

```bash
if [ -f "$role_file" ] && [ "$ROLE" != "base" ]; then
  # ... merge role
fi
```

silently skips the merge if the role file doesn't exist. Result: `settings.json` gets base+stacks but no personal role env block (no `GIT_CONFIG_GLOBAL`, no agent identity).

## The real inconsistency

The fish shell uses `home` / `work` as role names. claudeconfig.sh uses `personal` / `work` as file names. `home` and `personal` both mean the same thing but don't match.

## Options

1. Rename `claude/roles/personal.jsonc` -> `claude/roles/home.jsonc` (align with shell naming)
2. Change fish config to set `personal` instead of `home` (align with claude/roles)
3. Add a mapping layer in claudeconfig.sh (`home` -> `personal`)
4. Symlink `claude/roles/home.jsonc -> personal.jsonc`

Option 2 feels right: `personal` is the established name in ADR 0031, ADR 0013, bean history, and the agent SSH key paths (`~/.ssh/agents/personal/`). The fish config is the outlier.

## Also: silent failure is bad

`claudeconfig.sh` should warn loudly when `DOTPICKLES_ROLE` is set but no matching role file exists. Current behavior produces a half-configured `settings.json` with no indication anything is wrong.

## Checklist

- [ ] Decide on naming (recommend: fish config switches to `personal`/`work`)
- [ ] Make the change (and update any other references to the `home` role)
- [ ] Add a warning/error in claudeconfig.sh when `DOTPICKLES_ROLE` is set but role file missing
- [ ] Verify `./claudeconfig.sh` with no args loads the personal role on a fresh shell
