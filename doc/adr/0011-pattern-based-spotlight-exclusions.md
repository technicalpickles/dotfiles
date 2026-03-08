# 11. Pattern-Based Spotlight Exclusions

Date: 2025-10-27

## Status

2025-10-27 accepted

## Context and Problem Statement

While we have tools to manually add Spotlight exclusions ([ADR 0010](0010-manage-spotlight-exclusions-with-applescript.md)), managing exclusions for common patterns across many projects is tedious. For example, excluding `node_modules` from 100+ workspace projects requires running `spotlight-add-exclusion` 100+ times or crafting a long command with all paths listed explicitly.

We need a declarative way to specify exclusion patterns (like `.gitignore`) that can expand to many directories automatically. The solution must:

- Support common patterns like `~/workspace/*/node_modules`
- Be fast enough for practical use (< 30 seconds for typical workspaces)
- Use familiar syntax (gitignore-style)
- Work with existing `spotlight-add-exclusion` tool
- Handle non-existent paths gracefully

## Decision Drivers

- **Developer experience**: Familiar gitignore-style syntax is intuitive
- **Performance**: Must be fast enough for 100+ projects (~1-2 seconds acceptable)
- **Maintainability**: Patterns easier to version-control than hardcoded paths
- **Flexibility**: Support both literal paths and glob patterns
- **Integration**: Work with existing AppleScript-based exclusion tool

## Considered Options

1. **Gitignore-style pattern file with shell expansion**
2. **JSON/YAML configuration with structured rules**
3. **Shell script that hardcodes paths**
4. **Per-project `.spotlightignore` files (like `.gitignore`)**

## Decision Outcome

Chosen option: **"Gitignore-style pattern file with shell expansion"**, because it provides the best balance of familiarity, simplicity, and performance while integrating cleanly with existing tools.

### Implementation

**Three new tools:**

1. **`bin/spotlight-expand-patterns`** - Expands patterns to concrete directory paths

   - Uses `fd` (modern `find` replacement) for fast searching
   - Supports three pattern types:
     - Literal paths: `~/.cache`
     - Single-level glob: `~/workspace/*/node_modules`
     - Recursive globstar: `~/workspace/**/node_modules`
   - Options: `--max-depth`, `--verbose`, `--validate`

2. **`bin/spotlight-apply-exclusions`** - Applies exclusions from pattern file

   - Calls `spotlight-expand-patterns` to get directory list
   - Integrates with existing `spotlight-add-exclusion` tool
   - Supports `--dry-run` for safe previewing

3. **`config/spotlight-exclusions`** - Default pattern file
   - Symlinked to `~/.config/spotlight-exclusions`
   - Curated list of common exclusions
   - Fast by default (literal paths + single-level globs only)
   - Deep recursive patterns commented out

**Pattern syntax:**

```gitignore
# Comments start with #
# Blank lines ignored

# Literal path (tilde expanded)
~/.cache

# Single-level glob (one level deep)
~/workspace/*/node_modules

# Recursive globstar (any depth - slow)
~/workspace/**/node_modules
```

### Positive Consequences

- **Declarative**: Patterns are easy to read, version-control, and share
- **Fast by default**: Single-level globs handle 100+ projects in ~1-2 seconds
- **Familiar syntax**: Developers already know gitignore patterns
- **Flexible**: Support both specific paths and patterns
- **Safe**: Dry-run mode prevents accidental mass exclusions
- **Composable**: Works with existing `spotlight-add-exclusion` tool
- **Maintainable**: Changing patterns doesn't require code changes

### Negative Consequences

- **Requires `fd`**: Not available by default on macOS (but in Brewfile)
- **Glob performance**: Recursive `**/` patterns can be very slow with many nested directories
- **No removal**: Doesn't track which exclusions came from patterns (removal is manual)
- **Path anchoring**: Patterns must specify base path (can't search entire filesystem)

## Pros and Cons of the Options

### Gitignore-style pattern file with shell expansion

**Example:**

```bash
# config/spotlight-exclusions
~/.cache
~/workspace/*/node_modules
```

- ✅ **Good**: Familiar syntax (gitignore)
- ✅ **Good**: Human-readable and easy to edit
- ✅ **Good**: Fast with `fd` (< 2 seconds for 100+ projects)
- ✅ **Good**: Simple implementation (bash + fd)
- ✅ **Good**: Flexible (literal paths, single-level globs, globstar)
- ❌ **Bad**: Requires `fd` dependency
- ❌ **Bad**: Globstar patterns can be slow
- ❌ **Bad**: Less structured than config formats (can't validate schema)

### JSON/YAML configuration with structured rules

**Example:**

```json
{
  "exclusions": {
    "literal": ["~/.cache", "~/.npm/_cacache"],
    "patterns": [{ "base": "~/workspace", "match": "*/node_modules" }]
  }
}
```

- ✅ **Good**: Structured and validatable
- ✅ **Good**: Machine-readable
- ✅ **Good**: Could support advanced features (conditions, variables)
- ❌ **Bad**: More verbose and less intuitive
- ❌ **Bad**: Requires JSON/YAML parser
- ❌ **Bad**: Unfamiliar format for this use case
- ❌ **Bad**: Overkill for simple pattern matching

### Shell script that hardcodes paths

**Example:**

```bash
#!/bin/bash
spotlight-add-exclusion \
  ~/.cache \
  ~/workspace/proj1/node_modules \
  ~/workspace/proj2/node_modules \
  ...
```

- ✅ **Good**: Simple and direct
- ✅ **Good**: No parsing required
- ❌ **Bad**: Not scalable (100+ lines for many projects)
- ❌ **Bad**: Not declarative (must edit script)
- ❌ **Bad**: Hard to diff changes
- ❌ **Bad**: No pattern matching (must list every path)
- ❌ **Bad**: Maintenance burden when adding/removing projects

### Per-project `.spotlightignore` files

**Example:**

```bash
# ~/workspace/project1/.spotlightignore
node_modules
dist
tmp
```

- ✅ **Good**: Granular per-project control
- ✅ **Good**: Can be version-controlled with project
- ✅ **Good**: Familiar pattern (like `.gitignore`)
- ❌ **Bad**: Requires walking entire filesystem to find files
- ❌ **Bad**: Much slower (must check every directory)
- ❌ **Bad**: Doesn't handle user-level caches (~/.cache)
- ❌ **Bad**: More complex implementation
- ❌ **Bad**: Fragmented configuration (hard to see all exclusions)

## Technical Details

### Why `fd` instead of `find`?

- **3-10x faster** for typical searches
- **Simpler syntax** for common operations
- **Respects `.gitignore`** by default (though we disable this)
- **Already in Brewfile** for this dotfiles repo
- **Active development** and modern design

**Trade-off:** Adds dependency, but it's already required by other tools in this repo.

### Why single-level glob by default?

For `~/workspace/*/node_modules` (single-level) vs `~/workspace/**/node_modules` (recursive):

| Pattern           | Projects | Time    | Rationale                                       |
| ----------------- | -------- | ------- | ----------------------------------------------- |
| Single-level `*/` | 117      | ~1.4s   | Only searches immediate children of ~/workspace |
| Recursive `**/`   | 117      | Minutes | Searches every subdirectory recursively (slow)  |

**Decision:** Default to single-level globs for performance. Most projects have a flat structure (`~/workspace/PROJECT/node_modules`), not deeply nested modules.

**Escape hatch:** Users can uncomment `**/` patterns if they have deeply nested structures and are willing to wait.

### Why not use `find`'s `-name` with `-prune`?

`find` with `-prune` could work, but:

- More complex syntax (`-path '*/node_modules' -prune -o -type d -print`)
- Slower than `fd` in practice
- Harder to maintain and reason about

`fd` provides cleaner interface and better performance.

### Performance Characteristics

Tested on macOS with 117 workspace directories:

| Pattern Type       | Example                       | Time    | Strategy                  |
| ------------------ | ----------------------------- | ------- | ------------------------- |
| Literal paths      | `~/.cache`                    | < 1s    | Direct existence check    |
| Single-level glob  | `~/workspace/*/node_modules`  | ~1.4s   | `fd --maxdepth 2`         |
| Recursive globstar | `~/workspace/**/node_modules` | Minutes | `fd --maxdepth 10` (slow) |

**Default config:** 16 literal paths + 1 single-level glob = ~1.5 seconds total

## Alternatives Considered But Rejected

### Using `mdfind` (Spotlight's CLI)

```bash
mdfind -onlyin ~/workspace 'kMDItemFSName == node_modules'
```

- **Rejected**: Ironically requires Spotlight to be indexing the directories we want to exclude
- Would create circular dependency (need indexing to find directories to exclude from indexing)

### Using system `find` with complex glob patterns

```bash
find ~/workspace -maxdepth 2 -type d -name node_modules
```

- **Rejected**: Slower than `fd`, less maintainable syntax
- `fd` is already a dependency in Brewfile

### Creating a domain-specific language (DSL)

```
workspace ~/workspace {
  exclude */node_modules
  exclude */.venv
}
```

- **Rejected**: Overengineered for this use case
- Would require custom parser
- Gitignore syntax is already a well-known DSL

## Implementation Notes

### Handling `fd` trailing slashes

`fd` returns directory paths with trailing slashes (`/Users/josh/workspace/project/node_modules/`), but bash glob patterns don't expect them. Solution: Strip trailing slashes before pattern matching:

```bash
dir="${dir%/}" # Remove trailing slash
```

### Depth calculation for globs

For pattern `~/workspace/*/node_modules`:

- Glob part: `*/node_modules`
- Number of slashes: 1
- Depth: 2 (one slash + 1)

This ensures `fd --maxdepth 2` searches exactly `~/workspace/PROJECT/node_modules`, not deeper.

### Why no state tracking?

**Decision:** Don't track which exclusions came from patterns vs manual additions.

**Rationale:**

- Adds complexity (would need state file)
- macOS already tracks all exclusions in VolumeConfiguration.plist
- Removal can be done manually via System Settings GUI
- Pattern-based re-application is idempotent (skips existing exclusions)

**Trade-off:** Can't automatically remove exclusions when patterns change. User must manually clean up.

## Related Decisions

- [ADR 0010: Manage Spotlight Exclusions with AppleScript](0010-manage-spotlight-exclusions-with-applescript.md) - Provides the underlying GUI automation tool
- [ADR 0008: Disable Spotlight with LaunchAgent](0008-disable-spotlight-with-launchagent.md) - Previous approach (superseded) that disabled Spotlight entirely

## Links

- Implementation plan: `scratch/spotlight-exclusion-file/PLAN.md`
- Documentation: `doc/spotlight-exclusions.md#pattern-based-exclusions-gitignore-style`
- Scripts:
  - `bin/spotlight-expand-patterns`
  - `bin/spotlight-apply-exclusions`
  - `config/spotlight-exclusions`
