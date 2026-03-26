# Claudeconfig Stacks Refactor - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure Claude Code config from flat `permissions.*.json` files into `roles/` + `stacks/` directories with co-located permissions and sandbox config.

**Architecture:** Role files (`roles/base.jsonc`, etc.) hold settings + base permissions + sandbox scalars. Stack files (`stacks/*.jsonc`) hold per-topic permissions + sandbox arrays (network hosts, filesystem write paths). `claudeconfig.sh` merges everything into `~/.claude/settings.json`.

**Tech Stack:** Bash, jq, JSONC (parsed via Node.js or sed fallback)

**Spec:** `docs/plans/2026-03-25-claudeconfig-stacks-refactor.md`

**Working directory:** `/Users/josh.nichols/pickleton/repos/dotfiles/worktrees/main/`

---

## File Map

### Created

- `claude/roles/base.jsonc` - Base settings + safety permissions + sandbox scalars + base network hosts
- `claude/roles/personal.jsonc` - Empty role placeholder
- `claude/roles/work.jsonc` - AWS/Bedrock settings + work-specific permissions + SSO network host
- `claude/stacks/beans.jsonc` - Beans permissions (from `permissions.beans.json`)
- `claude/stacks/buildkite.jsonc` - NEW: buildkite.com host + bktide write path
- `claude/stacks/colima.jsonc` - Colima permissions + `~/.colima` write path
- `claude/stacks/docker.jsonc` - Docker permissions + `~/.docker` write path
- `claude/stacks/docs.jsonc` - NEW: karafka.io, lima-vm.io hosts + WebFetch
- `claude/stacks/git.jsonc` - Git permissions + hk.jdx.dev host + WebFetch (from `permissions.git.jsonc`)
- `claude/stacks/github.jsonc` - GH CLI permissions + github hosts + gh write paths + WebFetch
- `claude/stacks/go.jsonc` - Go permissions + go write paths
- `claude/stacks/mcp.jsonc` - MCP permissions (from `permissions.mcp.json`)
- `claude/stacks/mise.jsonc` - Mise permissions + mise hosts + mise write paths + WebFetch
- `claude/stacks/node.jsonc` - Node permissions + npm registry host + node/npm/pnpm/yarn write paths
- `claude/stacks/python.jsonc` - Python permissions + uv/pip/pre-commit write paths
- `claude/stacks/ruby.jsonc` - Ruby permissions + bundle/gem/rbenv write paths
- `claude/stacks/rust.jsonc` - Rust permissions + cargo/rustup write paths
- `claude/stacks/shell.jsonc` - Shell permissions + formulae.brew.sh host
- `claude/stacks/skills.jsonc` - Skill permissions (from `permissions.skills.json`)

### Modified

- `claudeconfig.sh` - Rewritten `generate_settings()` function
- `claude/README.md` - Rewritten for new structure

### Deleted (final task)

- `claude/settings.base.json`
- `claude/settings.personal.json`
- `claude/settings.work.json`
- `claude/permissions.json`
- `claude/permissions.personal.json`
- `claude/permissions.work.json`
- `claude/permissions.beans.json`
- `claude/permissions.colima.json`
- `claude/permissions.docker.json`
- `claude/permissions.git.jsonc`
- `claude/permissions.github.json`
- `claude/permissions.go.json`
- `claude/permissions.mcp.json`
- `claude/permissions.mise.json`
- `claude/permissions.node.json`
- `claude/permissions.python.json`
- `claude/permissions.ruby.json`
- `claude/permissions.rust.json`
- `claude/permissions.shell.json`
- `claude/permissions.skills.json`
- `claude/permissions.web.json`

---

### Task 1: Audit live settings for drift, then snapshot

Before changing anything, review the live `~/.claude/settings.json` to catch any drift since the spec was written. New permissions, hosts, write paths, or settings may have been added by Claude Code sessions or manual edits. These need to be accounted for in the role/stack files.

**Files:**
- Read: `~/.claude/settings.json`

- [ ] **Step 1: Review live settings.json for drift**

Compare the live file against what the spec expects. Check for:
- New permissions in `allow`/`ask`/`deny` not in any source `permissions.*.json` file
- New network hosts in `sandbox.network.allowedHosts` beyond the 15 in the spec
- New filesystem write paths in `sandbox.filesystem.allowWrite` beyond the 64 in the spec
- New top-level keys (settings, env vars) not in the spec
- Changed values (e.g. model names updated since spec was written)

```bash
# Quick counts to compare against spec expectations
echo "Allow: $(jq '.permissions.allow | length' ~/.claude/settings.json)"
echo "Ask: $(jq '.permissions.ask | length' ~/.claude/settings.json)"
echo "Deny: $(jq '.permissions.deny | length' ~/.claude/settings.json)"
echo "Hosts: $(jq '.sandbox.network.allowedHosts | length' ~/.claude/settings.json 2>/dev/null || echo 'none')"
echo "Write paths: $(jq '.sandbox.filesystem.allowWrite | length' ~/.claude/settings.json 2>/dev/null || echo 'none')"
echo "Top-level keys: $(jq 'keys[]' ~/.claude/settings.json)"
```

If any drift is found, decide for each item:
- Which role or stack file should it go in?
- Is it a local_key that should be preserved but not managed?
- Is it stale and should be dropped?

Update the role/stack file content in subsequent tasks to include any drift.

- [ ] **Step 2: Save current live settings as reference**

```bash
cp ~/.claude/settings.json /tmp/claude-settings-before-refactor.json
```

- [ ] **Step 3: Record exact counts for verification later**

```bash
jq '{
  allow_count: (.permissions.allow | length),
  ask_count: (.permissions.ask | length),
  deny_count: (.permissions.deny | length),
  host_count: (.sandbox.network.allowedHosts // [] | length),
  write_path_count: (.sandbox.filesystem.allowWrite // [] | length)
}' /tmp/claude-settings-before-refactor.json > /tmp/claude-settings-counts.json
cat /tmp/claude-settings-counts.json
```

These counts become the baseline for Task 6 verification.

---

### Task 2: Create role files

**Files:**
- Create: `claude/roles/base.jsonc`
- Create: `claude/roles/personal.jsonc`
- Create: `claude/roles/work.jsonc`
- Read: `claude/settings.base.json` (source for base settings)
- Read: `claude/permissions.json` (source for base permissions)
- Read: `claude/settings.work.json` (source for work settings)
- Read: `claude/permissions.work.json` (source for work permissions)
- Read: `claude/permissions.personal.json` (source)
- Read: `claude/settings.personal.json` (source)

- [ ] **Step 1: Create `claude/roles/` directory**

```bash
mkdir -p claude/roles
```

- [ ] **Step 2: Create `claude/roles/base.jsonc`**

Merge content from `settings.base.json` + `permissions.json`. Add sandbox scalars and base network hosts per spec. Add `Read(~/.claude/plugins/cache/**)` and `WebFetch(domain:code.claude.com)` to allow list.

The file should have this structure (abbreviated, full content from source files):

```jsonc
{
  // Base settings
  "statusLine": {
    "type": "command",
    "command": "npx -y ccstatusline@latest",
    "padding": 0
  },
  "includeCoAuthoredBy": true,

  // Permissions: base safety rules
  "permissions": {
    "allow": [
      // ... all entries from permissions.json .allow ...
      // NEW: plugin cache read access
      "Read(~/.claude/plugins/cache/**)",
      // From old web.json
      "WebFetch(domain:code.claude.com)"
    ],
    "ask": [
      // ... all entries from permissions.json .ask ...
    ],
    "deny": [
      // ... all entries from permissions.json .deny ...
    ]
  },

  // Sandbox: base config (source: agent-safehouse)
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "enableWeakerNetworkIsolation": true,
    "network": {
      "allowedHosts": [
        "api.anthropic.com",  // claude infrastructure
        "code.claude.com"     // claude docs
      ]
    }
  }
}
```

Copy the actual allow/ask/deny arrays from `permissions.json` verbatim, adding the two new entries to allow.

- [ ] **Step 3: Create `claude/roles/personal.jsonc`**

```jsonc
{
  // Personal role: no overrides currently
  // Add personal-specific settings, permissions, or sandbox config here
}
```

- [ ] **Step 4: Create `claude/roles/work.jsonc`**

Merge `settings.work.json` + `permissions.work.json`. Add SSO network host. Use the model names from the live `~/.claude/settings.json` (they may have been updated since `settings.work.json` was last committed).

```jsonc
{
  // Work role settings
  "awsAuthRefresh": "aws sso login --profile $AWS_PROFILE",
  "env": {
    // ... env vars from live settings.json, not the stale settings.work.json ...
  },

  // Work-specific permissions
  "permissions": {
    "allow": [
      "Bash(bin/rspec:*)",
      "Bash(bin/rubocop:*)",
      "Bash(bundle exec rspec:*)",
      "Bash(bundle exec rubocop:*)",
      "Bash(bundle install)",
      "Bash(npx bktide build:*)",
      "Bash(npx bktide)",
      "Bash(npx bktide:*)"
    ]
  },

  // Work-specific sandbox (source: agent-safehouse)
  "sandbox": {
    "network": {
      "allowedHosts": [
        "portal.sso.us-west-2.amazonaws.com"  // AWS SSO
      ]
    }
  }
}
```

- [ ] **Step 5: Commit role files**

```bash
git add claude/roles/base.jsonc claude/roles/personal.jsonc claude/roles/work.jsonc
git commit -m "feat: create role files for claudeconfig stacks refactor

Merges settings.*.json + permissions.{json,personal,work}.json into
roles/base.jsonc, roles/personal.jsonc, roles/work.jsonc.

Adds sandbox scalars and base network hosts (source: agent-safehouse).
Adds Read(~/.claude/plugins/cache/**) to base allow list."
```

---

### Task 3: Create stack files (permissions-only stacks)

These stacks carry forward existing permissions unchanged, just wrapped in the new schema. No sandbox config.

**Files:**
- Create: `claude/stacks/beans.jsonc`
- Create: `claude/stacks/mcp.jsonc`
- Create: `claude/stacks/skills.jsonc`

- [ ] **Step 1: Create `claude/stacks/` directory**

```bash
mkdir -p claude/stacks
```

- [ ] **Step 2: Create `claude/stacks/beans.jsonc`**

Read `permissions.beans.json`, wrap in `{"permissions": {...}}`:

```jsonc
{
  // Beans issue tracker
  "permissions": {
    "allow": [
      "Bash(beans create:*)",
      "Bash(beans list:*)",
      "Bash(beans query:*)",
      "Bash(beans show:*)",
      "Bash(beans update:*)",
      "Bash(beans:*)"
    ],
    "ask": [
      "Bash(beans archive:*)",
      "Bash(beans delete:*)"
    ]
  }
}
```

- [ ] **Step 3: Create `claude/stacks/mcp.jsonc`**

Read `permissions.mcp.json`, wrap in `{"permissions": {...}}`:

```jsonc
{
  // MCP proxy tools
  "permissions": {
    "allow": [
      "mcp__MCPProxy__call_tool_read",
      "mcp__MCPProxy__call_tool_write",
      "mcp__MCPProxy__read_cache",
      "mcp__MCPProxy__retrieve_tools",
      "mcp__MCPProxy__upstream_servers"
    ],
    "ask": [
      "mcp__MCPProxy__call_tool_destructive"
    ]
  }
}
```

- [ ] **Step 4: Create `claude/stacks/skills.jsonc`**

Read `permissions.skills.json`, wrap in `{"permissions": {...}}`. Copy all `Skill(...)` entries verbatim.

- [ ] **Step 5: Commit permissions-only stacks**

```bash
git add claude/stacks/beans.jsonc claude/stacks/mcp.jsonc claude/stacks/skills.jsonc
git commit -m "feat: create permissions-only stack files (beans, mcp, skills)"
```

---

### Task 4: Create stack files (permissions + sandbox stacks)

These stacks carry forward existing permissions AND add new sandbox config from agent-safehouse.

**Files:**
- Create: `claude/stacks/buildkite.jsonc` (NEW)
- Create: `claude/stacks/colima.jsonc`
- Create: `claude/stacks/docker.jsonc`
- Create: `claude/stacks/docs.jsonc` (NEW)
- Create: `claude/stacks/git.jsonc`
- Create: `claude/stacks/github.jsonc`
- Create: `claude/stacks/go.jsonc`
- Create: `claude/stacks/mise.jsonc`
- Create: `claude/stacks/node.jsonc`
- Create: `claude/stacks/python.jsonc`
- Create: `claude/stacks/ruby.jsonc`
- Create: `claude/stacks/rust.jsonc`
- Create: `claude/stacks/shell.jsonc`
- Read: All corresponding `permissions.*.json` files for current permissions

For each stack: read the source permissions file, wrap in the new schema with `{"permissions": {...}}`, add sandbox config per spec. Use `// source: agent-safehouse` comments on sandbox sections. Refer to the spec's "Sandbox Config Distribution" section for exact hosts and paths per stack.

- [ ] **Step 1: Create `claude/stacks/buildkite.jsonc`** (NEW, sandbox only)

```jsonc
{
  // Buildkite CI (source: agent-safehouse)
  "sandbox": {
    "network": {
      "allowedHosts": ["buildkite.com"]
    },
    "filesystem": {
      "allowWrite": ["~/.local/state/bktide"]
    }
  }
}
```

- [ ] **Step 2: Create `claude/stacks/docs.jsonc`** (NEW)

```jsonc
{
  // Reference documentation sites
  "permissions": {
    "allow": [
      "WebFetch(domain:karafka.io)",
      "WebFetch(domain:lima-vm.io)"
    ]
  },
  // source: agent-safehouse
  "sandbox": {
    "network": {
      "allowedHosts": [
        "karafka.io",
        "lima-vm.io"
      ]
    }
  }
}
```

- [ ] **Step 3: Create `claude/stacks/git.jsonc`**

Copy from `permissions.git.jsonc` (preserving comments), wrap in `{"permissions": {...}}`, add `WebFetch(domain:hk.jdx.dev)` to allow, add sandbox network host.

- [ ] **Step 4: Create `claude/stacks/github.jsonc`**

From `permissions.github.json` + sandbox (4 network hosts, 4 filesystem write paths) + WebFetch (docs.github.com, github.com, raw.githubusercontent.com).

- [ ] **Step 5: Create `claude/stacks/mise.jsonc`**

From `permissions.mise.json` + sandbox (2 network hosts, 5 filesystem write paths) + WebFetch (mise.jdx.dev).

- [ ] **Step 6: Create `claude/stacks/node.jsonc`**

From `permissions.node.json` + sandbox (1 network host: registry.npmjs.org, 27 filesystem write paths for npm/pnpm/yarn/corepack/test browsers).

- [ ] **Step 7: Create remaining stacks with sandbox filesystem paths**

For each, read source permissions, wrap, add sandbox filesystem per spec:

- `claude/stacks/colima.jsonc`: `permissions.colima.json` + `"allowWrite": ["~/.colima"]`
- `claude/stacks/docker.jsonc`: `permissions.docker.json` + `"allowWrite": ["~/.docker"]`
- `claude/stacks/go.jsonc`: `permissions.go.json` + 7 go filesystem paths
- `claude/stacks/python.jsonc`: `permissions.python.json` + 8 python filesystem paths
- `claude/stacks/ruby.jsonc`: `permissions.ruby.json` + 6 ruby filesystem paths
- `claude/stacks/rust.jsonc`: `permissions.rust.json` + 4 rust filesystem paths
- `claude/stacks/shell.jsonc`: `permissions.shell.json` + `"allowedHosts": ["formulae.brew.sh"]`

- [ ] **Step 8: Commit all stacks**

```bash
git add claude/stacks/
git commit -m "feat: create stack files with permissions + sandbox config

Migrates permissions.*.json into stacks/*.jsonc with new schema.
Adds sandbox config (network hosts, filesystem write paths) from
agent-safehouse. Creates new stacks: buildkite.jsonc, docs.jsonc.
Distributes web.json WebFetch permissions to their topic stacks."
```

---

### Task 5: Rewrite claudeconfig.sh merge logic

**Files:**
- Modify: `claudeconfig.sh` (the `generate_settings()` function, lines 70-182)

- [ ] **Step 1: Read current `claudeconfig.sh` fully**

Understand the current `generate_settings()` function before modifying.

- [ ] **Step 2: Rewrite `generate_settings()`**

Key changes:

1. `local_keys` becomes `("model" "enabledPlugins" "extraKnownMarketplaces")`
2. Load `roles/base.jsonc` via `read_json`
3. Extract settings keys (everything except `permissions` and `sandbox`) with `jq 'del(.permissions, .sandbox)'`
4. Extract permissions arrays and sandbox config separately from base
5. Load `roles/$ROLE.jsonc`, deep merge settings keys only, extract and concat permissions/sandbox arrays separately (do NOT deep-merge arrays, they must be concatenated)
6. Loop `stacks/*.jsonc` (sorted), concat permissions and sandbox arrays from each
7. Dedup and sort all arrays
8. Extract sandbox scalars from merged role config
9. Assemble final JSON: settings + `permissions` + `sandbox` (scalars + arrays)
10. Merge in `local_keys` from existing `~/.claude/settings.json`
11. Validate and write

**Critical detail:** Permissions and sandbox arrays must be extracted separately from each role file and concatenated. jq's `*` operator replaces arrays, so deep-merging role files would lose base permissions when the role also defines permissions. The current code already handles this pattern for permissions (separate extraction), extend it to sandbox arrays.

- [ ] **Step 3: Commit claudeconfig.sh changes**

```bash
git add claudeconfig.sh
git commit -m "feat: rewrite claudeconfig.sh for roles/stacks structure

Replaces flat permissions.*.json merging with roles/ + stacks/ system.
Merges permissions arrays AND sandbox arrays (network hosts, filesystem
write paths) from all source files. Local keys: model, enabledPlugins,
extraKnownMarketplaces."
```

---

### Task 6: Verify output matches

**Files:**
- Read: `~/.claude/settings.json` (generated output)
- Read: `/tmp/claude-settings-before-refactor.json` (saved in Task 1)

- [ ] **Step 1: Run refactored claudeconfig.sh**

```bash
cd /Users/josh.nichols/pickleton/repos/dotfiles/worktrees/main
DOTPICKLES_ROLE=work ./claudeconfig.sh
```

Expected: No errors, "Settings generated successfully" message.

- [ ] **Step 2: Diff against saved reference**

```bash
diff <(jq -S . /tmp/claude-settings-before-refactor.json) <(jq -S . ~/.claude/settings.json)
```

Expected diff:
- The new `Read(~/.claude/plugins/cache/**)` permission (added to base role)
- Network `allowedHosts` array now populated (these are NEW in the generated output; previously they were either absent or came from Claude Code's own sandbox enforcement, not user settings)
- Ordering differences (dedup + sort)
- No permissions should be lost

If the diff shows missing permissions or unexpected changes, investigate and fix before proceeding.

- [ ] **Step 3: Verify counts against baseline**

Compare against the counts saved in Task 1 Step 3:

```bash
echo "=== Before ==="
cat /tmp/claude-settings-counts.json

echo "=== After ==="
jq '{
  allow_count: (.permissions.allow | length),
  ask_count: (.permissions.ask | length),
  deny_count: (.permissions.deny | length),
  host_count: (.sandbox.network.allowedHosts // [] | length),
  write_path_count: (.sandbox.filesystem.allowWrite // [] | length)
}' ~/.claude/settings.json
```

Expected:
- `allow_count`: baseline + 1 (the new `Read(~/.claude/plugins/cache/**)`)
- `ask_count`: same as baseline
- `deny_count`: same as baseline
- `host_count`: 15 (may increase from baseline if hosts were absent before)
- `write_path_count`: same as baseline (64)

- [ ] **Step 4: Reverse-diff: verify no source permissions were lost**

For each stack and role file, verify all its permissions appear in the generated output:

```bash
for f in claude/stacks/*.jsonc claude/roles/*.jsonc; do
  node -e "
    const fs = require('fs');
    const c = fs.readFileSync('$f', 'utf8')
      .replace(/\/\/.*$/gm, '')
      .replace(/\/\*[\s\S]*?\*\//g, '')
      .replace(/,(\s*[}\]])/g, '\$1');
    try {
      const j = JSON.parse(c);
      const allow = j.permissions?.allow || [];
      const out = JSON.parse(fs.readFileSync(process.env.HOME + '/.claude/settings.json', 'utf8'));
      const outAllow = new Set(out.permissions.allow);
      const missing = allow.filter(a => !outAllow.has(a));
      if (missing.length) console.log('MISSING from $f:', missing);
    } catch(e) {}
  "
done
```

Expected: No output (all source permissions present in generated output).

- [ ] **Step 5: Commit any fixes if needed**

---

### Task 7: Delete old files

Only do this after Task 6 verification passes.

**Files:**
- Delete: All `claude/permissions.*.json`, `claude/permissions.*.jsonc`, `claude/settings.*.json`

- [ ] **Step 1: Remove old permission files**

```bash
git rm claude/permissions.json claude/permissions.personal.json claude/permissions.work.json
git rm claude/permissions.beans.json claude/permissions.colima.json claude/permissions.docker.json
git rm claude/permissions.git.jsonc claude/permissions.github.json claude/permissions.go.json
git rm claude/permissions.mcp.json claude/permissions.mise.json claude/permissions.node.json
git rm claude/permissions.python.json claude/permissions.ruby.json claude/permissions.rust.json
git rm claude/permissions.shell.json claude/permissions.skills.json claude/permissions.web.json
```

- [ ] **Step 2: Remove old settings files**

```bash
git rm claude/settings.base.json claude/settings.personal.json claude/settings.work.json
```

- [ ] **Step 3: Commit deletions**

```bash
git commit -m "chore: remove old permissions.*.json and settings.*.json files

These are replaced by claude/roles/ and claude/stacks/ directories."
```

---

### Task 8: Update README.md

**Files:**
- Modify: `claude/README.md`

- [ ] **Step 1: Read current README**

Read `claude/README.md` to understand structure and what to preserve.

- [ ] **Step 2: Rewrite README for new structure**

Update to cover:
- New `roles/` + `stacks/` architecture with tree diagram
- Schema: `permissions` + `sandbox` shape for both roles and stacks
- All files use JSONC, comments encouraged for provenance (`// source: agent-safehouse`)
- Merge order and precedence
- How to add a new stack (create `stacks/foo.jsonc` with permissions and/or sandbox)
- How to add a network host or filesystem write path (add to relevant stack)
- Local keys: `model`, `enabledPlugins`, `extraKnownMarketplaces` preserved from live settings
- Preserve useful sections: permission syntax table, promotion workflow, debugging commands (update paths)

- [ ] **Step 3: Commit README**

```bash
git add claude/README.md
git commit -m "docs: update claude/README.md for roles/stacks structure"
```

---

### Task 9: Fix spec and mark implemented

**Files:**
- Modify: `docs/plans/2026-03-25-claudeconfig-stacks-refactor.md`

- [ ] **Step 1: Update spec status to "Implemented"**

- [ ] **Step 2: Commit**

```bash
git add docs/plans/2026-03-25-claudeconfig-stacks-refactor.md
git commit -m "docs: mark claudeconfig stacks refactor spec as implemented"
```
