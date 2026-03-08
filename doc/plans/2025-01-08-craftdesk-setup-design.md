# Craftdesk Project Setup Helper

## Problem

Setting up Claude Code capabilities in a project requires:

- Deciding which plugins/skills to use
- Configuring craftdesk.json
- Handling git tracking (commit vs local-only)
- Running craftdesk install

This is tedious and error-prone, especially for repos you don't control where you want local-only configuration.

## Goals

1. **Minimal global config** - `~/.claude/settings.json` contains only infrastructure (bedrock, model, statusline)
2. **Profiles** - Predefined sets of plugins/skills that can be applied to any project
3. **Works in any repo** - Whether you own it or not, without polluting git history

## Design

### File Locations

```
~/workspace/dotfiles/
├── claude/
│   ├── profiles/
│   │   ├── superpowers.json      # craftdesk.json template
│   │   ├── speckit.json
│   │   └── minimal.json
│   ├── settings.base.json        # existing global config
│   └── ...
└── bin/
    └── craftdesk-setup           # helper script
```

### Profile Format

Each profile is a `craftdesk.json` template:

```json
{
  "name": "local-project",
  "version": "1.0.0",
  "dependencies": {
    "superpowers": {
      "git": "https://github.com/anthropics/superpowers.git",
      "branch": "main"
    },
    "elements-of-style": {
      "git": "https://github.com/anthropics/elements-of-style.git",
      "branch": "main"
    }
  }
}
```

The `name` field is replaced with the actual project directory name during setup.

### Script Workflow

#### Step 1: Detect Repo State

- Confirm it's a git repo (exit if not)
- Check if `craftdesk.json` already exists (ask to overwrite or exit)
- Check if `.claude/` exists and whether it's tracked

#### Step 2: Prompt for Profile

```
Available profiles:
  1) superpowers - Brainstorming, planning, debugging workflows
  2) speckit - Spec-driven development tools
  3) minimal - Just the essentials

Which profile? [1]:
```

#### Step 3: Prompt for Commit Strategy

```
How should craftdesk files be managed?
  1) Commit to repo (for repos you own)
  2) Keep local only (for repos you don't control)

Choice [2]:
```

#### Step 4: Set Up Files

1. Copy profile to `craftdesk.json`, replacing `name` with directory name

2. If **"local only"**: append to `.git/info/exclude`:

   ```
   # craftdesk (local)
   craftdesk.json
   craftdesk.lock
   .claude/
   ```

3. If **"commit"**: add to `.gitignore`:

   ```
   .claude/settings.local.json
   ```

4. Run `craftdesk install`

#### Step 5: Done Message

```
✓ Craftdesk configured with 'superpowers' profile
  - craftdesk.json created
  - Dependencies installed to .claude/
  - Files excluded from git (local only mode)

Run 'craftdesk list' to see installed crafts.
```

## Limitations

### Craftdesk writes to `.claude/settings.json`

Craftdesk currently writes its plugin registry to `.claude/settings.json` using its own schema. This differs from Claude Code's native schema.

For repos with an existing `.claude/settings.json`, the entire `.claude/` directory is excluded in "local only" mode, so this doesn't cause conflicts.

**Future improvement**: Contribute to craftdesk to support writing to `.claude/settings.local.json` instead, which Claude Code natively merges with the base settings.

### No lockfile portability in local-only mode

When using "local only" mode, `craftdesk.lock` is excluded from git. If you re-clone the repo, you'll need to re-run `craftdesk install` and versions may differ.

This is acceptable for personal tooling that doesn't need to be shared.

## Implementation Tasks

1. Create `claude/profiles/` directory in dotfiles
2. Create initial profiles (superpowers, minimal)
3. Write `bin/craftdesk-setup` script
4. Update `claudeconfig.sh` to create minimal global config
5. Test in a repo you control (commit mode)
6. Test in a repo you don't control (local only mode)

## Future Enhancements

- `craftdesk-setup update` - Re-apply profile or switch profiles
- `craftdesk-setup status` - Show current profile and mode
- Contribute `.claude/settings.local.json` support to craftdesk
- Profile inheritance (e.g., `speckit` extends `minimal`)
