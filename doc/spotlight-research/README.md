# Spotlight Research Documentation

This directory contains research and analysis that led to the Spotlight exclusion management system.

## Key Documents

### [apfs-volume-discovery.md](apfs-volume-discovery.md)

Discovery that Spotlight exclusions are stored on the **Data volume** (`/System/Volumes/Data`), not the root volume (`/`). This was a critical finding because user directories physically live on the Data volume in modern macOS (Catalina+), and we were initially checking the wrong volume.

**Key Insight:** When listing exclusions, you must check both `/` and `/System/Volumes/Data` to see all exclusions.

### [applescript-approach.md](applescript-approach.md)

Detailed research process for developing AppleScript-based GUI automation of System Settings. Documents the extensive UI exploration needed to:

- Find the "Search Privacy" button (which has no accessible name!)
- Navigate the System Settings UI tree
- Automate adding directories to Spotlight Privacy list

**Outcome:** Working tool at `bin/spotlight-add-exclusion`

### [pattern-system-plan.md](pattern-system-plan.md)

Complete implementation plan for the pattern-based exclusion system using gitignore-style syntax. Includes:

- Pattern syntax design
- Tool architecture (expand-patterns + apply-exclusions)
- Performance considerations
- Phase-by-phase implementation steps

**Outcome:** Working tools at `bin/spotlight-expand-patterns` and `bin/spotlight-apply-exclusions`

## Production Tools

This research led to these production tools in `bin/`:

| Tool                         | Purpose                                                |
| ---------------------------- | ------------------------------------------------------ |
| `spotlight-add-exclusion`    | AppleScript-based GUI automation for adding exclusions |
| `spotlight-list-exclusions`  | Lists exclusions from all volumes (Data + root)        |
| `spotlight-expand-patterns`  | Expands gitignore-style patterns to directory paths    |
| `spotlight-apply-exclusions` | Batch applies exclusions from pattern file             |
| `spotlight-analyze-activity` | Analyzes what Spotlight is actively indexing           |
| `spotlight-monitor-live`     | Live monitoring of Spotlight process activity          |

## Architecture Decisions

- [ADR 0010](../adr/0010-manage-spotlight-exclusions-with-applescript.md) - AppleScript-based approach
- [ADR 0011](../adr/0011-pattern-based-spotlight-exclusions.md) - Pattern-based exclusions with gitignore syntax

## Complete Documentation

See [doc/spotlight-exclusions.md](../spotlight-exclusions.md) for complete usage documentation covering:

- Pattern-based exclusions (recommended)
- Manual GUI exclusions
- Monitoring tools
- Alternative exclusion methods
- Troubleshooting

## Historical Research

Additional research documents are in the [historical/](historical/) subdirectory, including:

- AppleScript UI exploration findings
- Storage location research
- Exclusion method analysis
- Validation and testing notes

These documents provide context for how the production tools were developed and may be useful if macOS changes the UI in future versions.

## Key Discoveries

### 1. APFS Volume Groups

Modern macOS splits the filesystem into System (read-only) and Data (read-write) volumes. User directories appear at `/Users` but physically live on `/System/Volumes/Data/Users`. Spotlight exclusions are stored per-volume, so exclusions for user directories are on the Data volume.

### 2. AppleScript UI Automation

Successfully automated the Spotlight Privacy GUI despite challenges:

- "Search Privacy" button has no accessible name (identified by position/description)
- Modal dialog IS accessible (contrary to initial findings)
- Requires accessibility permissions for terminal/editor

### 3. Pattern Performance

- Literal paths: < 1 second
- Single-level globs (`*/pattern`): ~1-2 seconds for 100+ directories
- Recursive globstar (`**/pattern`): Minutes (too slow for practical use)

**Decision:** Default to single-level globs for performance.

### 4. Tool Dependency

Using `fd` instead of `find` provides 3-10x performance improvement and cleaner syntax. Already in Brewfile, so no additional dependency introduced.

## Timeline

- **Oct 8, 2025** - Initial Spotlight research, validation of exclusion methods
- **Oct 23, 2025** - AppleScript UI exploration and working prototype
- **Oct 23, 2025** - APFS volume group discovery (Data vs root volume)
- **Oct 27, 2025** - Pattern-based system design and implementation
- **Oct 28, 2025** - Research artifacts archived, docs reorganized

## Related Files

- **Production code:** `bin/spotlight-*`
- **Main documentation:** `doc/spotlight-exclusions.md`
- **ADRs:** `doc/adr/0010-*.md` and `doc/adr/0011-*.md`
- **Archived prototypes:** `scratch/archive/spotlight-research/prototypes/`
- **Configuration:** `config/spotlight-exclusions`
