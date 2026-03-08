# RESOLVED: Spotlight Exclusion Storage Mystery

**Date Resolved:** 2025-10-23
**Status:** ✅ **MYSTERY SOLVED**

---

## TL;DR - The Solution

**We were checking the wrong volume!**

User data exclusions are stored on `/System/Volumes/Data`, not `/`.

```bash
# ❌ WRONG - This shows empty
sudo mdutil -P / | grep -A 10 "Exclusions"

# ✅ CORRECT - This shows our exclusion
sudo mdutil -P /System/Volumes/Data | grep -A 10 "Exclusions"
```

**Result:**

```xml
<key>Exclusions</key>
<array>
    <string>/Users/josh.nichols/workspace/zenpayroll/tmp</string>
</array>
```

---

## What We Discovered

### The Exclusion EXISTS!

After adding `/Users/josh.nichols/workspace/zenpayroll/tmp` via AppleScript:

**Data Volume (`/System/Volumes/Data`):**

```xml
<key>Exclusions</key>
<array>
    <string>/Users/josh.nichols/workspace/zenpayroll/tmp</string>  <!-- ✅ HERE IT IS! -->
</array>
```

**Root Volume (`/`):**

```xml
<key>Exclusions</key>
<array/>  <!-- Empty, as expected -->
```

### Why We Were Confused

1. We checked `sudo mdutil -P /` (root volume)
2. Root volume showed empty exclusions array
3. But user directories live on **Data volume**, not root
4. Therefore exclusions for `/Users/...` are on Data volume

---

## APFS Volume Groups Explained

Modern macOS (Catalina+) uses **APFS volume groups** with separate volumes:

### System Volume (`/`)

- **Purpose:** Operating system files
- **Characteristics:** Read-only, sealed, signed
- **Spotlight Config:** `/System/Volumes/.Spotlight-V100/` (typically empty exclusions)
- **Contains:** System files, applications

### Data Volume (`/System/Volumes/Data`)

- **Purpose:** User and mutable data
- **Characteristics:** Read-write
- **Spotlight Config:** `/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist`
- **Contains:** `/Users`, `/private/var`, application data

### Key Insight

**User home directories** like `/Users/josh.nichols/` are actually on the **Data volume**, even though they appear to be at the root when using the file system.

This is accomplished through firmlinks - the system presents them as if they're at the root, but physically they're on `/System/Volumes/Data/Users/`.

Therefore:

- Path you see: `/Users/josh.nichols/workspace/zenpayroll/tmp`
- Actual location: `/System/Volumes/Data/Users/josh.nichols/workspace/zenpayroll/tmp`
- Exclusion stored in: `/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist`

---

## Resolution of Original Questions

### Question 1: Where are exclusions stored?

**Answer:** Still in `VolumeConfiguration.plist`, but you must check the **correct volume**:

- System files: Check `/` (root)
- User files: Check `/System/Volumes/Data` (data)

### Question 2: Why was plist empty when GUI showed exclusion?

**Answer:** We were checking the **wrong volume** (`/` instead of `/System/Volumes/Data`)

- Not an asynchronous write issue (though that can happen)
- Not a persistence problem
- Simply user error in which volume to check

### Question 3: Does `.metadata_never_index` work in subdirectories?

**Answer:** **NO** - Confirmed by research, stopped working since Mojave (10.14)

### Question 4: What methods work?

**Answer:**

- ✅ `.noindex` extension (best for folders)
- ✅ System Settings GUI + AppleScript automation (works!)
- ✅ `mdutil -i off` (volumes only)
- ❌ `.metadata_never_index` in subdirectories (doesn't work)

---

## How to Properly Check Exclusions

### Corrected Command

```bash
# Check all volumes
for vol in / /System/Volumes/Data; do
  echo "=== Volume: $vol ==="
  sudo mdutil -P "$vol" | grep -A 20 "Exclusions"
  echo ""
done
```

### Expected Output

```
=== Volume: / ===
<key>Exclusions</key>
<array/>

=== Volume: /System/Volumes/Data ===
<key>Exclusions</key>
<array>
    <string>/Users/josh.nichols/workspace/zenpayroll/tmp</string>
</array>
```

### Script Created

Use `list-exclusions-CORRECTED.sh` which checks both volumes:

```bash
./scratch/list-exclusions-CORRECTED.sh
```

---

## What This Means

### AppleScript Success Confirmed

Our AppleScript automation **DID work correctly**:

1. ✅ Opened Spotlight settings
2. ✅ Clicked "Search Privacy" button
3. ✅ Clicked "Add" button
4. ✅ Navigated to directory
5. ✅ Clicked "Choose"
6. ✅ **Exclusion was written to VolumeConfiguration.plist**
7. ✅ GUI shows "tmp"
8. ✅ Config file shows full path (on correct volume!)

### No Asynchronous Write Delay

While the research mentioned async writes are possible, in our case:

- Exclusion appeared immediately in config
- No reboot needed
- No wait time needed
- Just needed to check correct volume

### System Works As Designed

Everything is working as intended:

- GUI adds exclusions correctly
- Config file stores them correctly
- AppleScript can automate the process
- Just need to know which volume to check

---

## Updated Scripts

### Working Scripts

1. **`list-exclusions-CORRECTED.sh`** - ✅ Checks both volumes
2. **`add_exclusion_optimized.scpt`** - ✅ Adds exclusions via GUI (confirmed working)
3. **`list_exclusions_v2.scpt`** - ✅ Reads from GUI (gets basename only)

### Deprecated Scripts

These check only `/` (root) and miss Data volume exclusions:

- ❌ `list-exclusions-from-config.sh` (only checks `/`)
- ❌ `list-spotlight-exclusions.sh` (only checks `/`)

---

## Key Lessons Learned

### 1. APFS Volume Groups Matter

Modern macOS isn't just one volume anymore. Always consider:

- Where does the data actually live?
- Which volume's config should I check?

### 2. User vs System Data

**Rule of thumb:**

- System paths (`/Applications`, `/System`, `/Library`) → Check `/`
- User paths (`/Users`, `/private/var`) → Check `/System/Volumes/Data`

### 3. The "Root" is Deceiving

The file system **presents a unified view** via firmlinks, but physically:

- `/Users` is a firmlink to `/System/Volumes/Data/Users`
- Spotlight configs are per-volume
- Must check the actual volume where data lives

### 4. Test Your Assumptions

We assumed:

- ❌ Exclusions would be on root volume (wrong)
- ❌ Empty array meant async write issue (wrong)
- ❌ AppleScript might not have saved (wrong)

Reality:

- ✅ Everything worked perfectly
- ✅ We just checked wrong location

---

## Updated Documentation Status

### Files to Update

1. **`spotlight-exclusion-storage-mystery.md`**

   - Status: Can be marked as RESOLVED
   - Add: "See RESOLVED-spotlight-storage-mystery.md"

2. **`RESEARCH-REQUEST-spotlight-exclusions.md`**

   - Status: Can be marked as ANSWERED
   - Add resolution to each question

3. **`applescript-spotlight-success-report.md`**

   - Status: Confirmed successful
   - Add: Config verification from correct volume

4. **`spotlight-exclusion-analysis.md`**

   - Update: Add note about checking correct volume
   - Confirm: AppleScript method works

5. **`spotlight_exclusion_storage_macOS_2025.md`**
   - Status: Mostly correct
   - Note: "Asynchronous write" possible but not required in our case

### Files to Deprecate

These scripts only check root volume:

- `list-exclusions-from-config.sh` → Use `list-exclusions-CORRECTED.sh`
- `find-spotlight-storage.sh` → No longer needed (mystery solved)

---

## Final Recommendations

### For Reading Exclusions

**Always check BOTH volumes:**

```bash
sudo mdutil -P / | grep -A 20 "Exclusions"
sudo mdutil -P /System/Volumes/Data | grep -A 20 "Exclusions"
```

Or use the corrected script:

```bash
./scratch/list-exclusions-CORRECTED.sh
```

### For Adding Exclusions

**Choose based on your needs:**

1. **AppleScript automation** (now confirmed working!)

   ```bash
   osascript scratch/add_exclusion_optimized.scpt
   ```

   - ✅ Adds to official Spotlight Privacy list
   - ✅ Shows in System Settings GUI
   - ✅ Persists in VolumeConfiguration.plist
   - ⚠️ Requires accessibility permissions
   - ⚠️ Fragile (UI-dependent)

2. **`.noindex` extension** (simplest, most reliable)

   ```bash
   mv folder folder.noindex
   ```

   - ✅ Simple and effective
   - ✅ No permissions needed
   - ✅ Works immediately
   - ❌ Changes folder name

3. **LaunchAgent system-wide disable** (current solution)
   ```bash
   # Via ADR 0008
   mdutil -a -i off
   ```
   - ✅ Already implemented
   - ✅ Disables Spotlight completely
   - ✅ No individual exclusions needed

### For `.metadata_never_index`

**Do NOT use in subdirectories:**

- ❌ Stopped working since Mojave (10.14)
- ✅ Only works at volume root
- Research confirmed this definitively

---

## Conclusion

**Mystery Status:** ✅ **FULLY RESOLVED**

The "empty exclusions array" was not a bug or timing issue—we were simply checking the wrong volume. Once we checked `/System/Volumes/Data` instead of `/`, the exclusion appeared exactly as expected.

**Key Takeaway:**

```bash
# For user directory exclusions, always check the Data volume:
sudo mdutil -P /System/Volumes/Data | grep -A 20 "Exclusions"
```

**AppleScript Success:** Fully confirmed working. The automation successfully added the exclusion, and it persists in the correct VolumeConfiguration.plist file on the Data volume.

---

**Date Resolved:** 2025-10-23
**Time to Resolution:** ~3 hours of investigation
**Root Cause:** User error (checking wrong volume)
**Lessons Learned:** APFS volume groups, firmlinks, and the importance of understanding modern macOS storage architecture
