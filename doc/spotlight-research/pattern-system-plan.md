# Spotlight Exclusion Pattern System - Implementation Plan

## Overview

Build a system to specify Spotlight exclusions using gitignore-style patterns that expand to actual directories on disk.

## Goals

1. Provide a simple, familiar syntax for specifying exclusion patterns
2. Efficiently expand patterns to concrete directory paths
3. Support both literal paths and glob patterns
4. Provide safety through dry-run and validation
5. Integrate with existing `bin/spotlight-add-exclusion` tool

## Components

### 1. Pattern File Format

**Location**: `~/.config/spotlight-exclusions`

**Syntax**:

```gitignore
# Comments start with #
# Blank lines ignored

# Literal paths (with tilde expansion)
~/.cache
~/.npm/_cacache

# Absolute paths
/Users/josh/Library/Caches

# Recursive patterns (globstar)
~/workspace/**/node_modules
~/workspace/**/.venv

# Single-level glob
~/workspace/*/dist
```

**Rules**:

- `~` expands to `$HOME`
- `**/pattern` matches pattern at any depth within base path
- `*/pattern` matches pattern in immediate children only
- Pattern without glob must be an existing directory
- Only directories are matched (files ignored)
- Symlinks are not followed

### 2. Pattern Expander

**Script**: `bin/spotlight-expand-patterns`

**Purpose**: Takes pattern file, outputs list of absolute directory paths

**Algorithm**:

```
1. Read pattern file line by line
2. For each line:
   - Skip if blank or starts with #
   - Expand ~ to $HOME
   - Determine pattern type:

   a) No globs (* or **):
      - Verify directory exists
      - Output absolute path

   b) Contains **/:
      - Split into: BASE_PATH and PATTERN
      - Validate BASE_PATH exists
      - Run: find BASE_PATH -type d -name PATTERN
      - Output matching paths

   c) Contains single *:
      - Use find with -maxdepth or shell glob
      - Output matching directories only

3. Deduplicate results
4. Sort for consistent output
```

**Options**:

- `--max-depth N`: Limit recursion depth (default: 10)
- `--verbose`: Show expansion process
- `--validate`: Check all base paths exist before searching
- `--parallel`: Search multiple base paths concurrently (future)

**Output Format**:

```
/Users/josh.nichols/.cache
/Users/josh.nichols/.npm/_cacache
/Users/josh.nichols/workspace/dotfiles/node_modules
/Users/josh.nichols/workspace/envsense/node_modules
/Users/josh.nichols/workspace/myapp/node_modules
```

**Error Handling**:

- Base path doesn't exist → warning to stderr, skip pattern
- Permission denied → warning to stderr, skip directory
- Invalid pattern syntax → error and exit
- No results for pattern → info to stderr, continue

### 3. Pattern Applier

**Script**: `bin/spotlight-apply-exclusions`

**Purpose**: Expand patterns and apply exclusions via `spotlight-add-exclusion`

**Usage**:

```bash
bin/spotlight-apply-exclusions [OPTIONS] PATTERN_FILE
```

**Options**:

- `--dry-run, -n`: Show what would be excluded without applying
- `--verbose, -v`: Show detailed progress
- `--max-depth N`: Limit recursion depth for globstar patterns
- `--validate`: Validate patterns before applying

**Workflow**:

```
1. Validate pattern file exists and is readable
2. Call spotlight-expand-patterns with same options
3. Collect expanded paths
4. Show summary:
   - Number of patterns processed
   - Number of directories found
   - Total size (if --verbose)
5. If --dry-run:
   - Print paths that would be excluded
   - Exit
6. For each path:
   - Call bin/spotlight-add-exclusion
   - Handle errors gracefully
   - Show progress
7. Show final summary
```

**Output Format (normal)**:

```
Expanding patterns from ~/.config/spotlight-exclusions...
Found 47 directories matching patterns
Applying exclusions...
  [1/47] /Users/josh/.cache
  [2/47] /Users/josh/.npm/_cacache
  ...
  [47/47] /Users/josh/workspace/project/target

Successfully excluded 47 directories
```

**Output Format (dry-run)**:

```
Would exclude 47 directories:

From pattern: ~/.cache
  /Users/josh/.cache

From pattern: ~/workspace/**/node_modules
  /Users/josh/workspace/dotfiles/node_modules
  /Users/josh/workspace/envsense/node_modules
  /Users/josh/workspace/myapp/node_modules

From pattern: ~/workspace/**/.venv
  /Users/josh/workspace/project1/.venv
  /Users/josh/workspace/project2/.venv

Total: 47 directories
```

### 4. Default Pattern File

**File**: `config/spotlight-exclusions` (in dotfiles repo)

**Symlinked to**: `~/.config/spotlight-exclusions` (via install.sh)

**Contents**: Curated list of common exclusion patterns

```gitignore
# Spotlight Exclusion Patterns
# See: doc/spotlight-exclusions.md

# User-level caches
~/.cache
~/.npm/_cacache
~/.yarn/cache
~/.pnpm-store

# Development tool installations
~/.mise/installs

# Workspace dependencies (adjust base path as needed)
~/workspace/**/node_modules
~/workspace/**/.venv
~/workspace/**/venv
~/workspace/**/target
~/workspace/**/vendor

# Build artifacts
~/workspace/**/build
~/workspace/**/dist
~/workspace/**/.next
~/workspace/**/.nuxt
~/workspace/**/.turbo

# Caches and temp
~/workspace/**/tmp
~/workspace/**/.cache
~/workspace/**/__pycache__
~/workspace/**/.pytest_cache
~/workspace/**/.mypy_cache
~/workspace/**/.ruff_cache

# Coverage reports
~/workspace/**/coverage
~/workspace/**/.nyc_output

# System caches (macOS)
~/Library/Caches
```

### 5. Documentation Updates

**File**: `doc/spotlight-exclusions.md`

**New Sections**:

- Pattern-based exclusion system overview
- Pattern syntax reference
- Examples of common patterns
- How to customize for your workspace
- Troubleshooting pattern expansion

**File**: `README.md` or `CLAUDE.md`

**Updates**:

- Mention pattern-based exclusion system
- Link to documentation
- Note that `config/spotlight-exclusions` is symlinked

### 6. Integration with Install Script

**File**: `install.sh`

**Add step** (after symlinks are created):

```bash
if running_macos; then
  if [ -f "$HOME/.config/spotlight-exclusions" ]; then
    echo "Spotlight exclusions pattern file installed at ~/.config/spotlight-exclusions"
    echo "To apply exclusions, run: bin/spotlight-apply-exclusions ~/.config/spotlight-exclusions"
    echo "To preview first, run: bin/spotlight-apply-exclusions --dry-run ~/.config/spotlight-exclusions"
  fi
fi
```

## Implementation Steps

### Phase 1: Core Functionality

1. ✅ Create `bin/spotlight-expand-patterns` script

   - Start with basic literal path support
   - Add tilde expansion
   - Add simple glob support (\*)
   - Add globstar support (\*\*)
   - Add error handling and validation

2. ✅ Create `bin/spotlight-apply-exclusions` script

   - Integrate with `spotlight-expand-patterns`
   - Implement dry-run mode
   - Add progress reporting
   - Integrate with `bin/spotlight-add-exclusion`

3. ✅ Create default pattern file
   - Research common patterns
   - Create `config/spotlight-exclusions`
   - Document each pattern category

### Phase 2: Testing & Refinement

4. ✅ Test with various pattern types

   - Test literal paths
   - Test single-level globs
   - Test globstar patterns
   - Test non-existent paths
   - Test permission errors
   - Test with large numbers of matches

5. ✅ Performance optimization
   - Profile with real workspace
   - Add parallelization if needed
   - Consider caching strategy

### Phase 3: Integration & Documentation

6. ✅ Update documentation

   - Update `doc/spotlight-exclusions.md`
   - Add examples and troubleshooting
   - Document pattern syntax

7. ✅ Update install script

   - Add symlink for pattern file
   - Add informational message
   - Test fresh installation

8. ✅ Create ADR
   - Document design decisions
   - Explain pattern syntax choices
   - Note alternatives considered

### Phase 4: Polish

9. ✅ Add advanced features (optional)

   - Batch operations for performance
   - Configuration file for max-depth, base paths
   - State tracking (what was excluded by patterns)
   - Removal tool for pattern-based exclusions

10. ✅ User testing
    - Test on fresh macOS environment
    - Gather feedback on patterns
    - Refine default exclusions

## Design Decisions

### Pattern Syntax

- **Decision**: Use gitignore-style syntax with extensions for absolute paths
- **Rationale**: Familiar to developers, expressive, human-readable
- **Alternative**: Custom DSL, JSON/YAML config
- **Trade-offs**: Less structured than config format, but more intuitive

### Globstar Requirement for Base Path

- **Decision**: Require base path before `**/` (no bare `**/node_modules`)
- **Rationale**: Prevents expensive filesystem-wide searches
- **Alternative**: Allow with warning, limit to specific roots
- **Trade-offs**: Less flexible, but much safer and faster

### Shell Implementation

- **Decision**: Start with Bash/shell script using `find`
- **Rationale**: Easy to prototype, works everywhere, leverages existing tools
- **Alternative**: Rust/Go for performance, Python for clarity
- **Trade-offs**: May be slower, but simpler to maintain

### Single Pattern File

- **Decision**: One flat file with comments for organization
- **Rationale**: Simple, easy to edit, no hierarchy to learn
- **Alternative**: Multiple files, sections in config format
- **Trade-offs**: Can get large, but easier to understand

### Dry-run by Default

- **Decision**: Require explicit apply, not dry-run flag
- **Rationale**: Safer, prevents accidental mass exclusions
- **Alternative**: Apply by default, require --dry-run
- **Trade-offs**: More verbose, but more cautious
- **Resolution**: Use `--dry-run` flag as originally planned for flexibility

## Future Enhancements

1. **State Management**: Track which exclusions came from patterns vs manual
2. **Removal Tool**: Remove exclusions based on pattern file changes
3. **Multiple Pattern Files**: Support per-workspace exclusion files
4. **Include/Exclude Logic**: Allow exceptions like `!node_modules/important`
5. **Size Estimation**: Show disk space that will be excluded from indexing
6. **Performance Metrics**: Show time saved by exclusions
7. **Auto-discovery**: Scan workspace and suggest patterns
8. **Watch Mode**: Monitor filesystem and auto-exclude new matching directories

## Success Criteria

- [✅] Can specify common exclusions in simple pattern syntax
- [✅] Patterns expand correctly to concrete paths
- [✅] Dry-run shows accurate preview
- [✅] Integration with existing spotlight tools works
- [✅] Documentation is clear and includes examples
- [✅] Performance is acceptable (< 30 seconds for typical workspace)
- [✅] Error handling is robust and informative

## Timeline Estimate

- Phase 1 (Core): 3-4 hours
- Phase 2 (Testing): 2-3 hours
- Phase 3 (Integration): 2 hours
- Phase 4 (Polish): 2-3 hours

**Total**: 9-12 hours of focused development

## Open Questions

1. Should we support `.spotlightignore` files in directories (like `.gitignore`)?
2. Should patterns be anchored to specific base paths or allow searching multiple roots?
3. How do we handle the case where a pattern matches nothing?
4. Should we provide a way to "sync" exclusions (remove old, add new)?
5. Do we need a separate tool to show what's currently excluded vs what patterns would add?

## Next Steps

1. Review this plan for any gaps or issues
2. Create example pattern file with common exclusions
3. Start implementation with `spotlight-expand-patterns`
4. Test incrementally with each feature addition
5. Document as we go
