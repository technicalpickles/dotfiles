# 12. Extract Devcontainer as Reusable Template

Date: 2025-11-25

## Status

Accepted

Supersedes [8. Disable Spotlight via LaunchAgent](0008-disable-spotlight-via-launchagent.md) (for devcontainer-related changes)

Related to:

- [doc/plans/2025-11-06-devcontainer-live-editing.md](../plans/2025-11-06-devcontainer-live-editing.md) (superseded)
- [doc/plans/2025-11-06-devcontainer-live-editing-implementation.md](../plans/2025-11-06-devcontainer-live-editing-implementation.md) (superseded)

## Context

Initially, this dotfiles repository had a custom devcontainer configuration specifically for developing the dotfiles themselves. The devcontainer provided:

- Fish shell with starship prompt
- Pre-installed dotfiles from this repository
- Docker-in-Docker for testing container workflows
- 1Password CLI integration
- VS Code extensions and settings

The implementation used:

- Custom Dockerfile that copied the repo and ran install.sh
- Post-create script that swapped the installed directory with a workspace symlink
- Helper scripts (bin/devcontainer-{build,run,stop})
- npm scripts for devcontainer operations

This approach worked well for developing dotfiles, but we wanted to:

1. Use the same development environment setup for other projects
2. Apply our personal dotfiles to any codebase
3. Avoid duplicating devcontainer configuration across repositories

## Decision

Extract the devcontainer configuration into a separate, reusable template published at https://github.com/technicalpickles/pickled-devcontainer.

The pickled-devcontainer template:

- Is a proper [Dev Container Template](https://containers.dev/templates)
- Can be applied to any project via VS Code or CLI
- Accepts configuration options (dotfiles repo URL, branch, environment variables)
- Uses the devcontainer Feature system for composable functionality
- Is maintained and versioned independently

This dotfiles repository will **dogfood** the template by:

- Removing all custom devcontainer implementation
- Using pickled-devcontainer applied to itself
- Serving as the primary testing ground for template changes

## Consequences

### Positive

- **Single source of truth**: Devcontainer logic lives in one place
- **Reusability**: Can apply dotfiles environment to any project
- **Better testing**: Dogfooding ensures the template works in real usage
- **Simpler maintenance**: Don't maintain parallel implementations
- **Proper versioning**: Template has its own release cycle
- **Community value**: Others can use the template for their dotfiles

### Negative

- **Two repositories**: Must coordinate changes between dotfiles and template
- **Indirection**: Template development requires working in separate repo
- **Bootstrap dependency**: This repo depends on external template

### Cleanup Required

The following files are now obsolete and removed:

**Devcontainer implementation:**

- `.devcontainer/` directory (Dockerfile, devcontainer.json, post-create.sh)
- `.devcontainer/features/dotfiles-setup/` (custom feature)

**Helper scripts:**

- `bin/devcontainer-build`
- `bin/devcontainer-run`
- `bin/devcontainer-stop`

**Outdated test file:**

- `Dockerfile` (root level - old tide test)

**Design documents:**

- `doc/plans/2025-11-06-devcontainer-live-editing.md`
- `doc/plans/2025-11-06-devcontainer-live-editing-implementation.md`

**Package.json:**

- npm scripts: `devcontainer:*` (build, up, exec, stop, clean)
- devDependency: `@devcontainers/cli` (no longer needed locally)

### Documentation Updates

**CLAUDE.md** updated to:

- Reference pickled-devcontainer as the canonical implementation
- Provide instructions for applying the template to this repo
- Link to pickled-devcontainer documentation
- Remove references to old live-editing approach

## Implementation

The pickled-devcontainer template provides:

1. **Dockerfile** that installs dotfiles during build
2. **Feature-based architecture** for composable functionality
3. **Post-create script** that swaps installed dotfiles with workspace mount
4. **Template metadata** for VS Code integration
5. **CLI helpers** for applying template to projects

To use it with this repository:

```bash
cd ~/workspace/pickled-devcontainer
./bin/apply ~/workspace/dotfiles
```

Or via VS Code:

1. Command Palette → "Add Dev Container Configuration Files"
2. Search for "Dotfiles Dev Environment"
3. Configure options (defaults to this repo's URL)

## References

- pickled-devcontainer: https://github.com/technicalpickles/pickled-devcontainer
- Dev Container Templates: https://containers.dev/templates
- Dev Container Features: https://containers.dev/features
