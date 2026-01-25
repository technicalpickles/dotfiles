# Permissions Manager Skill

A Claude Code skill for analyzing, documenting, and maintaining permissions across projects.

## Purpose

This skill helps you:

- **Analyze** permissions across all projects to find patterns
- **Generate** recommendations for promoting common permissions to global
- **Document** permission changes with redacted, timestamped reports
- **Apply** changes interactively with safety checks
- **Maintain** a clean, centralized permission configuration

## Installation

This skill is part of the dotfiles repository and is automatically installed when you run `install.sh`. It will be symlinked to `~/.claude/skills/permissions-manager/`.

## Commands

### `/permissions-manager analyze`

Analyzes current permissions and generates a recommendations document.

**What it does:**
1. Runs `claude-permissions --aggregate` to gather data
2. Analyzes frequency of each permission across projects
3. Identifies dangerous wildcard patterns
4. Generates timestamped recommendations document
5. Redacts all project names and private information

**Output:**
- `doc/permissions-analysis-YYYY-MM-DD.md` (safe to commit)
- Shows high/medium frequency patterns
- Lists security concerns
- Provides specific recommendations

**Example:**
```bash
/permissions-manager analyze
```

### `/permissions-manager apply`

Interactively applies recommended permission changes.

**What it does:**
1. Shows you each recommended change
2. Asks for confirmation before applying
3. Updates permission files in `claude/`
4. Regenerates `~/.claude/settings.json`
5. Optionally runs cleanup to remove duplicates
6. Creates change summary document

**Safety features:**
- Always asks before making changes
- Shows exactly what will change
- Can skip individual changes
- Creates timestamped summary
- Suggests commit message

**Example:**
```bash
/permissions-manager apply
```

### `/permissions-manager review`

Quick review of current permission state.

**What it does:**
1. Shows current allow/ask/deny counts
2. Lists all permission files
3. Shows recent permission-related commits
4. Checks for common issues

**Example:**
```bash
/permissions-manager review
```

## Privacy & Security

### Redaction

All generated documentation is **automatically redacted** to remove:

- Project names → `Project-01`, `Project-02`, etc.
- File paths → `<project-dir>`, `<workspace>`, `<home>`
- Internal domains → `*.company.com` → `*.<internal>`
- API keys/tokens → `<REDACTED>`

This makes the documentation safe to commit to public repositories.

### Security Analysis

The skill automatically checks for:

- **Dangerous wildcards**: `rm -rf path:*` that could match multiple targets
- **Overly broad permissions**: `sudo:*` without restrictions
- **Pipe-to-shell**: `curl * | bash` in allow list
- **Missing protections**: Force-push to main/master not denied

## Workflow Example

### Initial Analysis

```bash
# In your dotfiles directory
/permissions-manager analyze
```

This creates `doc/permissions-analysis-2026-01-25.md` with recommendations.

### Review Recommendations

Open the generated file and review:
- High-frequency patterns (4+ projects)
- Medium-frequency patterns (2-3 projects)
- Security improvements needed
- Suggested deny → ask changes

### Apply Changes

```bash
/permissions-manager apply
```

You'll be asked about each change:
```
Add to permissions.shell.json:
  - Bash(sqlite3:*)
Apply this change? (yes/no/skip all): yes

Remove dangerous wildcard:
  - Bash(rm -rf build:*) → Bash(rm -rf build)
Apply this change? (yes/no/skip all): yes
```

### Verify

```bash
/permissions-manager review
```

Check that counts look reasonable and recent commit shows your changes.

### Cleanup

The skill will ask:
```
Run cleanup to remove 37 duplicate permissions from 16 projects?
(yes/no): yes
```

### Commit

The skill suggests a commit message:
```
feat(claude): consolidate permissions based on frequency analysis

Promoted 12 high-frequency permissions to global.
Removed 5 dangerous wildcards from rm commands.
Changed 3 deny rules to ask for better UX.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

## Helper Scripts

Located in `scripts/` directory:

### aggregate-permissions.sh

```bash
./scripts/aggregate-permissions.sh [output-file]
```

Runs `claude-permissions --aggregate` and saves output with stats.

### redact-projects.sh

```bash
./scripts/redact-projects.sh input-file [output-file]
```

Redacts all private information from a file. Uses project name mapping.

### analyze-wildcards.sh

```bash
./scripts/analyze-wildcards.sh [settings-file]
```

Analyzes wildcards in permissions, categorizing as dangerous/safe.

### generate-recommendations.sh

```bash
./scripts/generate-recommendations.sh aggregate-file [output-file]
```

Parses aggregated permissions and generates structured recommendations.

## Integration with Dotfiles

This skill integrates with:

- **`claude/` directory**: Permission files
- **`claudeconfig.sh`**: Settings regeneration
- **`claude-permissions`**: Analysis tool
- **`.git`**: For commit suggestions

## Configuration

The skill uses these environment variables (optional):

- `PERMISSIONS_THRESHOLD_HIGH`: Frequency for high-priority (default: 4)
- `PERMISSIONS_THRESHOLD_MEDIUM`: Frequency for medium-priority (default: 2)
- `PERMISSIONS_WORKSPACE`: Workspace directory (default: `~/workspace`)

## Best Practices

1. **Run analysis regularly**: After adding new projects or making changes
2. **Review before applying**: Not all recommendations should be followed
3. **Test after changes**: Ensure workflows still work
4. **Commit redacted docs**: They're safe for public repos
5. **Iterate**: Run cleanup periodically to stay centralized

## Troubleshooting

### "No recommendations found"

- Check if `claude-permissions` is installed
- Verify you have project-local permissions to analyze
- Try running `claude-permissions --aggregate` manually

### "Redaction failed"

- Ensure `scripts/redact-projects.sh` is executable
- Check that workspace directory exists
- Verify perl is installed

### "Apply failed"

- Check file permissions in `claude/` directory
- Ensure `claudeconfig.sh` is executable
- Verify `jq` is installed
- Check git repo is clean (no merge conflicts)

### "Settings not regenerated"

- Run `./claudeconfig.sh` manually
- Check for errors in the output
- Verify all JSON files are valid

## Examples

### Full Workflow

```bash
# 1. Analyze current state
/permissions-manager analyze
# Creates: doc/permissions-analysis-2026-01-25.md

# 2. Review the recommendations
cat doc/permissions-analysis-2026-01-25.md

# 3. Apply selected changes
/permissions-manager apply
# Interactive prompts guide you through

# 4. Verify results
/permissions-manager review

# 5. Check generated change summary
cat doc/permissions-changes-2026-01-25.md
```

### Quick Security Check

```bash
# Just check for dangerous patterns
./scripts/analyze-wildcards.sh
```

### Manual Redaction

```bash
# Redact any file
./scripts/redact-projects.sh doc/my-analysis.txt
# Creates: doc/my-analysis.txt.redacted
```

## Future Enhancements

Potential improvements:

- **Diff mode**: Show before/after side-by-side
- **Test mode**: Simulate permissions to see what would be blocked
- **Export/import**: Share permission configs between machines
- **Validation**: Detect conflicts between allow/deny
- **CI integration**: Run analysis in CI pipeline

## See Also

- [Claude Permissions Documentation](../../../claude/CLAUDE.md)
- [Permissions Analysis Template](../../../doc/claude-permissions-analysis.md)
- [Safe Patterns Guide](../../../doc/claude-permissions-safe-patterns.md)
- [Wildcard Safety](../../../doc/claude-permissions-wildcard-safety.md)

## Support

This skill is part of your personal dotfiles. For issues:

1. Check the troubleshooting section above
2. Review the generated logs
3. Test individual scripts manually
4. Check Claude Code logs: `~/.claude/logs/`

## License

Part of the dotfiles repository. Private use.
