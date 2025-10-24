# 10. Manage Spotlight Exclusions with AppleScript

Date: 2025-10-23

## Status

Accepted

Supersedes [ADR-0008](0008-disable-spotlight-with-launchagent.md)

## Context and Problem Statement

Spotlight indexing on macOS consumes significant CPU and I/O resources when indexing large codebases, dependency directories (node_modules, vendor), and build artifacts. However, **disabling Spotlight entirely** (as implemented in ADR-0008) has an unacceptable consequence: **Alfred stops working**.

Alfred, the macOS productivity app, relies on Spotlight's indexing to search files and applications. With Spotlight disabled system-wide, Alfred cannot find or launch applications, making it unusable.

**The core problem:** How can we reduce Spotlight's resource consumption from indexing unwanted directories while keeping it enabled for Alfred and other tools that depend on it?

## Decision Drivers

- **Alfred compatibility**: Alfred requires Spotlight to be enabled to function
- **Granular control**: Need to exclude specific directories (e.g., `node_modules`, build artifacts) without disabling all indexing
- **Automation**: Solution must be scriptable and portable via dotfiles
- **Reliability**: Exclusions must persist across reboots
- **Portability**: Must work across multiple macOS machines

## Considered Options

1. **AppleScript-based UI automation** ⭐
2. **Continue with system-wide Spotlight disable (ADR-0008)**
3. **Manual GUI management**
4. **`.metadata_never_index` files**
5. **`.noindex` directory extension**

## Decision Outcome

Chosen option: **"AppleScript-based UI automation"**, because it provides:

- Granular per-directory exclusion management (keeps Spotlight running for Alfred)
- Scriptable automation (can be run from dotfiles or CI/CD)
- Persistent exclusions (stored in VolumeConfiguration.plist by macOS)
- Official Apple method (uses System Settings GUI, same as manual process)

### Implementation

Created two utility scripts:

1. **`bin/spotlight-add-exclusion`**: AppleScript that automates adding directories to Spotlight exclusions

   - Accepts directory path as command-line argument
   - Uses System Events to navigate System Settings UI
   - Automates: Open Spotlight settings → Click "Search Privacy" → Click "Add" → Navigate to directory → Confirm

2. **`bin/spotlight-list-exclusions`**: Bash script that lists current exclusions
   - Reads VolumeConfiguration.plist from all mounted volumes using `mdutil -P`
   - Parses XML to extract exclusion paths
   - Handles APFS volume groups (checks both root and Data volumes)

### Positive Consequences

- **Alfred continues working**: Spotlight remains enabled system-wide
- **Granular control**: Exclude only problem directories (node_modules, build artifacts, large datasets)
- **Scriptable**: Can be automated in setup scripts or CI/CD pipelines
- **Persistent**: Exclusions stored in system plists, survive reboots
- **Discoverable**: `spotlight-list-exclusions` shows what's excluded
- **Portable**: Works across all macOS machines via dotfiles

### Negative Consequences

- **Requires accessibility permissions**: Terminal must be granted accessibility permissions in System Settings
- **UI-dependent**: If Apple changes System Settings UI, script may break
- **Slower than API**: Each exclusion takes ~5-10 seconds (UI automation delays)
- **Spotlight still runs**: Background indexing still consumes resources (just on fewer directories)
- **Manual per-directory**: Must explicitly exclude each directory (unlike system-wide disable)

## Pros and Cons of the Options

### AppleScript-based UI Automation

Uses macOS's System Events framework to programmatically interact with System Settings GUI.

- Good, because Alfred and other Spotlight-dependent tools continue working
- Good, because granular control over which directories are excluded
- Good, because scriptable and can be automated
- Good, because exclusions are stored in official macOS plists (persistent)
- Good, because uses official Apple GUI method (same as manual process)
- Bad, because requires accessibility permissions
- Bad, because fragile if UI structure changes in future macOS versions
- Bad, because slower than a direct API (5-10 seconds per exclusion)
- Bad, because each directory must be explicitly excluded

**Research that validated this approach:**

- `scratch/applescript-spotlight-research.md`: Documents exploration of AppleScript capabilities
- `scratch/applescript-spotlight-final-findings.md`: Confirms modal navigation works
- `scratch/RESOLVED-spotlight-storage-mystery.md`: Solves where exclusions are stored (APFS Data volume)

### Continue with System-Wide Spotlight Disable (ADR-0008)

Keep the LaunchAgent that runs `mdutil -a -i off` at startup.

- Good, because completely eliminates Spotlight resource consumption
- Good, because simple implementation (one LaunchAgent plist)
- Good, because already implemented and tested
- Bad, because **breaks Alfred** (cannot search or launch apps)
- Bad, because breaks any other tools that depend on Spotlight
- Bad, because all-or-nothing (can't selectively enable for some directories)

**Why rejected:** Alfred compatibility is a blocker. Alfred is a critical productivity tool and cannot be sacrificed.

### Manual GUI Management

Open System Settings > Spotlight > Search Privacy and manually drag directories into the exclusion list.

- Good, because official Apple-supported method
- Good, because no accessibility permissions needed
- Good, because visual confirmation
- Bad, because not scriptable
- Bad, because not portable (settings don't sync via dotfiles)
- Bad, because time-consuming for many directories
- Bad, because error-prone (easy to forget directories)

**Why rejected:** Not automatable, defeats the purpose of dotfiles.

### `.metadata_never_index` Files

Place empty `.metadata_never_index` files in directories to exclude them.

- Good, because no sudo required
- Good, because can be version-controlled
- Bad, because **only works at volume root** (not subdirectories) since macOS Mojave
- Bad, because difficult to validate (absence of evidence ≠ evidence of absence)
- Bad, because doesn't actually reduce system-wide Spotlight resource usage

**Why rejected:** Doesn't work in subdirectories on modern macOS. See ADR-0008 notes on validation difficulties.

### `.noindex` Directory Extension

Rename directories with `.noindex` suffix (e.g., `node_modules.noindex`).

- Good, because no sudo required
- Good, because no accessibility permissions needed
- Good, because works in subdirectories
- Good, because validated and confirmed working on modern macOS
- Bad, because changes directory name (may break hardcoded paths)
- Bad, because requires renaming back if needed
- Bad, because not all directories can be renamed (e.g., active project directories)

**Why rejected:** Useful as a supplement, but not a complete solution. Cannot rename active project directories or directories with hardcoded paths in configs.

## Implementation Details

### AppleScript UI Navigation

The `spotlight-add-exclusion` script navigates the following UI hierarchy:

```
System Settings > Spotlight
  └─ Window 1
      └─ Group
          └─ Splitter Group
              └─ Content Group
                  └─ Inner Group
                      └─ Button (description: "button") <-- "Search Privacy" button (no accessible name)
```

**Challenges Solved:**

1. **Button has no accessible name**: The "Search Privacy" button has `name: missing value`. Script locates it by class and description.
2. **File picker navigation**: Instead of clicking through nested folders, script uses `Cmd+Shift+G` to open "Go to Folder" and types the full path.
3. **Modal access**: Original research incorrectly concluded modal was inaccessible (error -10000). Actually works fine with `every UI element`.

### APFS Volume Groups and Storage Location

Modern macOS uses APFS volume groups:

- **System Volume** (`/`): Read-only, sealed OS files
- **Data Volume** (`/System/Volumes/Data`): Read-write user data

User directories like `/Users/josh.nichols` appear at root but physically live on Data volume via firmlinks.

**Critical Insight:** Exclusions for user paths are stored on the **Data volume's** VolumeConfiguration.plist, not the root volume's.

This is why `spotlight-list-exclusions` checks both volumes:

```bash
sudo mdutil -P /                    # System volume exclusions
sudo mdutil -P /System/Volumes/Data # User data exclusions (where most exclusions live)
```

**Research:** `scratch/RESOLVED-spotlight-storage-mystery.md` documents solving this mystery.

## Maintenance

### After macOS Updates

- Test scripts after major macOS updates (UI structure may change)
- Run `bin/spotlight-add-exclusion <test-dir>` to verify it still works
- If script fails, check `scratch/applescript-spotlight-research.md` for UI exploration methodology

### Managing Exclusions

```bash
# Add exclusion
bin/spotlight-add-exclusion ~/workspace/project/node_modules

# List current exclusions
bin/spotlight-list-exclusions

# Verify exclusion in GUI
# System Settings > Spotlight > Search Privacy
```

### Re-enabling Spotlight (Transition from ADR-0008)

If transitioning from the LaunchAgent approach:

```bash
# 1. Unload LaunchAgent
./launchagents.sh unload com.technicalpickles.disable-spotlight

# 2. Re-enable Spotlight
sudo mdutil -a -i on

# 3. Verify Alfred works
# Open Alfred (Cmd+Space) and search for an application

# 4. Add specific exclusions
bin/spotlight-add-exclusion ~/workspace/large-project/node_modules
bin/spotlight-add-exclusion ~/workspace/monorepo/tmp
```

## Resources

- **Documentation**: [doc/spotlight-exclusions.md](../spotlight-exclusions.md) - Comprehensive usage guide
- **Research**: `scratch/applescript-spotlight-research.md` - AppleScript exploration methodology
- **Research**: `scratch/applescript-spotlight-final-findings.md` - Validation results
- **Research**: `scratch/RESOLVED-spotlight-storage-mystery.md` - APFS volume group storage explanation
- **Scripts**: [bin/spotlight-add-exclusion](../../bin/spotlight-add-exclusion), [bin/spotlight-list-exclusions](../../bin/spotlight-list-exclusions)

## Links

- Supersedes [ADR-0008](0008-disable-spotlight-with-launchagent.md) - Disable Spotlight with LaunchAgent
