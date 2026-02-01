# QMD Refresh LaunchAgent Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a LaunchAgent to dotfiles that automatically refreshes the QMD semantic search index hourly.

**Architecture:** Create a plist file in `LaunchAgents/`, document it in README, remove the existing manually-created agent, then install via dotfiles symlink infrastructure.

**Tech Stack:** macOS launchd, bash, QMD (bun-based semantic search tool)

---

## Background

QMD provides semantic search for the Obsidian vault (`pickled-knowledge`). Unlike `grepai` which has a watch daemon, QMD requires manual `qmd update && qmd embed` to refresh the index.

A LaunchAgent was manually created at `~/Library/LaunchAgents/com.qmd.refresh.plist` that runs hourly. This plan integrates it into dotfiles for proper management.

**Current State:**

- QMD collection: `second-brain` pointing to `~/Vaults/pickled-knowledge/pickled-knowledge`
- Index location: `~/.cache/qmd/index.sqlite`
- Refresh time: ~3-9 seconds for 5000+ files
- Schedule: Hourly at minute 0

---

### Task 1: Create LaunchAgent plist

**Files:**

- Create: `LaunchAgents/com.technicalpickles.qmd-refresh.plist`

**Step 1: Create the plist file**

Create `LaunchAgents/com.technicalpickles.qmd-refresh.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.technicalpickles.qmd-refresh</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>$HOME/.bun/bin/qmd update &amp;&amp; $HOME/.bun/bin/qmd embed</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/com.technicalpickles.qmd-refresh.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/com.technicalpickles.qmd-refresh.err</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

**Step 2: Verify XML syntax**

Run: `plutil -lint LaunchAgents/com.technicalpickles.qmd-refresh.plist`

Expected: `LaunchAgents/com.technicalpickles.qmd-refresh.plist: OK`

**Step 3: Commit**

```bash
git add LaunchAgents/com.technicalpickles.qmd-refresh.plist
git commit -m "feat(launchagents): add QMD refresh plist"
```

---

### Task 2: Update LaunchAgents README

**Files:**

- Modify: `LaunchAgents/README.md` (add new section under "Available Agents")

**Step 1: Add documentation for the new agent**

Add to `LaunchAgents/README.md` under the "Available Agents" section:

```markdown
### `com.technicalpickles.qmd-refresh.plist`

Refreshes QMD semantic search index for the Obsidian vault.

**What it does:**

- Runs `qmd update && qmd embed` to refresh text and vector indexes
- Runs hourly at minute 0
- Logs to `/tmp/com.technicalpickles.qmd-refresh.{out,err}`

**Prerequisites:**

- QMD installed: `bun install -g https://github.com/tobi/qmd`
- Collection configured: `qmd collection add ~/Vaults/pickled-knowledge/pickled-knowledge --name second-brain`
```

**Step 2: Commit**

```bash
git add LaunchAgents/README.md
git commit -m "docs(launchagents): document QMD refresh agent"
```

---

### Task 3: Remove existing manual agent

**Step 1: Unload the existing agent**

Run: `launchctl bootout gui/$(id -u)/com.qmd.refresh 2>/dev/null || echo "Agent not loaded (OK)"`

Expected: No output (success) or "Agent not loaded (OK)"

**Step 2: Remove the manual plist file**

Run: `rm -f ~/Library/LaunchAgents/com.qmd.refresh.plist`

**Step 3: Verify removal**

Run: `ls ~/Library/LaunchAgents/com.qmd.refresh.plist 2>&1`

Expected: `ls: /Users/.../com.qmd.refresh.plist: No such file or directory`

---

### Task 4: Install and verify new agent

**Step 1: Run symlinks to link the new plist**

Run: `./symlinks.sh`

Expected: Output showing LaunchAgents symlink created

**Step 2: Verify symlink exists**

Run: `ls -la ~/Library/LaunchAgents/com.technicalpickles.qmd-refresh.plist`

Expected: Symlink pointing to dotfiles `LaunchAgents/` directory

**Step 3: Load the agent**

Run: `./launchagents.sh load com.technicalpickles.qmd-refresh`

Expected: Agent loads without error

**Step 4: Verify agent is loaded**

Run: `./launchagents.sh status com.technicalpickles.qmd-refresh`

Expected: Shows agent status (should be loaded, waiting for schedule)

**Step 5: Test manual trigger**

Run: `launchctl kickstart gui/$(id -u)/com.technicalpickles.qmd-refresh`

Expected: No error output

**Step 6: Verify execution succeeded**

Run: `cat /tmp/com.technicalpickles.qmd-refresh.out`

Expected: QMD output showing files updated and embeddings refreshed

**Step 7: Check for errors**

Run: `cat /tmp/com.technicalpickles.qmd-refresh.err`

Expected: Empty or no file (no errors)

---

## Design Notes

- Uses `$HOME` instead of hardcoded path for portability
- No `RunAtLoad` since index is persistent and hourly refresh is sufficient
- Index survives restarts - only needs periodic refresh for new/changed files
- Logs to `/tmp/` for easy debugging without cluttering home directory
