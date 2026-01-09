# Minimal Global Config with Craftdesk

## Problem

`claudeconfig.sh` installs all skill plugins globally. This bloats `settings.json` with plugins many projects never use, clutters permissions with skill-specific entries, and prevents per-project customization.

Now that `craftdesk-setup` exists, projects can install their own skills. The global config should provide infrastructure only.

## Decision

Adopt a hybrid model: global config provides infrastructure, craftdesk provides skills per-project.

## Global Config Changes

### Enabled Plugins (settings.base.json)

**Keep:**

- `claude-notifications-go` — system notifications
- `tool-routing` — redirects tool calls to better alternatives

**Move to craftdesk:**

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

- All `Skill(...)` entries
- All `Read(~/.claude/plugins/cache/...)` entries
- Domain-specific WebFetch entries

### Marketplaces (claudeconfig.sh)

Keep all marketplaces for browsing:

- `superpowers-marketplace`
- `anthropic-agent-skills`
- `technicalpickles-marketplace`
- `claude-notifications-go`

### Installed Plugins (claudeconfig.sh)

Install only:

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

### Profiles

**minimal.json** — No dependencies

**superpowers.json** — Core workflows:

- superpowers
- elements-of-style

**document-skills.json** — Document creation:

- document-skills

**full.json** — All skills:

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

Tool-routing must discover routes from craftdesk-installed skills at `.claude/skills/*/hooks/tool-routes.yaml`.

### New Function (config.py)

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

### Integration (cli.py)

Add after plugin routes discovery:

```python
# Craftdesk-installed skills
from tool_routing.config import discover_craftdesk_routes
for path in discover_craftdesk_routes(project_root):
    routes = load_routes_file(path)
    if routes:
        all_routes.append(routes)
        all_sources.append(str(path))
```

## Files to Change

1. `claude/settings.base.json` — Remove skill plugins from enabledPlugins
2. `claude/permissions.json` — Remove Skill and plugin cache Read entries
3. `claudeconfig.sh` — Remove skill plugin installations
4. `claude/profiles/superpowers.json` — Add elements-of-style
5. `claude/profiles/full.json` — Add all skills
6. `pickled-claude-plugins/plugins/tool-routing/src/tool_routing/config.py` — Add discover_craftdesk_routes
7. `pickled-claude-plugins/plugins/tool-routing/src/tool_routing/cli.py` — Call discover_craftdesk_routes

## Migration

### Analysis Tool

`bin/analyze-claude-sessions` parses Claude session history to prioritize migration:

```bash
# Show projects with skill usage and suggested profiles
analyze-claude-sessions

# Generate migration commands for top N projects
analyze-claude-sessions --migrate --limit 15

# JSON output for scripting
analyze-claude-sessions --json
```

The tool:

- Parses `.claude/projects/` session files
- Extracts skill invocations from tool_use entries
- Calculates session counts, message totals, and last activity
- Suggests a craftdesk profile based on actual usage
- Flags uncovered skills (project-specific, not in standard profiles)

**Profile suggestions:**

| Skills Used                     | Profile         |
| ------------------------------- | --------------- |
| None                            | minimal         |
| Only superpowers/elements-style | superpowers     |
| Only document-skills            | document-skills |
| Multiple categories             | full            |

### Workflow

1. **Analyze usage:**

   ```bash
   analyze-claude-sessions
   ```

2. **Generate commands:**

   ```bash
   analyze-claude-sessions --migrate --limit 10 > migrate.sh
   ```

3. **Migrate projects:** Run `craftdesk-setup` in each, selecting the suggested profile.

4. **Update global config:**

   ```bash
   ./claudeconfig.sh
   ```

5. **Verify:** Open Claude in a migrated project. Skills load from `.claude/skills/`.

### Gradual Approach

To avoid disruption:

1. Keep global plugins enabled initially
2. Run `craftdesk-setup` in projects over time
3. Once key projects migrate, slim down global config
4. Projects without craftdesk lose skill access intentionally
