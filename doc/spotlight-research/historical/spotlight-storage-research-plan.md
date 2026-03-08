# Research Plan: Spotlight Exclusion Storage Location

**Goal:** Find the actual storage location for Spotlight Privacy exclusions on modern macOS

## Current Mystery

**Problem:** GUI shows 1 exclusion ("tmp") but `VolumeConfiguration.plist` shows empty array
**System:** macOS Sequoia 15.x
**What we know:**

- AppleScript can read "tmp" from GUI table
- `sudo mdutil -P /` shows `<array/>` for Exclusions
- File should be at `/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist`

## Search Strategy

### 1. Official Apple Documentation

**Search queries:**

- "macOS Spotlight Search Privacy site:apple.com"
- "VolumeConfiguration.plist site:developer.apple.com"
- "mdutil exclusions site:apple.com"
- "macOS Sequoia Spotlight changes site:apple.com"

**Documents to check:**

- Apple Platform Security Guide (Spotlight section)
- macOS Release Notes (Sequoia/Sonoma)
- Technical Notes (TN2092, etc.)
- Man pages: `man mdutil`, `man mdfind`, `man mdls`

### 2. Reverse Engineering Resources

**Search queries:**

- "macOS Spotlight exclusions plist location"
- "VolumeConfiguration.plist empty but GUI shows exclusions"
- "System Settings Spotlight Privacy storage"
- "macOS Sequoia Spotlight database location"
- "mds_stores exclusions storage"

**Communities:**

- Ask Different (StackExchange)
- MacRumors Forums
- MacAdmins Slack archives
- Apple Developer Forums

### 3. System File Investigation

**Files/directories to check:**

```bash
# User-level preferences
~/Library/Preferences/com.apple.Spotlight.plist
~/Library/Preferences/com.apple.spotlight.plist
~/Library/Preferences/com.apple.SystemSettings.plist
~/Library/Preferences/ByHost/com.apple.Spotlight.*.plist

# System-level preferences
/Library/Preferences/com.apple.Spotlight.plist
/Library/Preferences/.GlobalPreferences.plist

# Spotlight metadata stores
/.Spotlight-V100/
/System/Volumes/Data/.Spotlight-V100/
/private/var/db/Spotlight-V100/

# System Settings data
~/Library/Application Support/com.apple.systempreferences/
~/Library/Application Support/com.apple.Settings/
~/Library/Containers/com.apple.systempreferences/

# CoreData databases
~/Library/Application Support/com.apple.spotlight/
~/Library/Caches/com.apple.Spotlight/

# Configuration Profiles
/Library/Managed Preferences/
~/Library/Managed Preferences/
```

**Commands to try:**

```bash
# Find all files modified when adding exclusion
sudo fs_usage -f filesys | grep -i spotlight

# Find plist files with "Exclusion" or path
sudo find /System/Volumes/Data -name "*.plist" -exec grep -l "zenpayroll" {} \; 2> /dev/null

# Check all spotlight-related plists
find ~/Library/Preferences -name "*[Ss]potlight*" -exec plutil -p {} \;

# Look for TCC (privacy) databases
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT * FROM access WHERE service='kTCCServiceSystemPolicyAllFiles';"

# Check for preferences in different domains
defaults domains | tr ',' '\n' | grep -i spotlight
```

### 4. GitHub Code Search

**Search queries:**

- "VolumeConfiguration.plist" language:shell
- "mdutil exclusions" language:python
- "Spotlight Privacy" language:swift
- "com.apple.Spotlight.plist Exclusions"

**Projects to examine:**

- macOS configuration management tools (Munki, Jamf scripts)
- Privacy/security hardening scripts
- Backup/migration tools
- System profiling tools

### 5. macOS System Tracing

**Approach: Monitor what System Settings does**

```bash
# Terminal 1: Start file monitoring
sudo fs_usage -w -f filesys System\ Settings | tee spotlight-files.log

# Terminal 2: Start system call monitoring
sudo dtruss -f -p $(pgrep "System Settings") 2>&1 | tee spotlight-dtruss.log

# Terminal 3: Monitor defaults/preferences
log stream --predicate 'process == "cfprefsd"' | grep -i spotlight

# Then: Open System Settings > Spotlight > Search Privacy
# Add a test directory
# Check the logs for file writes
```

### 6. Sandbox/Container Investigation

Modern macOS apps run in containers. System Settings might store data in:

```bash
# Find System Settings containers
find ~/Library/Containers -name "*[Ss]ystem*" -o -name "*[Ss]ettings*"

# Check Group Containers
find ~/Library/Group\ Containers -name "*[Ss]potlight*"

# Application Support
find ~/Library/Application\ Support -name "*[Ss]potlight*" -o -name "*[Ss]ettings*"
```

### 7. Privacy Framework Investigation

**Search queries:**

- "macOS TCC database Spotlight"
- "Privacy framework kTCCServiceSystemPolicyAllFiles"
- "System Settings Privacy storage"

**Files to check:**

```bash
# TCC (Transparency, Consent, and Control) databases
~/Library/Application Support/com.apple.TCC/TCC.db
/Library/Application Support/com.apple.TCC/TCC.db

# Privacy settings
/var/db/tcc/TCC.db
```

### 8. Configuration Profile / MDM Investigation

**Search queries:**

- "macOS MDM Spotlight exclusions"
- "Configuration Profile Spotlight Privacy"
- "com.apple.Spotlight configuration profile"

Exclusions might be stored differently if managed via MDM.

### 9. Temporal Investigation

**Approach: Add exclusion and immediately check everything**

```bash
# Before adding exclusion
sudo mdutil -P / > before.xml
find ~/Library -name "*.plist" -newer /tmp/marker -exec echo {} \;

# Mark time
touch /tmp/marker

# Use AppleScript to add exclusion (or add manually via GUI)

# Immediately after
sudo mdutil -P / > after.xml
diff before.xml after.xml

# Find modified files
find ~/Library -newer /tmp/marker -name "*.plist"
find ~/Library -newer /tmp/marker -name "*.db"
```

### 10. Process Investigation

**Check what processes are involved:**

```bash
# List Spotlight-related processes
ps aux | grep -i spotlight
ps aux | grep -i mds

# Check open files
sudo lsof | grep -i spotlight
sudo lsof | grep VolumeConfiguration

# Check what System Settings has open
sudo lsof -p $(pgrep "System Settings") | grep -i spotlight
```

## Expected Findings

### Hypothesis 1: User-specific storage

Maybe user-added exclusions are stored per-user, not system-wide:

- `~/Library/Preferences/com.apple.Spotlight.plist`
- `~/Library/Application Support/com.apple.spotlight/`

### Hypothesis 2: Sandboxed container

System Settings might store data in its container:

- `~/Library/Containers/com.apple.systempreferences/`
- `~/Library/Group Containers/systemgroup.com.apple.configurationprofiles/`

### Hypothesis 3: Asynchronous write

The plist might update later:

- Try checking 5-10 minutes after adding exclusion
- Try closing System Settings and checking again
- Try logging out/in and checking

### Hypothesis 4: Different volume

Maybe we're checking the wrong volume's configuration:

- `/System/Volumes/Preboot/.Spotlight-V100/`
- Each APFS volume has its own config

### Hypothesis 5: New storage format in Sequoia

macOS Sequoia might have changed the storage mechanism:

- Could be in a CoreData database
- Could be in a different plist location
- Could use a new framework

## Action Items

1. [ ] Run temporal investigation (add exclusion and monitor files)
2. [ ] Search Apple documentation for recent changes
3. [ ] Check GitHub for recent scripts that successfully read exclusions
4. [ ] Monitor System Settings with fs_usage when adding exclusion
5. [ ] Check all container/sandbox directories
6. [ ] Try different volumes
7. [ ] Search for recent blog posts about macOS Sequoia Spotlight changes
8. [ ] Check if other users report this behavior on Sequoia

## Documentation to Create

Once we find the answer:

- Update `spotlight-privacy-research.md` with correct location
- Create script to reliably read exclusions
- Document any macOS version differences
- Update comparison table with "reading" capabilities
