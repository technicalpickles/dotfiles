# Permission Wildcard Safety Analysis

## The Problem with Trailing Wildcards

### Current Pattern (Potentially Dangerous)

```json
"Bash(rm -rf node_modules:*)"
```

This matches:
- ✅ `rm -rf node_modules` - Safe
- ✅ `rm -rf node_modules/` - Safe
- ⚠️ `rm -rf node_modules --verbose` - Probably safe
- 🚫 `rm -rf node_modules ../important-dir` - **DANGEROUS!**
- 🚫 `rm -rf node_modules /tmp/secrets` - **DANGEROUS!**

The `:*` wildcard means "with any additional arguments", which could include additional paths to delete!

### How Permission Matching Works

Claude Code permission format:
```
Bash(command args:wildcard)
```

- `command` - The actual command (rm, git, etc.)
- `args` - Specific arguments to match
- `:*` - Wildcard for additional arguments

Examples:
- `Bash(git status:*)` - Matches `git status` with any extra args
- `Bash(npm install:*)` - Matches `npm install` plus anything after
- `Bash(rm -rf node_modules:*)` - Matches `rm -rf node_modules` plus anything after (DANGER!)

## Safer Alternatives

### Option 1: Exact Match (Most Restrictive)

```json
{
  "allow": [
    "Bash(rm -rf node_modules)",
    "Bash(rm -rf dist)",
    "Bash(rm -rf build)"
  ]
}
```

**Pros:**
- Maximum safety - only exact command is allowed
- No risk of additional paths being deleted

**Cons:**
- Doesn't support useful flags like `-v` (verbose)
- Might not match if shell expands paths (e.g., `rm -rf ./node_modules`)

### Option 2: Specific Safe Variations

```json
{
  "allow": [
    "Bash(rm -rf node_modules)",
    "Bash(rm -rf ./node_modules)",
    "Bash(rm -rf node_modules/)",
    "Bash(rm -rf ./node_modules/)",
    "Bash(rm -rf dist)",
    "Bash(rm -rf ./dist)",
    "Bash(rm -rf build)",
    "Bash(rm -rf ./build)"
  ]
}
```

**Pros:**
- Covers common path variations
- Still very safe - no extra arguments

**Cons:**
- More verbose
- Still doesn't support flags

### Option 3: Pattern-Based Validation (Ideal but Complex)

What we'd ideally want:
```
Allow "rm -rf X" where X matches safe patterns and no additional args
```

This would require custom logic that Claude Code may not support.

### Option 4: Keep Wildcards but Add Dangerous Patterns to Deny

```json
{
  "allow": [
    "Bash(rm -rf node_modules:*)",
    "Bash(rm -rf dist:*)"
  ],
  "deny": [
    "Bash(rm -rf node_modules /:*)",
    "Bash(rm -rf node_modules ~:*)",
    "Bash(rm -rf node_modules ..:*)",
    "Bash(rm -rf node_modules /*:*)",
    "Bash(rm -rf dist /:*)",
    "Bash(rm -rf dist ~:*)"
    // ... would need to enumerate many dangerous combinations
  ]
}
```

**Pros:**
- Allows flags and variations

**Cons:**
- Deny rules may not work as expected (allow might take precedence)
- Hard to enumerate all dangerous patterns
- Still leaves gaps

## Real-World Risk Assessment

### How likely is exploitation?

**Accidental:**
- Low risk - Claude is unlikely to accidentally add dangerous extra paths
- Most commands are generated as single targets

**Malicious:**
- Could a malicious prompt trick Claude into `rm -rf node_modules /important`?
- Possible, but would require specific prompt injection
- Multiple layers of defense (Claude's safety training, permission prompts)

### Comparison with Other Permissions

**Current wildcards that are probably fine:**
```json
"Bash(npm install:*)"  // Extra args are package names - safe
"Bash(git status:*)"   // Extra args are paths/flags - safe
"Bash(jq:*)"          // Extra args are filters/files - safe
```

**Current wildcards that are concerning:**
```json
"Bash(rm -rf node_modules:*)"  // Extra args could be more paths
"Bash(rm -rf dist:*)"          // Same issue
"Bash(sudo systemctl:*)"       // Extra args... probably ok?
```

## Recommendations

### Conservative Approach (Recommended)

Remove the trailing `:*` from rm commands:

```json
{
  "allow": [
    "Bash(rm -rf node_modules)",
    "Bash(rm -rf ./node_modules)",
    "Bash(rm -rf dist)",
    "Bash(rm -rf ./dist)",
    "Bash(rm -rf build)",
    "Bash(rm -rf ./build)",
    "Bash(rm -rf target)",
    "Bash(rm -rf ./target)",
    "Bash(rm -rf coverage)",
    "Bash(rm -rf ./coverage)",
    "Bash(rm -rf tmp)",
    "Bash(rm -rf ./tmp)",
    "Bash(rm -rf temp)",
    "Bash(rm -rf ./temp)",
    "Bash(rm -rf .cache)",
    "Bash(rm -rf .next)",
    "Bash(rm -rf out)",
    "Bash(rm -rf .pytest_cache)",
    "Bash(rm -rf .rspec_cache)",
    "Bash(rm -rf .DS_Store)",
    "Bash(rm -rf .tmp)",
    "Bash(rm -rf .coverage)",
    "Bash(rm -rf .gradle)",
    "Bash(rm -rf vendor)",
    "Bash(rm -rf pkg)"
  ]
}
```

**Rationale:**
- `rm` commands rarely need additional arguments beyond the path
- The safety benefit outweighs the minor inconvenience
- If you need verbose output, you can approve it when prompted

### Moderate Approach

Keep wildcards for commands where extra args are clearly safe:

```json
{
  "allow": [
    // rm commands - no wildcards
    "Bash(rm -rf node_modules)",
    "Bash(rm -rf dist)",

    // Other commands - wildcards ok
    "Bash(npm install:*)",    // Extra args are packages
    "Bash(git status:*)",     // Extra args are paths
    "Bash(sudo systemctl:*)"  // Extra args are services
  ]
}
```

### What About sudo Commands?

Current patterns:
```json
"Bash(sudo systemctl start:*)",
"Bash(sudo systemctl stop:*)",
"Bash(sudo docker:*)"
```

**Analysis:**
- `sudo systemctl start:*` - Extra args are service names (safe)
- `sudo docker:*` - Extra args are docker commands (safe)
- These wildcards are probably fine

## Testing the Risk

You can test whether wildcards allow multiple paths:

```bash
# If you have the current permissions:
# Does this get allowed or blocked?
rm -rf node_modules /tmp/test-danger
```

If it's **allowed**, the wildcards are dangerous.
If it's **blocked**, maybe Claude Code has additional parsing that prevents this.

## Implementation Plan

1. **Test current behavior** to understand how wildcards work
2. **If dangerous:** Update `permissions.json` to remove `:*` from rm commands
3. **Regenerate:** Run `./claudeconfig.sh`
4. **Validate:** Try common operations still work
5. **Monitor:** Watch for legitimate operations being blocked

## Specific Changes Needed

### File: `claude/permissions.json`

**Current (potentially unsafe):**
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
    "Bash(rm -rf pkg:*)",
    "Bash(rm -rf .gradle:*)",
    "Bash(rm -rf .DS_Store:*)"
  ]
}
```

**Proposed (safer):**
```json
{
  "allow": [
    "Bash(rm -rf node_modules)",
    "Bash(rm -rf ./node_modules)",
    "Bash(rm -rf dist)",
    "Bash(rm -rf ./dist)",
    "Bash(rm -rf build)",
    "Bash(rm -rf ./build)",
    "Bash(rm -rf target)",
    "Bash(rm -rf ./target)",
    "Bash(rm -rf .next)",
    "Bash(rm -rf ./. next)",
    "Bash(rm -rf out)",
    "Bash(rm -rf ./out)",
    "Bash(rm -rf coverage)",
    "Bash(rm -rf ./coverage)",
    "Bash(rm -rf .coverage)",
    "Bash(rm -rf .pytest_cache)",
    "Bash(rm -rf .rspec_cache)",
    "Bash(rm -rf tmp)",
    "Bash(rm -rf ./tmp)",
    "Bash(rm -rf .tmp)",
    "Bash(rm -rf temp)",
    "Bash(rm -rf ./temp)",
    "Bash(rm -rf .cache)",
    "Bash(rm -rf vendor)",
    "Bash(rm -rf ./vendor)",
    "Bash(rm -rf pkg)",
    "Bash(rm -rf ./pkg)",
    "Bash(rm -rf .gradle)",
    "Bash(rm -rf .DS_Store)"
  ]
}
```

Note: Doubled entries for with/without `./` prefix to handle different shell behaviors.

## Conclusion

**The trailing wildcards on rm -rf commands are a potential security risk.** While the practical risk is low (Claude is unlikely to generate malicious commands), the defense-in-depth principle suggests removing them.

**Recommendation:** Remove `:*` from all `rm -rf` permissions and instead enumerate the common path variations (`./node_modules` vs `node_modules`).
