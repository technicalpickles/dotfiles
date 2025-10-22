# Scope Testing Guide

Comprehensive guide for testing Scope configurations before deployment.

## Testing Philosophy

1. **Test patterns in isolation** before adding to YAML
2. **Validate schema** before testing functionality
3. **Test with real errors** using `.txt` files
4. **Test incrementally** (pattern → YAML → integration)
5. **Automate regression tests** for known errors

## Known Error Testing

### 1. Test Regex Pattern in Isolation

```bash
# Test pattern matches expected text
echo "error: cannot lock ref 'refs/heads/main'" | rg "cannot lock ref"
# Output: error: cannot lock ref 'refs/heads/main'

# Test pattern doesn't match unrelated text
echo "error: something else" | rg "cannot lock ref"
# Output: (nothing - no match)

# Test with actual error file
rg "pattern" path/to/error-output.log
```

**Common Issues**:

- Pattern too broad: matches too many things
- Pattern too specific: misses variations
- Missing escapes: special chars break regex
- Wrong quantifiers: `*` vs `+` vs `?`

### 2. Create Test File

```bash
# Create directory
mkdir -p {config-root}/known-errors/category

# Create test file with ACTUAL error output
cat > {config-root}/known-errors/category/error-name.txt << 'EOF'
[Paste actual error output here]
This should be the real error text that users see
Including all the context around it
EOF
```

**Best Practices**:

- Use real error output, not synthetic examples
- Include surrounding context (lines before/after)
- Test multiple variations if error has variants
- Keep file size reasonable (< 100 lines)

### 3. Create YAML Definition

```bash
cat > {config-root}/known-errors/category/error-name.yaml << 'EOF'
apiVersion: scope.github.com/v1alpha
kind: ScopeKnownError
metadata:
  name: error-name
  description: Brief description
spec:
  pattern: "your pattern here"
  help: |
    How to fix this error
EOF
```

### 4. Test Pattern Matching

```bash
# Test that pattern matches the test file
scope analyze logs \
  --extra-config {config-root} \
  {config-root}/known-errors/category/error-name.txt
```

**Expected Output** (pattern matches):

```
Known Error: error-name
Brief description

How to fix this error
```

**Expected Output** (pattern doesn't match):

```
No known errors found
```

### 5. Validate Schema

```bash
# Install validator
brew install sourcemeta/apps/jsonschema

# Get schema (one-time setup)
curl -o /tmp/ScopeKnownError.json \
  https://github.com/oscope-dev/scope/raw/main/scope/schema/v1alpha.com.github.scope.ScopeKnownError.json

# Validate
jsonschema validate \
  /tmp/ScopeKnownError.json \
  {config-root}/known-errors/category/error-name.yaml
```

**Expected Output** (valid):

```
ok: {config-root}/known-errors/category/error-name.yaml
```

### 6. Test in Real Scenario

```bash
# Run the actual failing command and pipe to scope
failing-command 2>&1 | scope analyze command

# Or analyze existing log file
scope analyze logs /path/to/error.log
```

## Doctor Group Testing

### 1. Test Check Script Standalone

```bash
# Create test script
cat > .scope/bin/test-check.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Your check logic here
if [[ -f .required-file ]]; then
  echo "Check passed"
  exit 0
else
  echo "Check failed: .required-file missing" >&2
  exit 1
fi
EOF

chmod +x .scope/bin/test-check.sh

# Test success case
touch .required-file
./.scope/bin/test-check.sh
echo "Exit code: $?"
# Expected: Check passed, Exit code: 0

# Test failure case
rm .required-file
./.scope/bin/test-check.sh
echo "Exit code: $?"
# Expected: Check failed: .required-file missing, Exit code: 1
```

### 2. Test Fix Script Standalone

```bash
# Create fix script
cat > .scope/bin/test-fix.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Creating .required-file..."
touch .required-file
echo "Done"
EOF

chmod +x .scope/bin/test-fix.sh

# Test fix
rm -f .required-file
./.scope/bin/test-fix.sh
ls -la .required-file
# Expected: File created
```

### 3. Create Doctor Group YAML

```bash
cat > .scope/test-group.yaml << 'EOF'
apiVersion: scope.github.com/v1alpha
kind: ScopeDoctorGroup
metadata:
  name: test-group
  description: Test group for validation
spec:
  include: when-required
  needs: []
  actions:
    - name: test-action
      description: Test action
      check:
        commands:
          - ./bin/test-check.sh
      fix:
        commands:
          - ./bin/test-fix.sh
EOF
```

### 4. Verify Group is Detected

```bash
# List all groups
scope doctor list | grep test-group

# Expected output includes:
# ScopeDoctorGroup/test-group    Test group for validation    .scope/test-group.yaml
```

### 5. Test Check-Only Mode

```bash
# Remove file to trigger check failure
rm -f .required-file

# Run in check-only mode
scope doctor run --only test-group --fix=false

# Expected: Shows check failed, but doesn't run fix
```

### 6. Test With Fix

```bash
# Remove file to trigger check failure
rm -f .required-file

# Run with fix enabled
scope doctor run --only test-group

# Expected: Check fails, fix runs, file created
ls -la .required-file
```

### 7. Test Caching

```bash
# First run (should execute check)
scope doctor run --only test-group
# Expected: Runs check and fix if needed

# Second run (should use cache if file-based)
scope doctor run --only test-group
# Expected: Skips if using path-based checks

# Force re-run
scope doctor run --only test-group --no-cache
# Expected: Runs check again
```

### 8. Test Dependencies

```bash
# Create dependency group
cat > .scope/dependency.yaml << 'EOF'
apiVersion: scope.github.com/v1alpha
kind: ScopeDoctorGroup
metadata:
  name: dependency
spec:
  include: when-required
  needs: []
  actions:
    - name: setup
      check:
        commands:
          - test -f .dependency-marker
      fix:
        commands:
          - touch .dependency-marker
EOF

# Update test group to depend on it
# Add to test-group.yaml:
# needs:
#   - dependency

# Test dependency resolution
rm -f .dependency-marker .required-file
scope doctor run --only test-group

# Expected: Runs dependency first, then test-group
ls -la .dependency-marker .required-file
```

### 9. Validate Schema

```bash
# Get schema
curl -o /tmp/ScopeDoctorGroup.json \
  https://github.com/oscope-dev/scope/raw/main/scope/schema/v1alpha.com.github.scope.ScopeDoctorGroup.json

# Validate
jsonschema validate \
  /tmp/ScopeDoctorGroup.json \
  .scope/test-group.yaml
```

## Integration Testing

### Test Complete Workflow

```bash
# 1. Clean slate
rm -rf /tmp/scope-test
mkdir -p /tmp/scope-test/.scope/bin

# 2. Create complete setup
cd /tmp/scope-test

# Create check script
cat > .scope/bin/check.sh << 'EOF'
#!/usr/bin/env bash
test -f .setup-complete
EOF
chmod +x .scope/bin/check.sh

# Create fix script
cat > .scope/bin/fix.sh << 'EOF'
#!/usr/bin/env bash
echo "Setting up..."
sleep 1
touch .setup-complete
echo "Done"
EOF
chmod +x .scope/bin/fix.sh

# Create doctor group
cat > .scope/setup.yaml << 'EOF'
apiVersion: scope.github.com/v1alpha
kind: ScopeDoctorGroup
metadata:
  name: setup
spec:
  include: by-default
  needs: []
  actions:
    - name: initialize
      description: Initialize project
      check:
        commands:
          - ./.scope/bin/check.sh
      fix:
        commands:
          - ./.scope/bin/fix.sh
        helpText: |
          Setup failed. Try running manually:
          ./.scope/bin/fix.sh
EOF

# 3. Test end-to-end
scope doctor run

# 4. Verify result
test -f .setup-complete && echo "SUCCESS" || echo "FAILED"
```

## Regression Testing

### Create Test Suite

```bash
# Create test runner
cat > test-scope.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

PASSED=0
FAILED=0

test_known_error() {
  local name=$1
  local yaml=$2
  local test_file=$3

  echo "Testing: $name"

  if scope analyze logs --extra-config {config-root} "$test_file" | grep -q "$name"; then
    echo "  ✓ Pattern matches"
    ((PASSED++))
  else
    echo "  ✗ Pattern does not match"
    ((FAILED++))
  fi
}

# Test all known errors
for yaml in {config-root}/known-errors/*/*.yaml; do
  name=$(basename "$yaml" .yaml)
  txt="${yaml%.yaml}.txt"

  if [[ -f "$txt" ]]; then
    test_known_error "$name" "$yaml" "$txt"
  fi
done

echo ""
echo "Results: $PASSED passed, $FAILED failed"

exit $FAILED
EOF

chmod +x test-scope.sh

# Run test suite
./test-scope.sh
```

### Continuous Testing

```bash
# Watch for changes and re-test
while true; do
  inotifywait -r -e modify {config-root}/
  ./test-scope.sh
done
```

## Performance Testing

### Measure Doctor Run Time

```bash
# Time complete run
time scope doctor run

# Time specific group
time scope doctor run --only group-name

# Compare cached vs uncached
time scope doctor run            # With cache
time scope doctor run --no-cache # Without cache
```

### Profile Cache Effectiveness

```bash
# First run (cold cache)
scope doctor run > /tmp/run1.log 2>&1

# Second run (warm cache)
scope doctor run > /tmp/run2.log 2>&1

# Compare
diff /tmp/run1.log /tmp/run2.log
```

## Debugging Tests

### Enable Verbose Output

```bash
# Scope doesn't have --verbose, but you can debug scripts
# Add to scripts:
set -x # Print commands before execution

# Example:
#!/usr/bin/env bash
set -euxo pipefail # Added 'x' for debug output
```

### Capture Full Output

```bash
# Capture stdout and stderr
scope doctor run --only group-name > /tmp/stdout.log 2> /tmp/stderr.log

# Capture combined
scope doctor run --only group-name &> /tmp/combined.log

# Capture and display
scope doctor run --only group-name 2>&1 | tee /tmp/output.log
```

### Test Specific Action

```bash
# Doctor groups run all actions in sequence
# To test just one action, you can run the script directly:
./.scope/bin/script.sh check
./.scope/bin/script.sh fix
```

## Common Test Scenarios

### Test: Pattern with Special Characters

```bash
# Pattern: "error: cannot lock ref 'refs/heads/main'"
# Test: Does it escape properly?

echo "error: cannot lock ref 'refs/heads/main'" > /tmp/test.txt

# This should match:
rg "cannot lock ref '[^']+'" /tmp/test.txt

# This should NOT match (missing escape):
rg "cannot lock ref 'refs/heads/main'" /tmp/test.txt # Literal string
```

### Test: Path-Based Check Triggers on Change

```bash
# Setup group with path check
cat > .scope/path-test.yaml << 'EOF'
spec:
  actions:
    - name: test
      check:
        paths:
          - config.yaml
      fix:
        commands:
          - echo "Config changed"
EOF

# First run - config doesn't exist, should trigger
scope doctor run --only path-test

# Create config
echo "version: 1" > config.yaml

# Second run - config exists, should trigger (first time seeing it)
scope doctor run --only path-test

# Third run - config unchanged, should NOT trigger
scope doctor run --only path-test

# Change config
echo "version: 2" > config.yaml

# Fourth run - config changed, should trigger
scope doctor run --only path-test
```

### Test: Dependency Order

```bash
# Create test that verifies order
cat > .scope/dep-order-test.yaml << 'EOF'
spec:
  needs:
    - first
    - second
  actions:
    - name: verify
      check:
        commands:
          - test -f .first-ran
          - test -f .second-ran
EOF

# Run and check log order
scope doctor run --only dep-order-test 2>&1 | grep -E "(first|second|verify)"
```

## Best Practices

### DO

✓ Test regex patterns with `rg` before adding to YAML
✓ Create `.txt` test files with real error output
✓ Validate schema before testing functionality
✓ Test scripts standalone before integrating
✓ Use `--no-cache` when testing changes
✓ Test both success and failure paths
✓ Test dependency resolution
✓ Keep test files small and focused
✓ Use version control to track test changes

### DON'T

✗ Skip testing regex patterns in isolation
✗ Use synthetic error examples
✗ Assume patterns work without testing
✗ Test only the happy path
✗ Forget to make scripts executable
✗ Hard-code paths in tests
✗ Test in production first
✗ Commit without validation

## Troubleshooting Tests

### Pattern doesn't match test file

```bash
# Debug steps:
# 1. Check file encoding
file -I test-file.txt

# 2. Check for hidden characters
cat -A test-file.txt

# 3. Test pattern piece by piece
rg "simple" test-file.txt
rg "simple.*pattern" test-file.txt
rg "full.*complex.*pattern" test-file.txt

# 4. Check escaping
rg "pattern with \. dot" test-file.txt
```

### Check always fails

```bash
# Debug steps:
# 1. Run script manually
./.scope/bin/check.sh
echo "Exit code: $?"

# 2. Check for syntax errors
bash -n ./.scope/bin/check.sh

# 3. Add debug output
set -x in script

# 4. Check permissions
ls -l ./.scope/bin/check.sh
```

### Fix runs but doesn't work

```bash
# Debug steps:
# 1. Check fix script exit code
./.scope/bin/fix.sh
echo "Exit code: $?"

# 2. Check what fix actually does
./.scope/bin/fix.sh
ls -la # Check if files created

# 3. Run check after fix
./.scope/bin/fix.sh && ./.scope/bin/check.sh
echo "Check exit code: $?"
```

### Cache causes issues

```bash
# Solutions:
# 1. Always use --no-cache when testing
scope doctor run --only test --no-cache

# 2. Clear cache manually (implementation-specific)
# Check scope docs for cache location

# 3. Use command-based checks instead of path-based
# Commands don't use cache
```
