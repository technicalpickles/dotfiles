---
name: working-in-scratch-areas
description: Use when creating one-off scripts, debug tools, analysis reports, or temporary documentation - ensures work is saved to persistent .scratch areas with proper documentation, organization, and executable patterns
---

# Working in Scratch Areas

## Overview

Helps Claude save one-off scripts and documents to persistent scratch areas instead of littering repositories with temporary files or using `/tmp`.

**Core principles:**

- Temporary work deserves permanent storage
- Scripts and documents should be documented, organized, and preserved
- Never use `/tmp` or project `tmp/` directories for these files
- Files belong in `.scratch/` subdirectories with context

**Announce at start:** "I'm using the working-in-scratch-areas skill."

## When to Use

Use this skill when creating:

- One-off debug scripts
- Analysis or investigation tools
- Temporary documentation or reports
- Quick test scripts
- Data extraction utilities
- Monitoring or diagnostic tools

Don't use for:

- Production code that belongs in the main codebase
- Configuration files that should be committed
- Tests that belong in the test suite
- Documentation that should be in docs/

**NEVER use `/tmp` or project `tmp/` directories.** Always use `.scratch/` for temporary work.

## Setup Workflow

### Check for Existing Scratch Area

First, check if a scratch area already exists:

```bash
test -L .scratch && echo "Scratch area exists" || echo "No scratch area"
```

If the symlink exists, verify gitignore is configured (see below), then you're ready to use it.

### Setting Up New Scratch Area

When no scratch area exists:

1. **Detect:** "I notice this repository doesn't have a scratch area set up."
2. **Offer:** "I can set one up using the setup script. This will create a persistent scratch area that survives even if the repository is moved or deleted. Would you like me to?"
3. **User accepts:** Follow setup steps below
4. **User declines:** "No problem. I can create scripts in another location if you prefer."

**Setup Steps:**

```bash
# 1. Get repo root
git rev-parse --show-toplevel
# Output: /Users/josh/workspace/some-repo

# 2. Run setup from repo root
cd /Users/josh/workspace/some-repo && ~/workspace/pickled-scratch-area/setup-scratch-area.sh

# 3. Verify gitignore (see Gitignore Setup section below)
```

**What the script does:**

- Creates `~/workspace/pickled-scratch-area/areas/{repo-name}/`
- Creates symlink `{repo-root}/.scratch` → scratch area
- Copies README template with usage guidelines
- Uses .scratch-root-exclusions for repo filtering

**Script Location:** `~/workspace/pickled-scratch-area/setup-scratch-area.sh`

### Gitignore Setup

After creating scratch area, ensure `.scratch` is gitignored:

**Preferred: Global gitignore**

```bash
# Check if globally ignored
git config --global core.excludesfile
# Verify .scratch is in that file

# If not set up, add to global gitignore
echo ".scratch" >> ~/.gitignore
git config --global core.excludesfile ~/.gitignore
```

**Alternative: Project .gitignore**

If global gitignore isn't used:

```bash
# Add to project .gitignore if not present
grep -q "^\.scratch$" .gitignore || echo ".scratch" >> .gitignore
```

**Why global is preferred:** Prevents accidental commits across all repositories.

## Subdirectory Organization

### Always Use Subdirectories

Organize scratch files into topic-specific subdirectories:

```
.scratch/
├── database-debug/
│   ├── README.md
│   ├── check-connections.sh
│   └── query-results.txt
├── performance-analysis/
│   ├── README.md
│   ├── profile-api.sh
│   └── results-2024-11-05.md
└── data-extraction/
    ├── README.md
    └── extract-users.rb
```

**Do NOT create files directly in `.scratch/` root.** Always use a subdirectory.

### Subdirectory Workflow

1. **Check for existing relevant subdirectory:**

   ```bash
   ls -la .scratch/
   ```

2. **If relevant subdirectory exists:** Ask user if it makes sense to use it:

   - "I see there's already a `.scratch/database-debug/` directory. Should I add this script there, or create a new subdirectory?"

3. **If creating new subdirectory:**

   - Use descriptive names: `database-debug`, `api-performance`, `user-data-extraction`
   - Create a README.md explaining the purpose

4. **Subdirectory README required:**
   Every subdirectory MUST have a README.md describing:
   - What kind of files are stored here
   - What problem/investigation spawned these files
   - How files relate to each other (if at all)

**Example subdirectory README:**

```markdown
# Database Connection Debugging

## Purpose

Scripts and notes for investigating database connection timeout issues reported on 2024-11-05.

## Files

- `check-connections.sh` - Monitor active connections
- `query-slow-queries.sql` - Identify slow queries
- `findings.md` - Investigation notes and conclusions

## Status

Investigation completed 2024-11-08. Issue was connection pool exhaustion.
Keeping files for reference.
```

## Script Creation Rules

When creating scripts in scratch areas, follow these mandatory rules:

### 1. Always Use Proper Shebang

Every script MUST start with `#!/usr/bin/env <command>`:

```bash
#!/usr/bin/env bash
```

```python
#!/usr/bin/env python3
```

```ruby
#!/usr/bin/env ruby
```

```javascript
#!/usr/bin/env node
```

**Why:** Enables proper allow list management and makes scripts directly executable.

### 2. Make Scripts Executable

After creating a **script** (file with shebang), use the helper script to make it executable:

```bash
~/.claude/skills/working-in-scratch-areas/scripts/make-executable .scratch/subdir/script.sh
```

**Why:**

- Allows calling scripts directly (`./script.sh`) instead of through interpreter
- Helper script gets approved once, not per-file
- Consistent executable permissions
- Validates shebang exists (prevents making non-script files executable)

**Never use `chmod +x` directly** - use the helper script instead.

**Important:** Only make script files executable (files with shebangs). Do NOT make markdown files, text files, or other non-script files executable. The helper script will reject files without shebangs.

### 3. Call Scripts Directly

When invoking scripts, use direct execution:

✅ **CORRECT:**

```bash
./.scratch/database-debug/check-connections.sh
```

❌ **WRONG:**

```bash
bash .scratch/database-debug/check-connections.sh # Don't use interpreter
ruby .scratch/data-extraction/extract-users.rb    # Don't use interpreter
```

**Why:** Direct execution respects shebang and allow list configurations.

### 4. Use Write Tool for File Creation

When creating files in scratch areas, prefer the Write tool:

✅ **CORRECT:**

```
Use Write tool to create .scratch/subdir/script.sh with content
```

❌ **WRONG:**

```bash
cat > .scratch/subdir/script.sh << 'EOF'
# content
EOF
```

**Why:** Write tool requires fewer approvals and is cleaner.

### 5. Always Include Documentation Header

Every file MUST have a documentation header explaining its purpose:

**Script header example:**

```bash
#!/usr/bin/env bash

# check-database-connections.sh
#
# Purpose: Monitor database connection pool usage
# Created: 2024-11-05
# Used for: Investigating connection timeout issues in production
#
# This script helped identify that connection pool was being exhausted
# during peak traffic. Key finding: connection cleanup wasn't happening
# in error paths.
```

**Document header example:**

```markdown
# API Performance Analysis Report

## Purpose

Analysis of API response times after v2.3.0 deployment

## Created

2024-11-05

## Usage Context

Users reported 2-3x slower response times after deploying v2.3.0.
This analysis was conducted to identify the regression.

## Key Findings

- Response times increased by 150% on average
- Root cause: New verbose logging middleware
- Each request was writing 500KB of logs
- Resolution: Disabled verbose logging in production config

## Impact

This analysis prevented a rollback and identified a simple configuration fix.
Deployment was saved by changing one config value.
```

## Git Operations

### Never Add Scratch Files to Git

When using git commands to add and commit files:

❌ **NEVER do this:**

```bash
git add .
git add -A
git add .scratch/
```

✅ **ALWAYS be explicit:**

```bash
git add specific-file.rb
git add src/components/Button.tsx
git add docs/api.md
```

**Why:** Prevents accidentally committing scratch work. Global gitignore is a safety net, but explicit adds are the first line of defense.

### Scratch Area Stays Local

- `.scratch` should be in `.gitignore` (globally preferred)
- Scratch files are never committed or pushed
- Scratch files are specific to your local investigation
- If work needs to be shared, it should be in the main codebase

## File Management Philosophy

### Never Delete - Document Instead

When a file is no longer actively needed:

❌ **DON'T:** Delete the file
✅ **DO:** Add retrospective comments explaining:

- How the file was used
- What it helped understand or accomplish
- Key findings or insights gained
- When it was last relevant

**Example retrospective header:**

```bash
#!/usr/bin/env bash

# investigate-memory-leak.sh
#
# [RESOLVED - 2024-11-08]
# This script was used to investigate memory leaks in worker processes.
#
# Original purpose: Track memory usage over time to identify leak pattern
# Key finding: Memory leak was in redis-client gem v4.2, not our code
# Resolution: Updated gem to v4.3 which fixed the issue
# Verification: Memory usage stayed stable after upgrade
#
# Keeping this script for reference in case similar issues occur with
# other background workers.
```

**Why:** Preserved scripts document your problem-solving process and findings for future reference.

## Workflow Examples

### Creating a Debug Script

1. Check if scratch area exists: `test -L .scratch`
2. If missing, offer setup
3. Check for relevant subdirectory: `ls -la .scratch/`
4. Ask if existing subdir is appropriate, or create new one
5. Create subdirectory README if new: Use Write tool
6. Create script with Write tool (include shebang + header)
7. Make executable: `~/.claude/skills/working-in-scratch-areas/scripts/make-executable .scratch/subdir/script.sh`
8. Run directly: `./.scratch/subdir/script.sh`

### Creating an Analysis Document

1. Check if scratch area exists
2. Check for relevant subdirectory
3. Ask about existing subdir or create new one
4. Create subdirectory README if new
5. Create document with Write tool (include header)
6. Document findings as you work

### Archiving a Script

When a script's purpose is complete:

1. DON'T delete it
2. Use Edit tool to add retrospective header with [RESOLVED] section
3. Document findings and resolution

## Best Practices Checklist

When creating any file in scratch area, verify:

- [ ] File is in a subdirectory, not `.scratch/` root
- [ ] Subdirectory has a README.md describing its purpose
- [ ] Checked for existing relevant subdirectory first
- [ ] Used Write tool for file creation (not cat/echo)
- [ ] Descriptive filename that indicates purpose
- [ ] Documentation header with purpose and context
- [ ] Created date in header
- [ ] Usage context documented
- [ ] `.scratch` is in gitignore (global or project)

**For script files specifically:**

- [ ] Proper shebang line (`#!/usr/bin/env <command>`)
- [ ] Made executable using helper script (verifies shebang)
- [ ] Called directly (not through interpreter like `bash` or `ruby`)

When completing work with a file:

- [ ] Add retrospective comments if no longer needed
- [ ] Document key findings
- [ ] Explain what was learned
- [ ] Note resolution if applicable
- [ ] Keep file for future reference

## Common Patterns

### Investigation Script Pattern

```bash
#!/usr/bin/env bash

# investigate-{issue}.sh
#
# Purpose: Debug {specific issue}
# Created: {date}
# Used for: {context}

set -euo pipefail

# Investigation logic here
echo "Starting investigation..."

# Document findings in comments as you discover them
```

### Data Extraction Pattern

```bash
#!/usr/bin/env bash

# extract-{data-type}.sh
#
# Purpose: Extract {specific data} for {reason}
# Created: {date}
# Used for: {context}

set -euo pipefail

# Extraction logic
# Output to .scratch/subdir/extracted-data.txt
```

### Monitoring Pattern

```bash
#!/usr/bin/env bash

# monitor-{resource}.sh
#
# Purpose: Monitor {resource} for {reason}
# Created: {date}
# Used for: {context}

set -euo pipefail

while true; do
  # Monitoring logic
  sleep 5
done
```

### Analysis Report Pattern

```markdown
# {Topic} Analysis Report

## Purpose

{What you're analyzing and why}

## Created

{Date}

## Usage Context

{Why this analysis was needed}

## Methodology

{How you approached the analysis}

## Findings

{What you discovered}

## Conclusions

{What this means}

## Next Steps / Impact

{What actions were taken based on this}
```

## Benefits

- **Centralized storage:** All temporary work in one location
- **Repository isolation:** Each repo has its own subdirectory
- **Easy access:** Symlink makes scratch area accessible from repo root
- **Persistent history:** Files remain even if repository is moved/deleted
- **Knowledge preservation:** Comments document learnings and process
- **Better security:** Proper shebangs enable better allow list management
- **Future reference:** Preserved scripts serve as examples and documentation
- **Organized:** Subdirectories group related work together
- **Git-safe:** Global gitignore prevents accidental commits

## Terminology

For consistency:

- **`.scratch`** - The symlink in repository root (e.g., `./.scratch/`)
- **`scratch area`** - The concept of a dedicated space for temporary work
- **`scratch areas`** - The overall system of centralized scratch directories
- **`pickled-scratch-area`** - The central repository managing all scratch areas

## Quick Reference

| Task                    | Command                                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------------------ |
| Check if scratch exists | `test -L .scratch && echo "exists" \|\| echo "missing"`                                          |
| Setup scratch area      | Get repo root, then `cd /path/to/repo && ~/workspace/pickled-scratch-area/setup-scratch-area.sh` |
| Check gitignore         | `git config --global core.excludesfile` or `grep .scratch .gitignore`                            |
| List subdirectories     | `ls -la .scratch/`                                                                               |
| Create subdirectory     | Use Write tool to create `.scratch/subdir-name/README.md`                                        |
| Create script           | Write tool with shebang + header                                                                 |
| Make executable         | `~/.claude/skills/working-in-scratch-areas/scripts/make-executable .scratch/subdir/script.sh`    |
| Run script              | `./.scratch/subdir/script-name.sh` (not `bash .scratch/...`)                                     |
| Archive script          | Add `[RESOLVED]` retrospective header, don't delete                                              |
| Git add files           | ALWAYS use explicit paths, NEVER `git add .` or `git add -A`                                     |

## Remember

- Temporary work deserves permanent storage
- Never use `/tmp` or project `tmp/` - always use `.scratch/`
- Always organize into subdirectories with README files
- Check for existing relevant subdirectories first
- Every script needs a shebang
- Every file needs documentation
- Use Write tool for file creation
- Use helper script to make files executable
- Call scripts directly, not through interpreter
- Never add `.scratch/` files to git
- Never delete - add retrospective comments instead
