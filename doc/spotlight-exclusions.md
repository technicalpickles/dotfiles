# Managing Spotlight Exclusions on macOS

This document describes how to manage Spotlight exclusions in this dotfiles repository using AppleScript-based automation tools.

## Overview

Spotlight is macOS's built-in search and indexing system. While useful for general file search, it can consume significant resources indexing large codebases, dependency directories (`node_modules`, `vendor`, etc.), and temporary build artifacts.

This repository provides tools to manage Spotlight exclusions on a per-directory basis, allowing you to:

- Exclude specific directories from Spotlight indexing (e.g., large codebases, build directories)
- Keep Spotlight enabled system-wide for other uses (like Alfred, which depends on Spotlight)
- List currently excluded directories across all volumes

## Quick Start

### Pattern-Based Exclusions (Recommended)

The easiest way to exclude common directories is using pattern-based exclusions:

```bash
# Preview what would be excluded
bin/spotlight-apply-exclusions --dry-run ~/.config/spotlight-exclusions

# Apply exclusions from pattern file
bin/spotlight-apply-exclusions ~/.config/spotlight-exclusions
```

The pattern file uses gitignore-style syntax to specify directories. Edit `~/.config/spotlight-exclusions` to customize patterns for your setup.

**See [Pattern-Based Exclusions](#pattern-based-exclusions-gitignore-style) below for details.**

### Manual Directory Exclusions

For one-off exclusions, use `spotlight-add-exclusion` directly:

```bash
# Add a single directory
bin/spotlight-add-exclusion /Users/josh.nichols/workspace/project/node_modules

# Add multiple directories at once (efficient - single UI session)
bin/spotlight-add-exclusion ~/workspace/proj1/node_modules ~/workspace/proj2/vendor ~/workspace/proj3/tmp
```

This will:

1. Check current exclusions to avoid duplicates
2. Validate that directories exist
3. Open System Settings > Spotlight
4. Click "Search Privacy" button
5. Add each new directory
6. Close the settings modal
7. Display the updated list of all exclusions

### List current exclusions

```bash
bin/spotlight-list-exclusions
```

This displays exclusions from all volumes, including the Data volume where user directory exclusions are stored.

## Usage Instructions

### Adding Exclusions: `spotlight-add-exclusion`

**Syntax:**

```bash
bin/spotlight-add-exclusion < directory-path > [ < directory-path2 > ...]
```

**Examples:**

```bash
# Exclude a single directory
bin/spotlight-add-exclusion ~/workspace/myproject/node_modules

# Exclude multiple directories at once (efficient - uses single UI session)
bin/spotlight-add-exclusion \
  ~/workspace/proj1/node_modules \
  ~/workspace/proj2/vendor \
  ~/workspace/proj3/tmp \
  ~/workspace/proj4/.next

# Exclude an entire project
bin/spotlight-add-exclusion ~/workspace/large-monorepo

# Script automatically skips duplicates and non-existent paths
bin/spotlight-add-exclusion ~/existing ~/new ~/already-excluded ~/doesnt-exist
# Output: Will skip "already-excluded" and "doesnt-exist", only adds "new"
```

**Features:**

- **Deduplication**: Automatically checks current exclusions and skips directories that are already excluded
- **Validation**: Verifies directories exist before attempting to add them
- **Batch Processing**: Adds multiple directories in a single UI session (much faster than running the script multiple times)
- **Feedback**: Shows which directories were added, skipped, or invalid

**Requirements:**

- **Accessibility Permissions**: The first time you run this, macOS will prompt you to grant accessibility permissions to your terminal app (Terminal.app, iTerm2, etc.) in System Settings > Privacy & Security > Accessibility
- **System Settings Must Be Closed**: The script automatically closes System Settings if it's open
- **Python 3**: Required for parsing current exclusions (pre-installed on macOS)

**What Happens:**

The script uses AppleScript to automate the following UI workflow:

1. Opens System Settings > Spotlight
2. Clicks the "Search Privacy" button (which has no accessible name, so it's located by position)
3. Waits for the modal to appear
4. Clicks the "Add" button
5. Uses `Cmd+Shift+G` to open "Go to Folder" dialog
6. Types the target path and confirms
7. Closes the modal

**Verification:**

After running, you can verify the exclusion was added by:

- Checking System Settings > Spotlight > Search Privacy (GUI)
- Running `bin/spotlight-list-exclusions` (command line)

**Troubleshooting:**

| Error                                 | Solution                                                                                                 |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| "Directory does not exist"            | Verify the path is correct and the directory exists                                                      |
| Accessibility permission denied       | Grant accessibility permissions to your terminal in System Settings > Privacy & Security > Accessibility |
| "No sheet found"                      | System Settings may already be open. Close it and try again                                              |
| Script hangs at "Clicking Add button" | The UI structure may have changed. See research files in `scratch/`                                      |

### Listing Exclusions: `spotlight-list-exclusions`

**Syntax:**

```bash
bin/spotlight-list-exclusions
```

**Requirements:**

- **sudo access**: The script needs to read VolumeConfiguration.plist files via `mdutil -P`, which requires elevated permissions

**Output:**

The script shows:

- Exclusions on the System Volume (`/`)
- Exclusions on the Data Volume (`/System/Volumes/Data`) - where user directory exclusions live
- Exclusions on any additional mounted external volumes
- Indexing status for each volume

**Example Output:**

```
=== Spotlight Exclusions ===

### System Volume ###

Status: /:
	Indexing enabled.

Exclusions:
  (none)

### Data Volume (User Data) ###

Status: /System/Volumes/Data:
	Indexing enabled.

Exclusions:
  • /Users/josh.nichols/workspace/zenpayroll/tmp
  • /Users/josh.nichols/workspace/large-project/node_modules

=== Additional Mounted Volumes ===
(none mounted)
```

## Pattern-Based Exclusions (Gitignore-Style)

The pattern-based exclusion system provides a declarative way to manage Spotlight exclusions using a familiar gitignore-style syntax.

### Overview

Instead of manually adding each directory, you can specify patterns in a configuration file (`~/.config/spotlight-exclusions`) and apply them all at once. This is especially useful for excluding common patterns across many projects (like `node_modules`, `.venv`, build artifacts, etc.).

### Quick Example

```bash
# Preview what would be excluded
bin/spotlight-apply-exclusions --dry-run ~/.config/spotlight-exclusions

# Apply the exclusions
bin/spotlight-apply-exclusions ~/.config/spotlight-exclusions
```

### Pattern Syntax

The pattern file supports three types of patterns:

#### 1. Literal Paths

Exact directory paths with tilde expansion:

```gitignore
~/.cache
~/.npm/_cacache
~/Library/Caches
```

These are fast (< 1 second) and expand `~` to your home directory.

#### 2. Single-Level Glob

Match immediate children of a directory using `*/`:

```gitignore
# Matches ~/workspace/PROJECT/node_modules (one level deep)
~/workspace/*/node_modules

# Matches ~/workspace/PROJECT/dist
~/workspace/*/dist
```

This is reasonably fast (~1-2 seconds for 100+ projects) and only searches one level deep.

#### 3. Recursive Globstar (Use Sparingly)

Match at any depth using `**/`:

```gitignore
# Matches node_modules anywhere under ~/workspace
~/workspace/**/node_modules

# Matches __pycache__ at any depth
~/workspace/**/__pycache__
```

**⚠️ Warning:** Recursive patterns can be very slow with many projects (minutes). Use single-level globs when possible.

### Default Pattern File

The default pattern file is located at `config/spotlight-exclusions` in this repository and symlinked to `~/.config/spotlight-exclusions`.

It includes:

- **User-level caches** (literal paths): `~/.cache`, `~/.npm/_cacache`, etc.
- **Development tool installations**: `~/.mise/installs`, `~/.rbenv/versions`, etc.
- **macOS system caches**: `~/Library/Caches`, `~/Library/Logs`
- **Container data**: `~/.docker`, `~/.vagrant.d`
- **Workspace patterns** (single-level): `~/workspace/*/node_modules` (commented examples)

**Default patterns are fast by default** - only literal paths and one workspace pattern are enabled. Deep recursive patterns are commented out.

### Customizing Patterns

Edit the pattern file to match your setup:

```bash
# Edit with your preferred editor
code ~/.config/spotlight-exclusions

# Or edit the source file
code config/spotlight-exclusions
```

**Pattern File Format:**

```gitignore
# Comments start with #
# Blank lines are ignored

# User-level caches (fast)
~/.cache
~/.npm/_cacache

# Workspace patterns (reasonably fast with single-level glob)
~/workspace/*/node_modules
~/workspace/*/.venv
~/workspace/*/dist

# Deep recursive patterns (slow - use only if needed)
# ~/workspace/**/__pycache__
# ~/workspace/**/coverage
```

### Tools

#### `spotlight-expand-patterns`

Expands patterns to concrete directory paths:

```bash
# Expand patterns and show results
bin/spotlight-expand-patterns ~/.config/spotlight-exclusions

# With verbose output
bin/spotlight-expand-patterns --verbose ~/.config/spotlight-exclusions

# Limit recursion depth for globstar patterns
bin/spotlight-expand-patterns --max-depth 5 ~/.config/spotlight-exclusions
```

**Options:**

- `--verbose, -v`: Show detailed expansion process
- `--max-depth N`: Limit recursion depth for `**/` patterns (default: 10)
- `--validate`: Validate patterns before searching
- `--help, -h`: Show usage information

**Requirements:**

- **`fd` command**: Required for fast directory searching (installed via Homebrew)

#### `spotlight-apply-exclusions`

Applies exclusions from a pattern file:

```bash
# Dry-run (preview only)
bin/spotlight-apply-exclusions --dry-run ~/.config/spotlight-exclusions

# Apply exclusions
bin/spotlight-apply-exclusions ~/.config/spotlight-exclusions

# With verbose output
bin/spotlight-apply-exclusions --verbose ~/.config/spotlight-exclusions
```

**Options:**

- `--dry-run, -n`: Show what would be excluded without applying
- `--verbose, -v`: Show detailed progress
- `--max-depth N`: Limit recursion depth for globstar patterns (default: 10)
- `--validate`: Validate patterns before applying
- `--help, -h`: Show usage information

**What It Does:**

1. Expands patterns using `spotlight-expand-patterns`
2. Shows summary of directories to exclude
3. Calls `spotlight-add-exclusion` with all directories (unless `--dry-run`)
4. Reports progress and final summary

### Performance

Pattern expansion performance varies by pattern type:

| Pattern Type       | Example                       | Performance (117 projects) |
| ------------------ | ----------------------------- | -------------------------- |
| Literal paths      | `~/.cache`                    | < 1 second                 |
| Single-level glob  | `~/workspace/*/node_modules`  | ~1-2 seconds               |
| Recursive globstar | `~/workspace/**/node_modules` | Minutes (very slow)        |

**Recommendation:** Use literal paths and single-level globs for best performance. Avoid recursive globstar patterns with many projects.

### Examples

#### Exclude Node.js Dependencies

```gitignore
# Single-level (fast - only immediate children)
~/workspace/*/node_modules

# Recursive (slow - searches deeply nested)
# ~/workspace/**/node_modules
```

#### Exclude Python Virtual Environments

```gitignore
~/workspace/*/.venv
~/workspace/*/venv
```

#### Exclude Build Artifacts

```gitignore
~/workspace/*/build
~/workspace/*/dist
~/workspace/*/.next
~/workspace/*/.turbo
```

#### Exclude Everything Under a Specific Project

```gitignore
# Exclude entire project
~/workspace/large-monorepo

# Or specific subdirectories
~/workspace/large-monorepo/node_modules
~/workspace/large-monorepo/build
```

### Troubleshooting

#### Pattern matches nothing

**Cause:** Directory doesn't exist or pattern syntax is incorrect

**Solutions:**

- Verify directories exist: `ls -ld ~/workspace/*/node_modules`
- Use `--verbose` to see expansion details
- Check pattern syntax matches one of the three types

#### Expansion is very slow

**Cause:** Using recursive globstar (`**/`) with many directories

**Solutions:**

- Replace `~/workspace/**/node_modules` with `~/workspace/*/node_modules` (single-level)
- Reduce `--max-depth` value
- Use literal paths for specific projects instead

#### "fd is required but not installed"

**Cause:** `fd` command not found

**Solution:** Install via Homebrew: `brew install fd`

## Monitoring Spotlight Activity

Before excluding directories, it's helpful to identify which directories Spotlight is actively indexing and causing high resource usage.

### Analyze Indexing Activity

**`spotlight-analyze-activity`** - Analyzes what Spotlight is indexing over a period of time:

```bash
# Analyze for 60 seconds (default: 30)
bin/spotlight-analyze-activity 60

# Analyze specific process (e.g., only mds_stores)
bin/spotlight-analyze-activity 30 mds_stores
```

**Output includes:**

- Top 20 directories by access count
- Top file types being indexed
- Recent activity samples
- High-volume directories (>50 accesses) - candidates for exclusion

**Use case:** Run this when Spotlight is consuming high CPU to identify which directories are causing the load.

### Live Monitoring

**`spotlight-monitor-live`** - Real-time view of Spotlight activity:

```bash
# Monitor all Spotlight processes
bin/spotlight-monitor-live

# Monitor specific process
bin/spotlight-monitor-live mdworker
```

Press **Ctrl+C** to stop and see summary statistics.

**Use case:** Watch what Spotlight is doing in real-time to understand indexing patterns.

### Workflow: Identify and Exclude Problem Directories

1. **Monitor activity** when Spotlight is using high resources:

   ```bash
   bin/spotlight-analyze-activity 60
   ```

2. **Identify high-volume directories** from the output:

   ```
   💡 High-Volume Directories (Consider adding to Spotlight Privacy):
      • ~/workspace/large-project/node_modules (234 accesses)
      • ~/Library/Caches/com.apple.Safari (189 accesses)
      • ~/.npm/_cacache (156 accesses)
   ```

3. **Add patterns to exclusion file**:

   ```bash
   # Edit pattern file
   code ~/.config/spotlight-exclusions
   
   # Add discovered directories:
   # ~/workspace/*/node_modules
   # ~/.npm/_cacache
   ```

4. **Preview exclusions**:

   ```bash
   bin/spotlight-apply-exclusions --dry-run ~/.config/spotlight-exclusions
   ```

5. **Apply exclusions**:

   ```bash
   bin/spotlight-apply-exclusions ~/.config/spotlight-exclusions
   ```

6. **Verify improvement** with live monitoring:
   ```bash
   bin/spotlight-monitor-live
   ```
   You should see reduced activity after exclusions are applied.

### Monitoring Requirements

Both tools require:

- **sudo access** (to use `fs_usage` for monitoring filesystem activity)
- **Terminal app** must be running (not just the command)

**Note:** These tools use `fs_usage` which has minimal performance impact but requires elevated privileges to monitor system processes.

## How It Works

### AppleScript UI Automation

The `spotlight-add-exclusion` script uses macOS's AppleScript and System Events framework to programmatically interact with the System Settings UI. This is the same approach a human would use, but automated.

**Why AppleScript?**

- No public API exists for managing Spotlight exclusions
- The only reliable method is through the GUI (System Settings > Spotlight > Search Privacy)
- AppleScript can automate clicking buttons and navigating the UI
- Once accessibility permissions are granted, it's fully scriptable

**Limitations:**

- Requires accessibility permissions
- Fragile if Apple changes the UI structure in future macOS versions
- Must wait for UI elements to load (adds ~5-10 seconds per exclusion)

### APFS Volume Groups and Data Storage

Modern macOS (Catalina+) uses **APFS volume groups** that split the system into two logical volumes:

- **System Volume** (`/`): Read-only, sealed, contains OS files
- **Data Volume** (`/System/Volumes/Data`): Read-write, contains all user data

Your home directory appears at `/Users/josh.nichols`, but physically lives on the Data volume at `/System/Volumes/Data/Users/josh.nichols`. macOS uses **firmlinks** to make this transparent.

**Implications for Spotlight Exclusions:**

Exclusions are stored in `.Spotlight-V100/VolumeConfiguration.plist` on each volume. Since user directories physically live on the Data volume, exclusions for paths like `/Users/josh.nichols/workspace/*` are stored on the Data volume's configuration, not the root volume.

This is why `spotlight-list-exclusions` checks both volumes.

**See Also:**

- `scratch/RESOLVED-spotlight-storage-mystery.md` - Documents the research that solved this mystery

### VolumeConfiguration.plist Parsing

The `spotlight-list-exclusions` script parses XML plists returned by `mdutil -P <volume>`. The relevant structure:

```xml
<key>Exclusions</key>
<array>
    <string>/Users/josh.nichols/workspace/project/tmp</string>
    <string>/Users/josh.nichols/workspace/project/node_modules</string>
</array>
```

The script uses a state machine to:

1. Find the `<key>Exclusions</key>` line
2. Extract all `<string>` elements until `</array>`
3. Handle both empty arrays (`<array/>`) and populated arrays
4. Avoid capturing strings from other plist sections

## Alternative Exclusion Methods

Besides the GUI-managed exclusions (via `spotlight-add-exclusion`), you can also exclude directories using:

### 1. `.noindex` Extension

Rename directories with a `.noindex` suffix:

```bash
mv node_modules node_modules.noindex
```

**Status:** ✅ **Verified Working** (tested on modern macOS)

**Pros:**

- No sudo required
- No accessibility permissions needed
- Can be version-controlled (e.g., `.gitignore` patterns)
- Works in subdirectories

**Cons:**

- Changes directory name (may break hardcoded paths)
- Requires renaming back if needed
- Manual per-directory

### 2. `.metadata_never_index` File

Place an empty file at the **root** of a volume:

```bash
sudo touch /Volumes/ExternalDrive/.metadata_never_index
```

**Status:** ⚠️ **Volume Root Only** - Does NOT work in subdirectories since macOS Mojave

**Pros:**

- Simple empty file
- No accessibility permissions

**Cons:**

- **Only works at volume root** (not in subdirectories like `~/workspace`)
- Difficult to validate (absence of indexed files ≠ proof it worked)
- May require remounting the volume

### 3. Manual GUI

Open System Settings > Spotlight > Search Privacy and drag directories into the list.

**Pros:**

- Official Apple-supported method
- Visual confirmation

**Cons:**

- Not scriptable
- Not portable across machines
- Time-consuming for many directories

## Requirements

### For `spotlight-add-exclusion`

- **macOS Catalina (10.15) or later**: Tested on Catalina through Sequoia
- **Accessibility Permissions**: System Settings > Privacy & Security > Accessibility
  - Grant permission to your terminal app (Terminal, iTerm2, Warp, etc.)
  - The script will prompt for this on first run
- **System Settings Must Be Closed**: Close System Settings before running

### For `spotlight-list-exclusions`

- **sudo Access**: Required to read VolumeConfiguration.plist via `mdutil -P`
- **Spotlight Enabled**: If Spotlight is disabled system-wide, exclusions exist but have no effect

## Integration with Alfred

**Important:** Alfred (the macOS productivity app) requires Spotlight to be enabled to index and search files. This is why we use **granular per-directory exclusions** instead of disabling Spotlight system-wide.

If you previously disabled Spotlight using a LaunchAgent (per ADR 0008), re-enable it:

```bash
sudo mdutil -a -i on
```

Then use `spotlight-add-exclusion` to exclude only the specific directories you don't want indexed (e.g., `node_modules`, build artifacts, large datasets).

## Troubleshooting

### "Operation not permitted" when running spotlight-list-exclusions

**Cause:** Script needs sudo to read VolumeConfiguration.plist

**Solution:** The script already uses `sudo` internally. You may need to enter your password when prompted.

### "Directory does not exist" when adding exclusion

**Cause:** The path doesn't exist or has a typo

**Solution:**

- Verify path with `ls -ld /path/to/directory`
- Use tab completion to avoid typos
- Use absolute paths (start with `/` or `~`)

### AppleScript errors or "button not found"

**Cause:** UI structure changed in newer macOS, or System Settings was already open

**Solutions:**

1. Close System Settings completely and try again
2. Verify accessibility permissions are granted
3. Check if macOS version changed the UI (may need script updates)

### Exclusion added but directory still being indexed

**Cause:** Spotlight may take time to stop indexing, or the exclusion didn't register

**Solutions:**

1. Wait 5-10 minutes for Spotlight to recognize the change
2. Verify the exclusion appears in System Settings > Spotlight > Search Privacy
3. Force Spotlight to re-read config: `sudo mdutil -E /`
4. Check `spotlight-list-exclusions` output to confirm it's listed

### "No sheet found" error

**Cause:** The modal didn't appear, or System Settings was on wrong pane

**Solutions:**

1. Close System Settings completely
2. Ensure you don't have other System Settings windows open
3. Try running the script again

## See Also

### Architecture Decisions

- [ADR 0011: Pattern-Based Spotlight Exclusions](adr/0011-pattern-based-spotlight-exclusions.md) - Gitignore-style pattern system design
- [ADR 0010: Manage Spotlight Exclusions with AppleScript](adr/0010-manage-spotlight-exclusions-with-applescript.md) - AppleScript GUI automation approach
- [ADR 0008: Disable Spotlight with LaunchAgent](adr/0008-disable-spotlight-with-launchagent.md) - Previous approach (superseded)

### Research Documentation

- [spotlight-research/](spotlight-research/) - Consolidated research documentation
  - [applescript-approach.md](spotlight-research/applescript-approach.md) - AppleScript research process
  - [apfs-volume-discovery.md](spotlight-research/apfs-volume-discovery.md) - APFS volume groups and where exclusions are stored
  - [pattern-system-plan.md](spotlight-research/pattern-system-plan.md) - Pattern system implementation plan
  - [historical/](spotlight-research/historical/) - Additional research documents

### Tools

- `bin/spotlight-add-exclusion` - AppleScript-based GUI automation
- `bin/spotlight-list-exclusions` - List exclusions from all volumes
- `bin/spotlight-expand-patterns` - Expand gitignore-style patterns
- `bin/spotlight-apply-exclusions` - Batch apply exclusions
- `bin/spotlight-analyze-activity` - Analyze indexing activity
- `bin/spotlight-monitor-live` - Live monitoring of Spotlight processes

## Future Improvements

Potential enhancements for these tools:

- **Batch adding**: Accept multiple directories as arguments
- **Remove exclusions**: Reverse operation to remove directories from exclusions list
- **JSON output**: Machine-readable format for `spotlight-list-exclusions`
- **Pre-flight checks**: Verify accessibility permissions before attempting automation
- **Retry logic**: Automatically retry if UI elements aren't found (with exponential backoff)
- **CI/CD integration**: Automatically exclude build directories in new projects
