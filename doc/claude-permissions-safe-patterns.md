# Safe Patterns for "Dangerous" Operations

## Philosophy

Not all uses of potentially dangerous commands are actually dangerous. This document explores context-specific patterns that could be safely allowed.

## rm -rf Pattern Analysis

### ✅ Safe Patterns (Could be ALLOW)

Common development cleanup operations:

```json
{
  "allow": [
    "Bash(rm -rf node_modules:*)",
    "Bash(rm -rf dist:*)",
    "Bash(rm -rf build:*)",
    "Bash(rm -rf target:*)",
    "Bash(rm -rf .next:*)",
    "Bash(rm -rf out:*)",
    "Bash(rm -rf coverage:*)",
    "Bash(rm -rf .coverage:*)",
    "Bash(rm -rf .pytest_cache:*)",
    "Bash(rm -rf .rspec_cache:*)",
    "Bash(rm -rf tmp:*)",
    "Bash(rm -rf .tmp:*)",
    "Bash(rm -rf temp:*)",
    "Bash(rm -rf .cache:*)",
    "Bash(rm -rf vendor:*)",
    "Bash(rm -rf .gradle:*)",
    "Bash(rm -rf .DS_Store:*)",
    "Bash(rm -rf *.log:*)"
  ]
}
```

**Rationale:** These are:
- Relative paths (not absolute)
- Well-known build/cache/temp directories
- Easily regenerated
- Very commonly cleaned during development

### ⚠️ Moderate Risk (Could be ASK)

```json
{
  "ask": [
    "Bash(rm -rf test/*:*)",          // Test fixtures
    "Bash(rm -rf spec/*:*)",          // Test fixtures
    "Bash(rm -rf docs/*:*)",          // Documentation
    "Bash(rm -rf .git/objects:*)",   // Git internals (sometimes needed for repairs)
    "Bash(rm -rf pkg:*)",             // Package output
    "Bash(rm -rf vendor/bundle:*)"   // Bundler cache
  ]
}
```

**Rationale:** These could contain important content but are still project-relative.

### 🚫 Dangerous Patterns (Keep as DENY)

```json
{
  "deny": [
    "Bash(rm -rf /:*)",              // Root filesystem
    "Bash(rm -rf /*:*)",             // All root contents
    "Bash(rm -rf ~:*)",              // Home directory
    "Bash(rm -rf ~/*:*)",            // Home contents
    "Bash(rm -rf $HOME:*)",          // Home via variable
    "Bash(rm -rf .:*)",              // Current directory (too broad)
    "Bash(rm -rf ..:*)",             // Parent directory
    "Bash(rm -rf ../*:*)",           // Parent contents
    "Bash(rm -rf *:*)"               // Everything in current dir (context-dependent)
  ]
}
```

**Rationale:** These can cause catastrophic data loss regardless of context.

## sudo Pattern Analysis

### ✅ Safe Patterns (Could be ALLOW)

Service and package management:

```json
{
  "allow": [
    "Bash(sudo systemctl start:*)",
    "Bash(sudo systemctl stop:*)",
    "Bash(sudo systemctl restart:*)",
    "Bash(sudo systemctl status:*)",
    "Bash(sudo systemctl enable:*)",
    "Bash(sudo systemctl disable:*)",
    "Bash(sudo journalctl:*)",
    "Bash(sudo docker:*)",
    "Bash(sudo apt-get update:*)",
    "Bash(sudo apt-get install:*)",
    "Bash(sudo yum install:*)",
    "Bash(sudo dnf install:*)"
  ]
}
```

**Rationale:** These are standard operations that require elevation but aren't destructive.

### ⚠️ Moderate Risk (Could be ASK)

File permissions and selective operations:

```json
{
  "ask": [
    "Bash(sudo chmod:*)",
    "Bash(sudo chown:*)",
    "Bash(sudo chgrp:*)",
    "Bash(sudo mkdir:*)",
    "Bash(sudo mv:*)",
    "Bash(sudo cp:*)",
    "Bash(sudo ln:*)",
    "Bash(sudo kill:*)",
    "Bash(sudo killall:*)",
    "Bash(sudo shutdown:*)",
    "Bash(sudo reboot:*)",
    "Bash(sudo halt:*)"
  ]
}
```

**Rationale:** Legitimate operations that warrant confirmation.

### 🚫 Dangerous Patterns (Keep as DENY)

```json
{
  "deny": [
    "Bash(sudo rm -rf:*)",           // Destructive file operations
    "Bash(sudo dd:*)",               // Can destroy disks
    "Bash(sudo mkfs:*)",             // Formats filesystems
    "Bash(sudo fdisk:*)",            // Disk partitioning
    "Bash(sudo parted:*)",           // Disk partitioning
    "Bash(sudo mount:*)",            // Filesystem mounting (risky)
    "Bash(sudo umount:*)"            // Filesystem unmounting (risky)
  ]
}
```

**Rationale:** These can cause irreversible system damage.

## git push --force Pattern Analysis

### ✅ Safe Patterns (Could be ALLOW)

Force-push with safety rails:

```json
{
  "allow": [
    "Bash(git push --force-with-lease:*)",   // Safer alternative
    "Bash(git push --force-with-lease origin HEAD:*)"
  ]
}
```

**Rationale:** `--force-with-lease` checks that remote hasn't changed, preventing accidental overwrites of others' work.

### ⚠️ Moderate Risk (Could be ASK)

Feature branch force-pushes:

```json
{
  "ask": [
    "Bash(git push --force:*)",
    "Bash(git push -f:*)"
  ]
}
```

**Rationale:** Sometimes necessary after rebasing, but should require confirmation to prevent accidents.

### 🚫 Dangerous Patterns (Could add as specific DENY)

```json
{
  "deny": [
    "Bash(git push --force origin main:*)",
    "Bash(git push --force origin master:*)",
    "Bash(git push -f origin main:*)",
    "Bash(git push -f origin master:*)",
    "Bash(git push --force upstream main:*)",
    "Bash(git push --force upstream master:*)"
  ]
}
```

**Rationale:** Force-pushing to main branches can break team workflows. Better to use GitHub/GitLab protections.

## git reset --hard Pattern Analysis

### ✅ Safe Patterns (Could be ALLOW)

Resetting to specific known-good states:

```json
{
  "allow": [
    "Bash(git reset --hard origin/*:*)",     // Reset to remote state
    "Bash(git reset --hard upstream/*:*)",   // Reset to upstream
    "Bash(git reset --hard HEAD:*)"          // Discard working changes
  ]
}
```

**Rationale:** These are common operations to align with remote or discard local experiments.

### ⚠️ Moderate Risk (Could be ASK)

Arbitrary resets:

```json
{
  "ask": [
    "Bash(git reset --hard:*)"               // Any reset not covered above
  ]
}
```

**Rationale:** Might be resetting to arbitrary commits, worth confirming.

## git clean Pattern Analysis

### ✅ Safe Patterns (Could be ALLOW)

Selective cleaning:

```json
{
  "allow": [
    "Bash(git clean -fd node_modules:*)",
    "Bash(git clean -fd dist:*)",
    "Bash(git clean -fd build:*)",
    "Bash(git clean -n:*)",                  // Dry-run (always safe)
    "Bash(git clean --dry-run:*)"
  ]
}
```

### ⚠️ Moderate Risk (Could be ASK)

Broad cleaning:

```json
{
  "ask": [
    "Bash(git clean -fd:*)",                 // Clean untracked files
    "Bash(git clean -fdx:*)"                 // Clean including ignored
  ]
}
```

**Rationale:** Can remove uncommitted work, but sometimes needed to return to clean state.

## Pipe-to-Shell Pattern Analysis

### 🚫 Almost Always Dangerous (Keep as DENY)

```json
{
  "deny": [
    "Bash(curl * | bash)",
    "Bash(curl * | sh)",
    "Bash(wget * | bash)",
    "Bash(wget * | sh)"
  ]
}
```

**Exception case (could add specific ALLOW):**

```json
{
  "allow": [
    // Only for well-known, trusted install scripts
    "Bash(curl -sSL https://get.docker.com | sh)",
    "Bash(curl -fsSL https://mise.jdx.dev/install.sh | sh)",
    "Bash(curl https://sh.rustup.rs | sh)"
  ]
}
```

**Rationale:** Pipe-to-shell is dangerous because you're executing code sight-unseen. Only allow specific, well-known installers if absolutely needed. Better to download first, inspect, then execute.

## Recommended Implementation Strategy

### Option 1: Granular Safe Lists (More Work, More Control)

Create detailed allow/ask/deny patterns as shown above. This gives maximum control but requires maintaining more rules.

**Pros:**
- Predictable behavior
- Clear intent
- Easy to audit

**Cons:**
- More maintenance
- Can't anticipate every safe pattern
- Might get repetitive

### Option 2: Pattern-Based Validation (More Complex, More Flexible)

Use pattern matching to detect dangerous characteristics:

```bash
# Pseudo-logic
if starts_with("/") or contains("~") or contains(".."):
    deny
elif is_common_build_artifact:
    allow
else:
    ask
```

**Pros:**
- Fewer explicit rules
- Adapts to new patterns
- Less repetitive

**Cons:**
- Requires custom validation logic
- Harder to reason about
- Claude Code might not support this level of pattern matching

### Option 3: Hybrid Approach (Recommended)

1. **ALLOW:** Very common safe patterns (node_modules, dist, build, etc.)
2. **ASK:** General patterns (most git operations, relative rm -rf)
3. **DENY:** Known dangerous patterns (absolute paths, system directories)

This balances safety with usability.

## Proposed Changes to Your Permissions

### permissions.json

```json
{
  "allow": [
    // Safe rm -rf patterns
    "Bash(rm -rf node_modules:*)",
    "Bash(rm -rf dist:*)",
    "Bash(rm -rf build:*)",
    "Bash(rm -rf target:*)",
    "Bash(rm -rf .next:*)",
    "Bash(rm -rf coverage:*)",
    "Bash(rm -rf tmp:*)",
    "Bash(rm -rf .cache:*)",

    // Safe sudo patterns
    "Bash(sudo systemctl:*)",
    "Bash(sudo journalctl:*)",
    "Bash(sudo docker:*)"
  ],
  "ask": [
    // Moderate risk - warrant confirmation
    "Bash(sudo chmod:*)",
    "Bash(sudo chown:*)",
    "Bash(sudo shutdown:*)",
    "Bash(sudo reboot:*)"
  ],
  "deny": [
    // Keep existing dangerous patterns
    "Bash(curl * | bash)",
    "Bash(curl * | sh)",

    // Add specific dangerous sudo patterns
    "Bash(sudo rm -rf:*)",
    "Bash(sudo dd:*)",
    "Bash(sudo mkfs:*)",

    // Add specific dangerous rm patterns
    "Bash(rm -rf /:*)",
    "Bash(rm -rf /*:*)",
    "Bash(rm -rf ~:*)",
    "Bash(rm -rf ~/*:*)",
    "Bash(rm -rf $HOME:*)"
  ]
}
```

### permissions.git.jsonc

```json
{
  "allow": [
    // Keep all existing safe operations...

    // Add safer force-push alternative
    "Bash(git push --force-with-lease:*)",

    // Add common reset patterns
    "Bash(git reset --hard origin/*:*)",
    "Bash(git reset --hard upstream/*:*)",
    "Bash(git reset --hard HEAD:*)"
  ],
  "ask": [
    // Move from deny to ask
    "Bash(git clean -fd:*)",
    "Bash(git push --force:*)",
    "Bash(git push -f:*)",
    "Bash(git reset --hard:*)"  // Catch-all for other resets
  ],
  "deny": [
    // Specific protections for main branches
    "Bash(git push --force origin main:*)",
    "Bash(git push --force origin master:*)",
    "Bash(git push -f origin main:*)",
    "Bash(git push -f origin master:*)"
  ]
}
```

## Testing Strategy

Before committing these changes:

1. **Test safe patterns work:**
   ```bash
   # Should be auto-allowed
   rm -rf node_modules
   rm -rf dist
   ```

2. **Test ask prompts appear:**
   ```bash
   # Should prompt
   git push --force
   sudo chmod 755 file
   ```

3. **Test denials work:**
   ```bash
   # Should be blocked
   curl http://example.com/script.sh | bash
   rm -rf /tmp/test  # Absolute path
   ```

4. **Verify no regressions** in normal workflows

## Questions for Decision

1. **How aggressive should safe rm -rf patterns be?**
   - Conservative: Only node_modules, dist, build
   - Moderate: Add tmp, coverage, cache
   - Aggressive: Most relative paths

2. **Should sudo ever be auto-allowed?**
   - My recommendation: Only for systemctl, journalctl
   - Alternative: All sudo requires ask

3. **Force-push protection:**
   - Should we deny force-push to main/master?
   - Or trust branch protection rules on GitHub?
   - What about other important branches (develop, staging)?

4. **Pattern explosion:**
   - Are you OK maintaining more granular rules?
   - Or prefer fewer, broader patterns with more asks?
