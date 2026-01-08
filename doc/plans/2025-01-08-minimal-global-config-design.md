# Minimal Global Config with Craftdesk

## Problem

The current Claude Code configuration installs all skill plugins globally via `claudeconfig.sh`. This creates:

- A bloated global `settings.json` with many enabled plugins
- Long permission lists for skills that may not be needed in every project
- No per-project customization of which skills are available

Now that `craftdesk-setup` exists, skills can be installed per-project. The global config should provide only infrastructure.

## Decision

Adopt a **hybrid model**:

- **Global config** provides infrastructure plugins only
- **Per-project craftdesk** provides skills tailored to the project

## Global Config Changes

### Enabled Plugins (settings.base.json)

**Keep globally:**

- `claude-notifications-go` - system notifications
- `tool-routing` - routes tool calls to better alternatives

**Remove from global (now per-project via craftdesk):**

- `superpowers`
- `elements-of-style`
- `superpowers-developing-for-claude-code`
- `superpowers-chrome`
- `document-skills`
- `git-workflows`
- `ci-cd-tools`
- `working-in-monorepos`
- `dev-tools`
- `debugging-tools`
- `gopls-lsp`

### Permissions (permissions.json)

**Keep:**

- `Bash(gh pr list:*)`, `Bash(gh pr view:*)`, `Bash(git worktree:*)`, `Bash(tree:*)`
- `mcp__MCPProxy__call_tool`, `mcp__MCPProxy__retrieve_tools`
- `WebFetch(domain:code.claude.com)`, `WebFetch(domain:github.com)`

**Remove:**

- All `Skill(...)` permissions
- All `Read(~/.claude/plugins/cache/...)` permissions
- Domain-specific WebFetch (karafka.io, trivy.dev, etc.)

### Marketplaces (claudeconfig.sh)

**Keep all marketplaces** - they're just registries for browsing:

- `superpowers-marketplace`
- `anthropic-agent-skills`
- `technicalpickles-marketplace`
- `claude-notifications-go`

### Installed Plugins (claudeconfig.sh)

**Install only:**

- `tool-routing@technicalpickles-marketplace`
- `claude-notifications-go@claude-notifications-go`

## Craftdesk Profile Updates

### Git Sources

| Skill                                  | Git URL                                                            | Path                         |
| -------------------------------------- | ------------------------------------------------------------------ | ---------------------------- |
| superpowers                            | https://github.com/obra/superpowers.git                            | (root)                       |
| elements-of-style                      | https://github.com/obra/the-elements-of-style.git                  | (root)                       |
| superpowers-chrome                     | https://github.com/obra/superpowers-chrome.git                     | (root)                       |
| superpowers-developing-for-claude-code | https://github.com/obra/superpowers-developing-for-claude-code.git | (root)                       |
| document-skills                        | https://github.com/anthropics/skills.git                           | skills                       |
| git-workflows                          | https://github.com/technicalpickles/pickled-claude-plugins.git     | plugins/git-workflows        |
| ci-cd-tools                            | https://github.com/technicalpickles/pickled-claude-plugins.git     | plugins/ci-cd-tools          |
| working-in-monorepos                   | https://github.com/technicalpickles/pickled-claude-plugins.git     | plugins/working-in-monorepos |
| dev-tools                              | https://github.com/technicalpickles/pickled-claude-plugins.git     | plugins/dev-tools            |

### Updated Profiles

**minimal.json** - No dependencies (unchanged)

**superpowers.json** - Core workflows:

- superpowers
- elements-of-style

**document-skills.json** - Document creation (unchanged):

- document-skills

**full.json** - Everything:

- superpowers
- elements-of-style
- superpowers-chrome
- superpowers-developing-for-claude-code
- document-skills
- git-workflows
- ci-cd-tools
- working-in-monorepos
- dev-tools

## Tool-Routing Enhancement

Tool-routing must discover routes from craftdesk-installed skills.

### New Discovery Function (config.py)

```python
def discover_craftdesk_routes(project_root: Path) -> list[Path]:
    """Find tool-routes.yaml in craftdesk-installed skills."""
    skills_dir = project_root / ".claude" / "skills"
    if not skills_dir.exists():
        return []

    paths = []
    for skill_dir in skills_dir.iterdir():
        if not skill_dir.is_dir():
            continue
        routes_file = skill_dir / "hooks" / "tool-routes.yaml"
        if routes_file.exists():
            paths.append(routes_file)

    return sorted(paths)
```

### Updated get_all_routes (cli.py)

Add after plugin routes discovery:

```python
# 2.5. Craftdesk-installed skills' routes
from tool_routing.config import discover_craftdesk_routes
for path in discover_craftdesk_routes(project_root):
    routes = load_routes_file(path)
    if routes:
        all_routes.append(routes)
        all_sources.append(str(path))
```

## Implementation Files

1. `claude/settings.base.json` - Remove skill plugins from enabledPlugins
2. `claude/permissions.json` - Remove Skill and plugin cache Read permissions
3. `claudeconfig.sh` - Remove skill plugin installations
4. `claude/profiles/superpowers.json` - Add elements-of-style
5. `claude/profiles/full.json` - Add all skills
6. `pickled-claude-plugins/plugins/tool-routing/src/tool_routing/config.py` - Add discover_craftdesk_routes
7. `pickled-claude-plugins/plugins/tool-routing/src/tool_routing/cli.py` - Call discover_craftdesk_routes

## Migration

After implementation:

1. Run `./claudeconfig.sh` to update global settings
2. In each project, run `craftdesk-setup` to install desired skills
3. Existing projects with craftdesk.json continue working
