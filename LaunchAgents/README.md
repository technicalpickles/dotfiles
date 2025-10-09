# LaunchAgents

Custom LaunchAgents for macOS startup tasks.

## What are LaunchAgents?

LaunchAgents are macOS's native way to run programs automatically at login or on a schedule. They're managed by `launchd`, the system service manager.

**LaunchAgents vs LaunchDaemons:**

- **LaunchAgents** (`~/Library/LaunchAgents/`): Run in user context, start at login
- **LaunchDaemons** (`/Library/LaunchDaemons/`): Run as root, start at system boot

## Available Agents

### `com.technicalpickles.disable-spotlight.plist`

Disables Spotlight indexing on all volumes at startup.

**What it does:**

- Runs `mdutil -a -i off` to disable Spotlight indexing
- Logs output to system logs and `/tmp/` files
- Runs once at login (doesn't stay resident)

**Note:** This requires sudo privileges. You may need to configure passwordless sudo for mdutil, or Spotlight will re-enable on reboot.

## Setup

The `install.sh` script automatically symlinks all `.plist` files from this directory to `~/Library/LaunchAgents/`.

Manual installation:

```bash
# Link the agents
./symlinks.sh

# Load the agent (test without reboot)
./launchagents.sh load com.technicalpickles.disable-spotlight

# Check status
./launchagents.sh status com.technicalpickles.disable-spotlight

# Unload if needed
./launchagents.sh unload com.technicalpickles.disable-spotlight
```

## Testing

Before committing to a LaunchAgent:

1. **Test the command manually:**

   ```bash
   sudo mdutil -a -i off
   sudo mdutil -a -s # Verify it's off
   ```

2. **Load the agent without reboot:**

   ```bash
   ./launchagents.sh load com.technicalpickles.disable-spotlight
   ```

3. **Check the logs:**

   ```bash
   ./launchagents.sh logs com.technicalpickles.disable-spotlight
   
   # Or manually:
   cat /tmp/com.technicalpickles.disable-spotlight.out
   cat /tmp/com.technicalpickles.disable-spotlight.err
   tail -f /var/log/system.log | grep disable-spotlight
   ```

4. **Verify it ran:**

   ```bash
   ./launchagents.sh status com.technicalpickles.disable-spotlight
   ```

5. **Test a full reboot:**
   ```bash
   # After reboot, check if Spotlight is still disabled
   sudo mdutil -a -s
   ```

## Troubleshooting

### Agent isn't loading

```bash
# Check for errors in the plist file
plutil -lint ~/Library/LaunchAgents/com.technicalpickles.disable-spotlight.plist

# Check launchd logs
log show --predicate 'subsystem == "com.apple.launchd"' --last 30m
```

### Sudo password required

LaunchAgents run without a terminal, so interactive sudo won't work. Options:

1. **Configure sudoers (recommended for specific commands):**

   ```bash
   # Edit sudoers file
   sudo visudo

   # Add this line (replace YOUR_USERNAME):
   YOUR_USERNAME ALL=(ALL) NOPASSWD: /usr/bin/mdutil
   ```

2. **Use System Integrity Protection (SIP) settings** (not recommended)

3. **Alternative: Use System Settings** instead of LaunchAgent:
   - System Settings → Siri & Spotlight → Spotlight Privacy
   - Add volumes/directories to exclude

### Command runs but doesn't work

Check:

- Full paths are used (no relative paths or aliases)
- Environment variables are set explicitly (PATH isn't inherited)
- Log files for errors

### Want to disable an agent

```bash
./launchagents.sh unload com.technicalpickles.disable-spotlight
# Or delete the symlink:
rm ~/Library/LaunchAgents/com.technicalpickles.disable-spotlight.plist
```

## Creating New Agents

1. **Create a plist file** in this directory following the naming convention:

   ```
   com.technicalpickles.{descriptive-name}.plist
   ```

2. **Use absolute paths** for all commands and files

3. **Set logging paths** for debugging:

   ```xml
   <key>StandardOutPath</key>
   <string>/tmp/com.technicalpickles.{name}.out</string>
   <key>StandardErrorPath</key>
   <string>/tmp/com.technicalpickles.{name}.err</string>
   ```

4. **Test thoroughly** before committing:

   - Validate plist syntax: `plutil -lint your-file.plist`
   - Load and test: `./launchagents.sh load {name}`
   - Check logs after loading
   - Test after a full reboot

5. **Document it** in this README

## Key Properties Reference

| Property                | Description           | Common Values               |
| ----------------------- | --------------------- | --------------------------- |
| `Label`                 | Unique identifier     | `com.technicalpickles.name` |
| `ProgramArguments`      | Command to run        | Array of command + args     |
| `RunAtLoad`             | Run at startup        | `true`/`false`              |
| `KeepAlive`             | Keep running          | `true`/`false`              |
| `StartInterval`         | Run every N seconds   | Integer (seconds)           |
| `StartCalendarInterval` | Run at specific times | Dict with time fields       |
| `StandardOutPath`       | Stdout log location   | Path string                 |
| `StandardErrorPath`     | Stderr log location   | Path string                 |
| `WorkingDirectory`      | Working directory     | Path string                 |
| `EnvironmentVariables`  | Set environment vars  | Dict of key/value pairs     |

## Resources

- [launchd.info](https://www.launchd.info/) - Comprehensive guide
- [Apple Developer: Creating Launch Daemons and Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
- [launchctl man page](https://ss64.com/osx/launchctl.html)
