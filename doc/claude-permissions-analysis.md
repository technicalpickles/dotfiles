# Claude Permissions Analysis

Generated: 2026-01-24

## Executive Summary

This analysis reviews all Claude Code permissions across global and project-specific settings to identify opportunities for simplification and permission policy improvements.

### Key Findings

1. **27 candidate permissions** appearing 2+ times across projects that could be promoted to global
2. **6 deny rules** that could potentially be changed to ask for better UX
3. **Missing ecosystem files** for commonly-used tools (colima, sqlite, yamllint, bash, beans)
4. **Well-organized structure** with good separation of concerns

## Current Permission Structure

### Global Permission Files

| File | Purpose | Entries (allow/ask/deny) |
|------|---------|-------------------------|
| `permissions.json` | Base deny rules | 0 / 0 / 4 |
| `permissions.skills.json` | Cross-project skills | 27 / 0 / 0 |
| `permissions.shell.json` | Shell utilities | 41 / 2 / 0 |
| `permissions.git.jsonc` | Git operations | 31 / 0 / 4 |
| `permissions.github.json` | GitHub CLI | 25 / 0 / 0 |
| `permissions.node.json` | Node.js ecosystem | 30 / 0 / 0 |
| `permissions.ruby.json` | Ruby ecosystem | 45 / 0 / 0 |
| `permissions.python.json` | Python ecosystem | 38 / 0 / 0 |
| `permissions.go.json` | Go ecosystem | 27 / 0 / 0 |
| `permissions.rust.json` | Rust ecosystem | 26 / 0 / 0 |
| `permissions.docker.json` | Docker/containers | 24 / 0 / 0 |
| `permissions.mise.json` | mise version manager | 18 / 0 / 0 |
| `permissions.mcp.json` | MCP tools | 5 / 0 / 1 |
| `permissions.web.json` | WebFetch domains | 4 / 0 / 0 |
| `permissions.work.json` | Work-specific | 5 / 0 / 0 |
| `permissions.personal.json` | Personal-specific | 0 / 0 / 0 |

**Total: 346 allow, 2 ask, 9 deny**

## Recommendations

### 1. Promote Frequently-Used Project Permissions to Global

These permissions appear in 2+ projects and are good candidates for global inclusion:

#### High Priority (4+ occurrences)

```json
// Add to permissions.shell.json
"Bash(bash:*)",

// Already covered by permissions.github.json (gh pr create, etc.)
// but could add wildcard for simplicity:
"Bash(gh pr:*)"
```

#### Medium Priority (2-3 occurrences)

**Shell utilities** (add to `permissions.shell.json`):
```json
"Bash(pkill:*)",
"Bash(sqlite3:*)",
"Bash(yamllint:*)"
```

**Container management** (add to `permissions.docker.json` or new `permissions.colima.json`):
```json
"Bash(colima ssh:*)",
"Bash(colima start:*)",
"Bash(colima status:*)",
"Bash(colima stop:*)",
"Bash(colima:*)"
```

**Git operations** (already covered by `git remote:*` in git.jsonc):
```json
// No action needed - git remote set-url is covered by git remote:*
```

**Work-specific tools** (add to `permissions.work.json`):
```json
"Bash(npx bktide:*)",
"Bash(bin/schemaflow:*)"
```

**Documentation sites** (add to `permissions.web.json`):
```json
"WebFetch(domain:hk.jdx.dev)",
"WebFetch(domain:karafka.io)",
"WebFetch(domain:lima-vm.io)",
"WebFetch(domain:mise.jdx.dev)"
```

### 2. Create New Ecosystem Permission Files

#### `permissions.colima.json`
```json
{
  "allow": [
    "Bash(colima delete:*)",
    "Bash(colima kubernetes:*)",
    "Bash(colima list:*)",
    "Bash(colima ssh:*)",
    "Bash(colima ssh-config:*)",
    "Bash(colima start:*)",
    "Bash(colima status:*)",
    "Bash(colima stop:*)",
    "Bash(colima template:*)",
    "Bash(colima version:*)",
    "Bash(colima:*)"
  ],
  "deny": []
}
```

#### `permissions.beans.json`
```json
{
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
  ],
  "deny": []
}
```

### 3. Convert Deny to Ask for Selective Approval

Several currently-denied operations are sometimes necessary and could use `ask` instead:

#### Change in `permissions.json`

**Current:**
```json
{
  "deny": [
    "Bash(curl * | bash)",
    "Bash(curl * | sh)",
    "Bash(rm -rf:*)",
    "Bash(sudo:*)"
  ]
}
```

**Recommended:**
```json
{
  "ask": [
    "Bash(rm -rf /*)",        // Only ask for root-level rm -rf
    "Bash(sudo rm:*)",        // Ask for destructive sudo operations
    "Bash(sudo shutdown:*)",
    "Bash(sudo reboot:*)"
  ],
  "deny": [
    "Bash(curl * | bash)",    // Keep these as deny - very dangerous
    "Bash(curl * | sh)"
  ]
}
```

**Rationale:** `sudo` and `rm -rf` are sometimes needed for legitimate operations. Using `ask` provides a safety gate while maintaining flexibility. Keep pipe-to-shell as deny since it's rarely needed and highly dangerous.

#### Change in `permissions.git.jsonc`

**Current:**
```json
{
  "deny": [
    "Bash(git clean -fd:*)",
    "Bash(git push --force:*)",
    "Bash(git push -f:*)",
    "Bash(git reset --hard:*)"
  ]
}
```

**Recommended:**
```json
{
  "ask": [
    "Bash(git clean -fd:*)",      // Sometimes needed to clean build artifacts
    "Bash(git push --force:*)",   // Needed after rebases (ask prevents accidents)
    "Bash(git push -f:*)",
    "Bash(git reset --hard:*)"    // Useful for abandoning local changes
  ],
  "deny": [
    "Bash(git push --force origin main:*)",  // Protect main branch
    "Bash(git push --force origin master:*)", // Protect master branch
    "Bash(git push -f origin main:*)",
    "Bash(git push -f origin master:*)"
  ]
}
```

**Rationale:** These operations are part of normal git workflows (especially with rebase-based workflows), but benefit from confirmation prompts. Specifically deny force-push to main/master branches.

#### Change in `permissions.mcp.json`

**Current:**
```json
{
  "deny": ["mcp__MCPProxy__call_tool_destructive"]
}
```

**Consider:**
```json
{
  "ask": ["mcp__MCPProxy__call_tool_destructive"]
}
```

**Rationale:** If a destructive MCP tool is needed, user can approve it. Complete denial may be too restrictive.

### 4. Consolidate Wildcards

Some permission files could be simplified by using broader wildcards where appropriate:

#### `permissions.github.json` - Simplification Opportunity

**Current:** 25 specific `gh` commands

**Alternative (more permissive):**
```json
{
  "allow": [
    "Bash(gh:*)"  // Trust all gh CLI operations
  ],
  "ask": [
    "Bash(gh repo delete:*)",      // Destructive operations still ask
    "Bash(gh secret delete:*)"
  ],
  "deny": []
}
```

**Recommendation:** Keep current granular approach - it provides better visibility and control.

### 5. Add Missing Common Tools

Add to `permissions.shell.json`:
```json
"Bash(awk:*)",
"Bash(base64:*)",
"Bash(basename:*)",
"Bash(cut:*)",
"Bash(date:*)",
"Bash(expr:*)",
"Bash(gzip:*)",
"Bash(hostname:*)",
"Bash(id:*)",
"Bash(nc:*)",
"Bash(openssl:*)",
"Bash(printenv:*)",
"Bash(ps:*)",
"Bash(rsync:*)",
"Bash(seq:*)",
"Bash(sha256sum:*)",
"Bash(shasum:*)",
"Bash(sleep:*)",
"Bash(split:*)",
"Bash(ssh:*)",
"Bash(time:*)",
"Bash(timeout:*)",
"Bash(uname:*)",
"Bash(watch:*)",
"Bash(whoami:*)",
"Bash(xz:*)",
"Bash(yes:*)",
"Bash(zip:*)"
```

## Implementation Plan

### Phase 1: High-Value, Low-Risk Changes

1. **Create new ecosystem files:**
   - `permissions.colima.json`
   - `permissions.beans.json`

2. **Add high-frequency tools to existing files:**
   - Add `bash:*` to `permissions.shell.json`
   - Add common shell utilities to `permissions.shell.json`
   - Add documentation domains to `permissions.web.json`

3. **Regenerate and test:**
   ```bash
   ./claudeconfig.sh
   claude-permissions --aggregate
   ```

### Phase 2: Policy Changes (Requires More Consideration)

4. **Convert selective deny → ask:**
   - Git operations in `permissions.git.jsonc`
   - Selective sudo operations in `permissions.json`
   - MCP destructive operations in `permissions.mcp.json`

5. **Test in real-world usage** before committing

### Phase 3: Cleanup

6. **Remove project-specific duplicates:**
   ```bash
   claude-permissions cleanup --force
   ```

7. **Commit changes to dotfiles**

## Project-Specific Permission Patterns

### High-Use One-Off Patterns

These appear in 1-2 projects but follow patterns that might indicate missing global coverage:

- **Custom scripts:** `./bin/`, `./.buildkite/`, `./.scratch/`
  - Action: None needed - these are project-specific

- **Tool debugging:** `./target/debug/mise`, `./soju`, `./sojuctl`
  - Action: None needed - these are development-time one-offs

- **Ruby test tools:** Already well-covered in `permissions.ruby.json`

## Anti-Patterns to Avoid

1. **Don't add wildcards for security-sensitive operations**
   - Keep specific git commands rather than `git:*`
   - Keep specific gh commands rather than `gh:*`

2. **Don't promote one-off project scripts to global**
   - `./bin/schemaflow` is project-specific
   - `./bin/build` varies by project

3. **Don't remove the base deny rules**
   - `curl | bash` should always be denied
   - Core safety rules protect against copy-paste attacks

## Questions for Review

1. **bash:* permission:** Should `bash` with arbitrary scripts be globally allowed? Or should it remain project-specific?
   - Recommend: ADD - bash is commonly needed for running scripts

2. **gh pr:* wildcard:** Is the wildcard redundant given specific gh pr commands?
   - Recommend: NO - keep specific commands for better visibility

3. **colima ecosystem:** Should this be merged into docker.json or separate?
   - Recommend: SEPARATE - Colima is an alternative to Docker Desktop

4. **MCP destructive operations:** Should these use ask or stay deny?
   - Recommend: CHANGE TO ASK - allows approval when truly needed

5. **Work-specific tools:** Should bktide, schemaflow be in global work.json?
   - Recommend: ADD bktide to work.json (3x usage), keep schemaflow project-specific (appears as different paths)

## Summary of Changes

### Files to Create
- [ ] `claude/permissions.colima.json`
- [ ] `claude/permissions.beans.json`

### Files to Modify
- [ ] `claude/permissions.json` - Convert some deny → ask
- [ ] `claude/permissions.shell.json` - Add common utilities
- [ ] `claude/permissions.git.jsonc` - Convert deny → ask + protect main
- [ ] `claude/permissions.mcp.json` - Convert deny → ask
- [ ] `claude/permissions.web.json` - Add documentation domains
- [ ] `claude/permissions.work.json` - Add bktide

### Estimated Impact
- **Before:** 346 allow, 2 ask, 9 deny
- **After:** ~390 allow, ~10 ask, 2 deny
- **Net effect:** More permissive with appropriate safety gates

### Risk Assessment
- **Low risk:** New ecosystem files, additional shell utilities
- **Medium risk:** Converting deny → ask (requires testing)
- **No risk:** Adding documentation domains to web.json
