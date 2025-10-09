# Testing LaunchAgents

Quick guide for testing your LaunchAgents before committing to them running at startup.

## Quick Test Flow

### 1. Test the Command Manually

Before creating a LaunchAgent, make sure the command works:

```bash
# Test disabling Spotlight
sudo mdutil -a -i off

# Verify it worked
sudo mdutil -a -s
```

### 2. Test with the Helper Script

```bash
# Use the test script
./LaunchAgents/test-spotlight-disable.sh
```

### 3. Validate the Plist File

```bash
# Check for syntax errors
./launchagents.sh validate com.technicalpickles.disable-spotlight
```

### 4. Load the Agent (Without Rebooting)

```bash
# This will start the agent immediately
./launchagents.sh load com.technicalpickles.disable-spotlight
```

### 5. Check if It Ran

```bash
# Check status
./launchagents.sh status com.technicalpickles.disable-spotlight

# View logs
./launchagents.sh logs com.technicalpickles.disable-spotlight

# Verify the actual result
sudo mdutil -a -s
```

### 6. Make Changes and Reload

If you need to modify the plist:

```bash
# Edit the file
vim LaunchAgents/com.technicalpickles.disable-spotlight.plist

# Reload it
./launchagents.sh reload com.technicalpickles.disable-spotlight

# Check logs again
./launchagents.sh logs com.technicalpickles.disable-spotlight
```

### 7. Test After Reboot

The final test - does it work after a full reboot?

```bash
# Reboot
sudo reboot

# After reboot, check if it worked
sudo mdutil -a -s
./launchagents.sh status com.technicalpickles.disable-spotlight
./launchagents.sh logs com.technicalpickles.disable-spotlight
```

## Common Issues

### Agent loads but command doesn't run

**Check:**

- Logs: `./launchagents.sh logs com.technicalpickles.disable-spotlight`
- Permissions: Does the command need sudo?
- Paths: Are all paths absolute?

### Sudo requires password

If the LaunchAgent can't run sudo commands without a password, you have two options:

**Option A: Configure passwordless sudo for mdutil** (recommended)

```bash
# Edit sudoers
sudo visudo

# Add this line (replace YOUR_USERNAME):
YOUR_USERNAME ALL=(ALL) NOPASSWD: /usr/bin/mdutil
```

**Option B: Use a different approach**
Instead of disabling Spotlight system-wide, exclude specific directories:

```bash
# Add .metadata_never_index files (no sudo needed)
./scratch/add-spotlight-exclusion.sh vendor
./scratch/add-spotlight-exclusion.sh node_modules
```

### Agent won't load

```bash
# Validate syntax
plutil -lint ~/Library/LaunchAgents/com.technicalpickles.disable-spotlight.plist

# Check launchd errors
log show --predicate 'subsystem == "com.apple.launchd"' --last 10m
```

### Want to disable temporarily

```bash
# Unload the agent
./launchagents.sh unload com.technicalpickles.disable-spotlight

# Re-enable Spotlight
sudo mdutil -a -i on
```

## Quick Commands Reference

```bash
# List all agents and their status
./launchagents.sh list

# Load/unload specific agent
./launchagents.sh load com.technicalpickles.disable-spotlight
./launchagents.sh unload com.technicalpickles.disable-spotlight

# Check status and logs
./launchagents.sh status com.technicalpickles.disable-spotlight
./launchagents.sh logs com.technicalpickles.disable-spotlight

# Validate plist syntax
./launchagents.sh validate com.technicalpickles.disable-spotlight

# System commands
sudo mdutil -a -s     # Check Spotlight status on all volumes
sudo mdutil -a -i off # Disable Spotlight
sudo mdutil -a -i on  # Enable Spotlight
sudo mdutil -E /      # Erase and rebuild index
```

## Debugging Tips

1. **Always check logs first:**

   ```bash
   ./launchagents.sh logs com.technicalpickles.disable-spotlight
   ```

2. **Check system logs:**

   ```bash
   log show --predicate 'eventMessage CONTAINS "disable-spotlight"' --last 30m
   ```

3. **Verify the agent is loaded:**

   ```bash
   launchctl list | grep technicalpickles
   ```

4. **Check the plist is symlinked correctly:**

   ```bash
   ls -la ~/Library/LaunchAgents/com.technicalpickles.disable-spotlight.plist
   ```

5. **Test the command in isolation:**
   ```bash
   /bin/bash -c '/usr/bin/sudo /usr/bin/mdutil -a -i off'
   ```
