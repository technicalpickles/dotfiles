# Managing Spotlight Exclusions on macOS

This document describes how to manage Spotlight exclusions in this dotfiles repository using AppleScript-based automation tools.

## Overview

Spotlight is macOS's built-in search and indexing system. While useful for general file search, it can consume significant resources indexing large codebases, dependency directories (`node_modules`, `vendor`, etc.), and temporary build artifacts.

This repository provides tools to manage Spotlight exclusions on a per-directory basis, allowing you to:

- Exclude specific directories from Spotlight indexing (e.g., large codebases, build directories)
- Keep Spotlight enabled system-wide for other uses (like Alfred, which depends on Spotlight)
- List currently excluded directories across all volumes

## Quick Start

### Add directories to exclusions

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

- [ADR 0010: Manage Spotlight Exclusions with AppleScript](adr/0010-manage-spotlight-exclusions-with-applescript.md) - Architecture decision documenting why we use this approach
- [ADR 0008: Disable Spotlight with LaunchAgent](adr/0008-disable-spotlight-with-launchagent.md) - Previous approach (superseded) that disabled Spotlight entirely
- `scratch/applescript-spotlight-research.md` - Research documenting how the AppleScript approach was developed
- `scratch/RESOLVED-spotlight-storage-mystery.md` - Research solving where exclusions are stored on APFS volume groups

## Future Improvements

Potential enhancements for these tools:

- **Batch adding**: Accept multiple directories as arguments
- **Remove exclusions**: Reverse operation to remove directories from exclusions list
- **JSON output**: Machine-readable format for `spotlight-list-exclusions`
- **Pre-flight checks**: Verify accessibility permissions before attempting automation
- **Retry logic**: Automatically retry if UI elements aren't found (with exponential backoff)
- **CI/CD integration**: Automatically exclude build directories in new projects
