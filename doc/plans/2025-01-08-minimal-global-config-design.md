# Minimal Global Config Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move skill plugins from global config to per-project craftdesk installation, leaving only infrastructure plugins globally.

**Architecture:** Global `claudeconfig.sh` installs only notifications and tool-routing. Craftdesk profiles provide skill dependencies per-project. Tool-routing discovers routes from `.claude/skills/` in addition to global plugins.

**Tech Stack:** Bash (claudeconfig.sh), Python (tool-routing), JSON (profiles, settings)

---

## Task 1: Update Craftdesk Profiles

**Files:**

- Modify: `claude/profiles/superpowers.json`
- Modify: `claude/profiles/full.json`

**Step 1: Update superpowers.json to include elements-of-style**

```json
{
  "name": "local-project",
  "version": "1.0.0",
  "description": "Core workflows - brainstorming, planning, debugging, writing",
  "dependencies": {
    "superpowers": {
      "git": "https://github.com/obra/superpowers.git",
      "branch": "main"
    },
    "elements-of-style": {
      "git": "https://github.com/obra/the-elements-of-style.git",
      "branch": "main"
    }
  }
}
```

**Step 2: Update full.json with all skills**

```json
{
  "name": "local-project",
  "version": "1.0.0",
  "description": "Full setup - superpowers + document skills + chrome + git workflows",
  "dependencies": {
    "superpowers": {
      "git": "https://github.com/obra/superpowers.git",
      "branch": "main"
    },
    "elements-of-style": {
      "git": "https://github.com/obra/the-elements-of-style.git",
      "branch": "main"
    },
    "superpowers-chrome": {
      "git": "https://github.com/obra/superpowers-chrome.git",
      "branch": "main"
    },
    "superpowers-developing-for-claude-code": {
      "git": "https://github.com/obra/superpowers-developing-for-claude-code.git",
      "branch": "main"
    },
    "document-skills": {
      "git": "https://github.com/anthropics/skills.git",
      "branch": "main",
      "path": "skills"
    },
    "git-workflows": {
      "git": "https://github.com/technicalpickles/pickled-claude-plugins.git",
      "branch": "main",
      "path": "plugins/git-workflows"
    },
    "ci-cd-tools": {
      "git": "https://github.com/technicalpickles/pickled-claude-plugins.git",
      "branch": "main",
      "path": "plugins/ci-cd-tools"
    },
    "working-in-monorepos": {
      "git": "https://github.com/technicalpickles/pickled-claude-plugins.git",
      "branch": "main",
      "path": "plugins/working-in-monorepos"
    },
    "dev-tools": {
      "git": "https://github.com/technicalpickles/pickled-claude-plugins.git",
      "branch": "main",
      "path": "plugins/dev-tools"
    }
  }
}
```

**Step 3: Commit**

```bash
git add claude/profiles/superpowers.json claude/profiles/full.json
git commit -m "feat(craftdesk): extend profiles with all skill dependencies"
```

---

## Task 2: Add Craftdesk Route Discovery to Tool-Routing

**Files:**

- Modify: `~/workspace/pickled-claude-plugins/plugins/tool-routing/src/tool_routing/config.py`
- Test: `~/workspace/pickled-claude-plugins/plugins/tool-routing/tests/test_config.py`

**Step 1: Write failing test for discover_craftdesk_routes**

Add to `tests/test_config.py`:

```python
def test_discover_craftdesk_routes_finds_routes_in_skills_dir(tmp_path):
    """Test that craftdesk-installed skills' routes are discovered."""
    # Create .claude/skills structure
    skills_dir = tmp_path / ".claude" / "skills"
    skill_a = skills_dir / "skill-a" / "hooks"
    skill_b = skills_dir / "skill-b" / "hooks"
    skill_a.mkdir(parents=True)
    skill_b.mkdir(parents=True)

    # Create route files
    (skill_a / "tool-routes.yaml").write_text("routes: []")
    (skill_b / "tool-routes.yaml").write_text("routes: []")

    # Skill without routes
    (skills_dir / "skill-c").mkdir()

    from tool_routing.config import discover_craftdesk_routes
    paths = discover_craftdesk_routes(tmp_path)

    assert len(paths) == 2
    assert skill_a / "tool-routes.yaml" in paths
    assert skill_b / "tool-routes.yaml" in paths


def test_discover_craftdesk_routes_returns_empty_when_no_skills_dir(tmp_path):
    """Test that missing .claude/skills returns empty list."""
    from tool_routing.config import discover_craftdesk_routes
    paths = discover_craftdesk_routes(tmp_path)
    assert paths == []
```

**Step 2: Run test to verify it fails**

Run: `cd ~/workspace/pickled-claude-plugins/plugins/tool-routing && pytest tests/test_config.py -v -k craftdesk`

Expected: FAIL with "cannot import name 'discover_craftdesk_routes'"

**Step 3: Implement discover_craftdesk_routes**

Add to `src/tool_routing/config.py`:

```python
def discover_craftdesk_routes(project_root: Path) -> list[Path]:
    """Find tool-routes.yaml in craftdesk-installed skills.

    Craftdesk installs skills to: project_root/.claude/skills/<name>/
    Each skill may have: hooks/tool-routes.yaml
    """
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

**Step 4: Run test to verify it passes**

Run: `cd ~/workspace/pickled-claude-plugins/plugins/tool-routing && pytest tests/test_config.py -v -k craftdesk`

Expected: PASS

**Step 5: Commit**

```bash
cd ~/workspace/pickled-claude-plugins/plugins/tool-routing
git add src/tool_routing/config.py tests/test_config.py
git commit -m "feat(tool-routing): discover routes from craftdesk-installed skills"
```

---

## Task 3: Integrate Craftdesk Routes in CLI

**Files:**

- Modify: `~/workspace/pickled-claude-plugins/plugins/tool-routing/src/tool_routing/cli.py`
- Test: `~/workspace/pickled-claude-plugins/plugins/tool-routing/tests/test_cli.py`

**Step 1: Write failing test for craftdesk routes integration**

Add to `tests/test_cli.py`:

```python
def test_get_all_routes_includes_craftdesk_skills(tmp_path, monkeypatch):
    """Test that craftdesk-installed skill routes are included."""
    # Create craftdesk skill with routes
    skill_dir = tmp_path / ".claude" / "skills" / "test-skill" / "hooks"
    skill_dir.mkdir(parents=True)
    (skill_dir / "tool-routes.yaml").write_text("""
routes:
  - tool: TestTool
    description: "Test tool from craftdesk skill"
""")

    monkeypatch.chdir(tmp_path)

    from tool_routing.cli import get_all_routes
    routes, sources = get_all_routes()

    # Should find the craftdesk skill routes
    craftdesk_sources = [s for s in sources if ".claude/skills" in s]
    assert len(craftdesk_sources) == 1
    assert "test-skill" in craftdesk_sources[0]
```

**Step 2: Run test to verify it fails**

Run: `cd ~/workspace/pickled-claude-plugins/plugins/tool-routing && pytest tests/test_cli.py -v -k craftdesk`

Expected: FAIL (craftdesk routes not discovered)

**Step 3: Add craftdesk discovery to get_all_routes**

In `src/tool_routing/cli.py`, find `get_all_routes()` and add after plugin routes discovery:

```python
from tool_routing.config import discover_craftdesk_routes

# ... existing code ...

# Craftdesk-installed skills' routes
for path in discover_craftdesk_routes(project_root):
    routes = load_routes_file(path)
    if routes:
        all_routes.append(routes)
        all_sources.append(str(path))
```

**Step 4: Run test to verify it passes**

Run: `cd ~/workspace/pickled-claude-plugins/plugins/tool-routing && pytest tests/test_cli.py -v -k craftdesk`

Expected: PASS

**Step 5: Run full test suite**

Run: `cd ~/workspace/pickled-claude-plugins/plugins/tool-routing && pytest`

Expected: All tests pass

**Step 6: Commit**

```bash
cd ~/workspace/pickled-claude-plugins/plugins/tool-routing
git add src/tool_routing/cli.py tests/test_cli.py
git commit -m "feat(tool-routing): include craftdesk skill routes in discovery"
```

---

## Task 4: Slim Down Global Settings

**Files:**

- Modify: `claude/settings.base.json`

**Step 1: Update settings.base.json to only enable infrastructure plugins**

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/workspace/dotfiles/bin/claude-status-line"
  },
  "includeCoAuthoredBy": false,
  "alwaysThinkingEnabled": false,
  "enabledPlugins": {
    "claude-notifications-go@claude-notifications-go": true,
    "tool-routing@technicalpickles-marketplace": true
  }
}
```

**Step 2: Commit**

```bash
git add claude/settings.base.json
git commit -m "feat(claude): slim down global plugins to infrastructure only"
```

---

## Task 5: Slim Down Global Permissions

**Files:**

- Modify: `claude/permissions.json`

**Step 1: Update permissions.json to remove skill-related entries**

```json
[
  "Bash(gh pr list:*)",
  "Bash(gh pr view:*)",
  "Bash(git worktree:*)",
  "Bash(tree:*)",
  "mcp__MCPProxy__call_tool",
  "mcp__MCPProxy__retrieve_tools",
  "WebFetch(domain:code.claude.com)",
  "WebFetch(domain:github.com)"
]
```

**Step 2: Commit**

```bash
git add claude/permissions.json
git commit -m "feat(claude): remove skill-related permissions from global config"
```

---

## Task 6: Update claudeconfig.sh

**Files:**

- Modify: `claudeconfig.sh`

**Step 1: Update marketplaces array (keep all)**

Find the `marketplaces` array and ensure it contains:

```bash
local marketplaces=(
  "superpowers-marketplace"
  "anthropic-agent-skills"
  "technicalpickles-marketplace"
  "claude-notifications-go"
)
```

**Step 2: Update plugins array (infrastructure only)**

Find the `plugins` array and replace with:

```bash
local plugins=(
  "tool-routing@technicalpickles-marketplace"
  "claude-notifications-go@claude-notifications-go"
)
```

**Step 3: Add helpful message at end**

Add after settings generation:

```bash
echo ""
echo "Note: Skills are now installed per-project via craftdesk."
echo "  Run 'craftdesk-setup' in a project to configure skills."
```

**Step 4: Commit**

```bash
git add claudeconfig.sh
git commit -m "feat(claudeconfig): install only infrastructure plugins globally"
```

---

## Task 7: Test Full Migration Flow

**Step 1: Regenerate global config**

Run: `./claudeconfig.sh`

Expected: Completes without error, shows note about craftdesk

**Step 2: Verify settings.json has minimal plugins**

Run: `jq '.enabledPlugins' ~/.claude/settings.json`

Expected: Only `claude-notifications-go` and `tool-routing`

**Step 3: Test craftdesk-setup in a test project**

```bash
cd /tmp/craftdesk-test
craftdesk-setup
# Select "full" profile
craftdesk install
```

Expected: Skills installed to `.claude/skills/`

**Step 4: Verify tool-routing finds craftdesk routes**

```bash
cd /tmp/craftdesk-test
# Add a tool-routes.yaml to one of the installed skills for testing
tool-routing validate
```

Expected: Shows routes from `.claude/skills/` if any exist

**Step 5: Final commit for dotfiles**

```bash
git add -A
git commit -m "feat: complete minimal global config migration"
```

---

## Migration Checklist

After implementation, use `bin/analyze-claude-sessions` to migrate existing projects:

1. Run `analyze-claude-sessions` to see projects and suggested profiles
2. Run `analyze-claude-sessions --migrate --limit 10` for migration commands
3. Execute `craftdesk-setup` in each project
4. Verify skills load from `.claude/skills/`
