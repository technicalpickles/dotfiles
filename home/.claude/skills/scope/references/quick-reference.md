# Scope Quick Reference

Condensed reference for common Scope operations and patterns.

## Command Cheat Sheet

```bash
# Doctor
scope doctor run                   # Run all checks
scope doctor run --only group-name # Run specific group
scope doctor run --fix=false       # Check only
scope doctor run --no-cache        # Force re-check
scope doctor list                  # List all checks

# Analyze
scope analyze logs file.log            # Check log for errors
scope analyze command -- cmd args      # Check command output
scope analyze --extra-config dir/ file # Use extra configs

# Report
scope report ./script.sh     # Run & report script
scope report -- command args # Run & report command

# Version
scope version # Show version
```

## YAML Templates

### Known Error Template

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeKnownError
metadata:
  name: error-name
  description: What this error means
spec:
  pattern: 'regex pattern'
  help: |
    Explanation and steps to fix:
    1. First step
    2. Second step
  fix:
    prompt:
      text: Permission prompt
    commands:
      - fix-command
```

### Doctor Group Template

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeDoctorGroup
metadata:
  name: group-name
  description: What this group does
spec:
  include: when-required
  needs:
    - dependency-1
  actions:
    - name: action-name
      description: What this checks
      required: true
      check:
        paths:
          - 'file.txt'
        commands:
          - ./bin/check.sh
      fix:
        commands:
          - ./bin/fix.sh
        helpText: |
          Help if fix fails
```

### Report Location Template

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeReportLocation
metadata:
  name: location-name
spec:
  destination:
    local:
      directory: /tmp/reports
    # OR githubIssue:
    #   owner: org
    #   repo: repo
    # OR rustyPaste:
    #   url: http://localhost:8000
  additionalData:
    command1: command-to-run
```

## Regex Pattern Examples

```yaml
# Match specific version error
pattern: "ruby [0-9]+\\.[0-9]+\\.[0-9]+ is not installed"

# Match file not found
pattern: "cannot load such file -- .*/([^/]+)\\.(rb|so)"

# Match Docker daemon not running
pattern: "\\.colima/[^/]+/docker\\.sock.*Is the docker daemon running\\?"

# Match Git lock error
pattern: "Unable to create '.*\\.git/refs/heads/.*\\.lock'"

# Match DNS resolution failure
pattern: "Could not resolve host: ([a-zA-Z0-9.-]+)"

# Match permission denied
pattern: "Permission denied.*(/[^:]+)"

# Character classes
[[:digit:]]   # 0-9
[[:alpha:]]   # a-z, A-Z
[[:alnum:]]   # alphanumeric
[[:space:]]   # whitespace

# Quantifiers
*             # 0 or more
+             # 1 or more
?             # 0 or 1
{n,m}         # between n and m

# Escaping
\\.           # literal dot
\\[           # literal [
\\(           # literal (
```

## Check/Fix Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-check}"

check() {
  # Exit 0 if OK, non-zero if needs fix
  if [[ condition ]]; then
    return 0
  else
    echo "Check failed: reason" >&2
    return 1
  fi
}

fix() {
  # Perform fix, exit 0 on success
  echo "Fixing..."
  # commands
  return 0
}

case "$ACTION" in
  check) check ;;
  fix) fix ;;
  *)
    echo "Usage: $0 [check|fix]" >&2
    exit 1
    ;;
esac
```

## Common Patterns

### Version Check

```yaml
- name: min-version
  description: Check minimum version
  check:
    commands:
      - test "$(tool --version | cut -d' ' -f2)" = "1.2.3"
  fix:
    helpText: Update tool via Managed Software Center
```

### File Exists

```yaml
- name: config-exists
  description: Config file exists
  check:
    commands:
      - test -f .config
  fix:
    commands:
      - ./bin/create-config.sh
```

### Service Running

```yaml
- name: service-up
  description: Service is running
  check:
    commands:
      - pgrep -x service-name
  fix:
    commands:
      - brew services restart service-name
```

### Dependencies Installed

```yaml
- name: deps
  description: Dependencies installed
  check:
    paths:
      - package.json
      - yarn.lock
  fix:
    commands:
      - yarn install
```

### Path-Based Auto-Run

```yaml
# Runs fix when file changes
- name: auto-update
  check:
    paths:
      - config.yaml
      - '**/*.conf'
  fix:
    commands:
      - ./bin/reload.sh
```

## Validation Workflow

```bash
# 1. Create error file
mkdir -p {config-root}/known-errors/category
cat > {config-root}/known-errors/category/error.yaml << 'EOF'
apiVersion: scope.github.com/v1alpha
kind: ScopeKnownError
metadata:
  name: my-error
spec:
  pattern: "error pattern"
  help: How to fix
EOF

# 2. Create test file with actual error
cat > {config-root}/known-errors/category/error.txt << 'EOF'
Actual error output goes here
EOF

# 3. Test pattern
scope analyze logs \
  --extra-config {config-root} \
  {config-root}/known-errors/category/error.txt

# 4. Validate schema (if available)
jsonschema validate schema.json error.yaml
```

## File Organization

```
# Gusto shared configs
{config-root}/
├── application/              # App-level (ruby, node, db)
├── environment/              # System-level (homebrew, git)
├── known-errors/
│   ├── docker/
│   ├── ruby/
│   ├── git/
│   └── {category}/
│       ├── error-name.yaml
│       └── error-name.txt   # Test file
└── reports/

# Project-specific
.scope/
├── project-name.yaml         # Main orchestrator
├── db.yaml                  # Database setup
├── ruby.yaml                # Language setup
└── bin/                     # Helper scripts
    ├── check-*.sh
    └── fix-*.sh
```

## Debugging Checklist

### Known Error Not Matching

- [ ] Test regex: `echo "error" | rg "pattern"`
- [ ] Check escaping of special chars
- [ ] Verify test file has actual error
- [ ] Try broader pattern first

### Doctor Always Runs

- [ ] Check path globs match: `ls -la path/pattern`
- [ ] Verify check command exits 0: `./bin/check.sh; echo $?`
- [ ] Try `--no-cache`
- [ ] Check script is executable: `ls -l script.sh`

### Dependencies Not Working

- [ ] Run `scope doctor list` - see order
- [ ] Verify `needs` names match exactly
- [ ] Check for circular deps
- [ ] Test with `--only group-name`

### Script Issues

- [ ] Add `set -euo pipefail` to scripts
- [ ] Check relative path has `./` prefix
- [ ] Make executable: `chmod +x script.sh`
- [ ] Test standalone: `./bin/script.sh check`

## Testing Tips

```bash
# Test regex patterns
echo "error text here" | rg "pattern"

# Test check command
./bin/check.sh check
echo "Exit code: $?"

# Test doctor group in isolation
scope doctor run --only group-name --no-cache

# See what would run
scope doctor list | grep group-name

# Test with extra config
scope analyze --extra-config /path/to/config file.log

# Validate YAML syntax
yamllint file.yaml

# Check file matching
ls -la path/to/files/**/*.pattern
```

## Environment Variables

```bash
# Report authentication
SCOPE_GH_TOKEN=ghp_xxx        # GitHub PAT
SCOPE_GH_APP_ID=123           # GitHub App
SCOPE_GH_APP_KEY=/path/to/key # GitHub App key

# Template variables (in YAML)
{{ working_dir }} # Current working directory
```

## Common Gotchas

1. **Regex escaping**: Use `\\.` for literal dot, not `.`
2. **Relative paths**: Must start with `./` (relative to YAML file)
3. **Check exit codes**: 0 = pass, non-zero = needs fix
4. **Cache persistence**: Use `--no-cache` when testing
5. **Pattern specificity**: Too broad = false positives, too narrow = misses errors
6. **Script permissions**: Must be executable (`chmod +x`)
7. **YAML indentation**: Use 2 spaces, not tabs
8. **Action order**: Actions run in order defined
9. **Dependency order**: Use `scope doctor list` to verify
10. **Help text**: Use `|` for multi-line strings in YAML
