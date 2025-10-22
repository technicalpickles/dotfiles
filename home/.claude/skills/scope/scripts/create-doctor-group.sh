#!/usr/bin/env bash
# Create a new Scope doctor group with helper scripts

set -euo pipefail

usage() {
  cat << EOF
Usage: $0 <type> <group-name>

Create a new Scope doctor group with helper scripts.

Arguments:
  type        Group type: 'application' or 'environment' or 'project'
  group-name  Descriptive name (e.g., ruby-version, colima)

Examples:
  $0 application ruby-version
  $0 environment colima
  $0 project database-setup

The script will create:
  For application/environment:
    - {config-root}/{type}/{group-name}.yaml
    - {config-root}/{type}/bin/{group-name}.sh

  For project:
    - .scope/{group-name}.yaml
    - .scope/bin/{group-name}.sh
EOF
  exit 1
}

# Check arguments
if [[ $# -ne 2 ]]; then
  usage
fi

TYPE="$1"
GROUP_NAME="$2"

# Validate type and determine base directory
case "$TYPE" in
  application | environment)
    # Try common config directory structures
    if [[ -d "config/${TYPE}" ]]; then
      BASE_DIR="config/${TYPE}"
    elif [[ -d "scope-config/${TYPE}" ]]; then
      BASE_DIR="scope-config/${TYPE}"
    elif [[ -d "${TYPE}" ]]; then
      BASE_DIR="${TYPE}"
    else
      echo "Error: Cannot find ${TYPE} directory" >&2
      echo "Run this from config root directory" >&2
      exit 1
    fi
    BIN_DIR="${BASE_DIR}/bin"
    ;;
  project)
    BASE_DIR=".scope"
    BIN_DIR="${BASE_DIR}/bin"
    ;;
  *)
    echo "Error: type must be 'application', 'environment', or 'project'" >&2
    usage
    ;;
esac

# Create directories
mkdir -p "$BASE_DIR" "$BIN_DIR"

# Create YAML file
YAML_FILE="${BASE_DIR}/${GROUP_NAME}.yaml"
if [[ -f "$YAML_FILE" ]]; then
  echo "Error: $YAML_FILE already exists" >&2
  exit 1
fi

cat > "$YAML_FILE" << EOF
apiVersion: scope.github.com/v1alpha
kind: ScopeDoctorGroup
metadata:
  name: ${GROUP_NAME}
  description: TODO: Brief description of what this group does
spec:
  include: when-required  # or 'by-default'
  needs:
    # TODO: Add dependencies here
    # - dependency-1
    # - dependency-2
  actions:
    - name: check-and-fix
      description: TODO: What this action checks/fixes
      required: true
      check:
        # Option 1: Command-based check
        commands:
          - ./bin/${GROUP_NAME}.sh check
        # Option 2: Path-based check (watches files for changes)
        # paths:
        #   - "file-to-watch.txt"
        #   - "**/*.config"
      fix:
        commands:
          - ./bin/${GROUP_NAME}.sh fix
        helpText: |
          TODO: What to do if the fix fails.

          Common issues:
          1. Issue 1 and resolution
          2. Issue 2 and resolution

          If you need assistance, contact #help-channel in Slack.
        # Optional: helpUrl: https://docs.example.com/troubleshooting
EOF

# Create helper script
SCRIPT_FILE="${BIN_DIR}/${GROUP_NAME}.sh"
if [[ -f "$SCRIPT_FILE" ]]; then
  echo "Error: $SCRIPT_FILE already exists" >&2
  exit 1
fi

cat > "$SCRIPT_FILE" << 'SCRIPTEOF'
#!/usr/bin/env bash
# Helper script for GROUP_NAME doctor group

set -euo pipefail

ACTION="${1:-}"

check() {
  # TODO: Implement check logic
  # Return 0 if check passes (nothing to fix)
  # Return non-zero if check fails (fix needed)

  echo "Checking..." >&2

  # Example: Check if a file exists
  # if [[ -f .required-file ]]; then
  #   echo "Check passed" >&2
  #   return 0
  # else
  #   echo "Check failed: .required-file missing" >&2
  #   return 1
  # fi

  echo "TODO: Implement check logic" >&2
  return 1
}

fix() {
  # TODO: Implement fix logic
  # Return 0 on success
  # Return non-zero on failure

  echo "Fixing..." >&2

  # Example: Create required file
  # touch .required-file

  echo "TODO: Implement fix logic" >&2
  return 1
}

case "$ACTION" in
  check)
    check
    ;;
  fix)
    fix
    ;;
  *)
    echo "Usage: $0 [check|fix]" >&2
    exit 1
    ;;
esac
SCRIPTEOF

# Replace GROUP_NAME placeholder
sed -i.bak "s/GROUP_NAME/${GROUP_NAME}/g" "$SCRIPT_FILE" && rm "${SCRIPT_FILE}.bak"

# Make script executable
chmod +x "$SCRIPT_FILE"

echo "Created files:"
echo "  - $YAML_FILE"
echo "  - $SCRIPT_FILE"
echo ""
echo "Next steps:"
echo "1. Edit $SCRIPT_FILE:"
echo "   - Implement check() logic"
echo "   - Implement fix() logic"
echo "2. Test script standalone:"
echo "   - $SCRIPT_FILE check"
echo "   - $SCRIPT_FILE fix"
echo "3. Edit $YAML_FILE:"
echo "   - Update description"
echo "   - Add dependencies in 'needs'"
echo "   - Adjust include mode (when-required vs by-default)"
echo "   - Update helpText"
echo "4. Test group:"
echo "   - scope doctor list | grep ${GROUP_NAME}"
echo "   - scope doctor run --only ${GROUP_NAME} --no-cache"
echo "5. Validate schema:"
echo "   - jsonschema validate schema.json $YAML_FILE"
