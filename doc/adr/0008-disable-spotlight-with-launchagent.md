# 8. Disable Spotlight with LaunchAgent

Date: 2025-10-09

## Status

Accepted

## Context and Problem Statement

Spotlight indexing on macOS consumes significant CPU and I/O resources, especially on systems with large codebases, dependency directories (node_modules, vendor), and frequent file changes. This background indexing can cause:

- High CPU usage from `mds` and `mdworker` processes
- Disk I/O spikes that slow down development tasks
- Battery drain on laptops
- System responsiveness issues during active indexing

Since I don't use Spotlight search functionality (preferring command-line tools like `fzf`, `fd`, and IDE search), the resource cost provides no benefit.

### Considered Alternatives

1. **Manual exclusion of specific directories**

   - Method: Add `.metadata_never_index` files to directories
   - Pros: Granular control, no sudo required, version-controllable
   - Cons: Requires maintenance, only works for directories you remember to exclude, doesn't reduce system-wide indexing overhead
   - Status: ⚠️ **Unverified** - Community reports exist but proper validation revealed methodological flaws (absence of evidence ≠ evidence of absence)
   - Note: Even if it works for specific directories, doesn't solve the system-wide resource consumption problem

2. **System Settings GUI**

   - Method: System Settings → Spotlight → Privacy
   - Pros: Official Apple method, simple UI
   - Cons: Not scriptable, not portable across machines, settings don't sync

3. **Disable Spotlight system-wide with one-time script**

   - Method: Add `sudo mdutil -a -i off` to `.macos` setup script
   - Pros: Simple, one file to maintain
   - Cons: Only runs during initial setup or manual execution, Spotlight can re-enable across reboots

4. **LaunchAgent to disable at startup** ⭐
   - Method: Create LaunchAgent that runs `mdutil -a -i off` at login
   - Pros: Automatic, persistent, survives reboots, version-controlled
   - Cons: Requires sudo access, adds LaunchAgent infrastructure

## Decision Outcome

Implement a LaunchAgent (`com.technicalpickles.disable-spotlight.plist`) that disables Spotlight indexing on all volumes at every login.

### Implementation Details

- Created `LaunchAgents/` directory for custom LaunchAgents
- Implemented helper script `launchagents.sh` for managing agents (load, unload, status, logs, validate)
- Updated `symlinks.sh` to automatically symlink LaunchAgents to `~/Library/LaunchAgents/`
- Documented testing procedures in `LaunchAgents/TESTING.md`
- Created comprehensive documentation in `LaunchAgents/README.md`

### Why LaunchAgent over Alternatives

1. **Automatic enforcement**: Runs at every login without manual intervention
2. **Persistent**: Spotlight can't re-enable itself between reboots
3. **Portable**: Works across all macOS machines via dotfiles
4. **Infrastructure benefit**: LaunchAgent framework can be reused for other startup tasks
5. **Testable**: Can load/unload without rebooting for testing

## Consequences

### Positive

- **Improved system performance**: No CPU/I/O consumed by Spotlight indexing
- **Better battery life**: Eliminates constant background indexing on laptops
- **Faster file operations**: No contention with `mds` processes
- **Reusable infrastructure**: LaunchAgent helper script can manage other startup tasks
- **Well-documented**: Testing and troubleshooting guides included

### Negative

- **Spotlight search disabled**: Can't use Cmd+Space to search files (mitigated: use `fzf`, `fd`, and IDE search instead)
- **Requires sudo**: LaunchAgent needs passwordless sudo for `mdutil` or manual password entry (mitigated by default user already having this setup)
- **Additional complexity**: Adds LaunchAgent management to dotfiles setup
- **Debugging**: LaunchAgent issues require checking system logs

### Maintenance

- Test after macOS updates to ensure compatibility
- Monitor logs if Spotlight re-enables (shouldn't happen, but possible)
- Can easily disable by running: `./launchagents.sh unload com.technicalpickles.disable-spotlight`

## Resources

- [LaunchAgent documentation](../../LaunchAgents/README.md)
- [Testing procedures](../../LaunchAgents/TESTING.md)
- [Test results](../../LaunchAgents/TEST-RESULTS.md)
- [Apple Developer: Creating Launch Daemons and Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

## Notes

Research into directory-level exclusion methods (`.metadata_never_index` files) revealed they are difficult to validate properly. Testing revealed methodological issues: not finding indexed files doesn't prove the marker prevented indexing (could have been that Spotlight wasn't indexing that location anyway). This is a classic "absence of evidence is not evidence of absence" problem.

Given the uncertainty around directory-level exclusions and the goal of eliminating Spotlight resource consumption entirely, the system-wide LaunchAgent approach provides a definitive solution for completely disabling an unused feature.
