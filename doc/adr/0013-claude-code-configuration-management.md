# 13. Claude Code Configuration Management

Date: 2025-11-25

## Status

Accepted

## Context

Claude Code configuration includes settings (statusLine, co-authored, thinking mode), permissions (tool allowlists), marketplace setup, and plugin installation. This configuration needs to be:

- Reproducible across machines
- Role-aware (personal vs work environments)
- Version controlled (except sensitive data)
- Easy to regenerate and keep in sync

The existing dotfiles repository already uses:

- Role-based configuration (`$DOTPICKLES_ROLE`)
- Generated configs (gitconfig.sh builds .gitconfig.local)
- Symlinked files (home/ → $HOME)

We needed a way to manage Claude Code configuration that:

1. Doesn't commit sensitive data (AWS credentials)
2. Supports role-specific overrides
3. Handles idempotent marketplace/plugin installation
4. Works with manual additions (local-only settings)

## Decision

Implement Claude Code configuration management following the gitconfig.sh pattern:

### Configuration Structure

```
claude/
├── settings.base.json       # Core settings
├── settings.$ROLE.json      # Role overrides
├── permissions.json         # Base permissions
└── permissions.$ROLE.json   # Role-specific permissions
```

### Generation Script

`claudeconfig.sh` (similar to gitconfig.sh):

1. Installs marketplaces idempotently (checks before adding)
2. Installs plugins idempotently (checks before installing)
3. Merges settings: base + role-specific
4. Merges permissions: base + role-specific
5. Preserves local-only keys (awsAuthRefresh, env)
6. Generates `~/.claude/settings.json` atomically

### Integration

- `install.sh` runs `claudeconfig.sh` after gitconfig setup
- Manual regeneration: `./claudeconfig.sh`
- Marketplace/plugin lists hardcoded in script (like Fish configs)

### Alternatives Considered

1. **Template + manual merge**: Track settings.template.json, document manual copying

   - Rejected: Error-prone, not automated, doesn't support role-based config

2. **Modular JSON fragments**: Separate files per concern (plugins.json, statusline.json)

   - Rejected: Over-engineered for current needs, harder to understand structure

3. **Native settings.local.json**: Rely on Claude Code supporting local file merging

   - Rejected: Claude Code doesn't support this (confirmed via documentation check)

4. **Environment variable substitution**: Template with $AWS_PROFILE placeholders

   - Rejected: Doesn't handle complex nested JSON (env object), less flexible

5. **Separate marketplace/plugin scripts**: Individual files for each concern
   - Rejected: User wanted single file, following Fish pattern

## Consequences

### Positive

- **Consistent with existing patterns**: Uses same approach as gitconfig.sh
- **Role-aware**: Automatically adapts to personal/work environments
- **Idempotent**: Safe to run multiple times, no duplicate installations
- **Preserves manual additions**: Local-only settings survive regeneration
- **Automated setup**: Fresh machines get complete config via install.sh
- **Version controlled**: All configuration tracked except sensitive data

### Negative

- **Manual local settings**: AWS credentials must be added manually after generation
- **No validation of marketplace/plugin names**: Typos won't be caught until runtime
- **Hardcoded lists**: Adding plugins requires editing script (not separate config file)
- **Assumes jq available**: Requires jq for JSON merging (added to prerequisites)

### Maintenance

- **Adding permissions**: Edit claude/permissions.json or claude/permissions.$ROLE.json
- **Adding plugins**: Update both `plugins` array in claudeconfig.sh AND `enabledPlugins` in settings files
- **Adding settings**: Update claude/settings.base.json or role-specific files
- **Regeneration**: Run `./claudeconfig.sh` after any configuration changes
