#!/usr/bin/env bash
# Create a new Scope known error with proper structure

set -euo pipefail

usage() {
  cat << EOF
Usage: $0 <category> <error-name>

Create a new Scope known error definition with test file.

Arguments:
  category    Error category (e.g., docker, ruby, git)
  error-name  Descriptive error name (e.g., colima-not-running)

Examples:
  $0 docker colima-not-running
  $0 ruby gem-missing-file
  $0 git cannot-lock-ref

The script will create:
  - {config-root}/known-errors/{category}/{error-name}.yaml
  - {config-root}/known-errors/{category}/{error-name}.txt

You will need to edit both files with actual content.
EOF
  exit 1
}

# Check arguments
if [[ $# -ne 2 ]]; then
  usage
fi

CATEGORY="$1"
ERROR_NAME="$2"

# Determine base directory
if [[ -d "known-errors" ]]; then
  BASE_DIR="known-errors"
elif [[ -d "config/known-errors" ]]; then
  BASE_DIR="config/known-errors"
elif [[ -d "scope-config/known-errors" ]]; then
  BASE_DIR="scope-config/known-errors"
else
  echo "Error: Cannot find known-errors directory" >&2
  echo "Run this from config root or known-errors parent directory" >&2
  exit 1
fi

# Create directory
DIR="${BASE_DIR}/${CATEGORY}"
mkdir -p "$DIR"

# Create YAML file
YAML_FILE="${DIR}/${ERROR_NAME}.yaml"
if [[ -f "$YAML_FILE" ]]; then
  echo "Error: $YAML_FILE already exists" >&2
  exit 1
fi

cat > "$YAML_FILE" << EOF
apiVersion: scope.github.com/v1alpha
kind: ScopeKnownError
metadata:
  name: ${ERROR_NAME}
  description: TODO: Brief description of what this error means
spec:
  pattern: "TODO: regex pattern to match the error"
  help: |
    TODO: Clear explanation of the issue.

    Steps to resolve:
    1. First step
    2. Second step
    3. Where to get help if needed

    If you need assistance, contact #help-channel in Slack.
  # Uncomment to add automated fix:
  # fix:
  #   prompt:
  #     text: TODO: User-friendly prompt asking permission
  #   commands:
  #     - TODO: command-to-fix
EOF

# Create test file
TXT_FILE="${DIR}/${ERROR_NAME}.txt"
cat > "$TXT_FILE" << EOF
TODO: Paste actual error output here.

This should be the real error text that users see, including:
- The error message itself
- Surrounding context (lines before/after)
- Stack traces if applicable
- Command that failed

Example:
  $ some-command that failed
  Error: something went wrong
  Details about the error here
EOF

echo "Created files:"
echo "  - $YAML_FILE"
echo "  - $TXT_FILE"
echo ""
echo "Next steps:"
echo "1. Edit $TXT_FILE with actual error output"
echo "2. Test pattern: rg 'your-pattern' $TXT_FILE"
echo "3. Edit $YAML_FILE with:"
echo "   - Proper description"
echo "   - Correct pattern"
echo "   - Clear help text"
echo "   - Optional fix commands"
echo "4. Test: scope analyze logs --extra-config ${BASE_DIR%/known-errors*} $TXT_FILE"
echo "5. Validate: jsonschema validate schema.json $YAML_FILE"
