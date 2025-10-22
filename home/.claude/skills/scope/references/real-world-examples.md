# Real-World Scope Examples

Curated examples from production Scope configurations showing battle-tested patterns.

## Known Errors

### Docker: Colima Not Running

**File**: `known-errors/docker/default-colima-not-running.yaml`

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeKnownError
metadata:
  name: default-colima-not-running
  description: The default instance of Colima is not running
spec:
  pattern: '.colima/default/docker.sock. Is the docker daemon running?'
  help: |
    Colima is not running. Start it by:
    1. `scope doctor run --only company/docker@v1`

    If that doesn't resolve the issue, reach out to us at @team
    in the #help-channel channel in Slack for help.
  fix:
    prompt:
      text: Run scope doctor?
    commands:
      - scope doctor run --only company/docker@v1
```

**Key Patterns**:

- Uses escaped dot in path pattern: `\\.colima/`
- Provides clear escalation path
- Fix delegates to doctor group for complex multi-step resolution
- Includes Slack channel for human help

### Ruby: Gem Missing File

**File**: `known-errors/ruby/gem-missing-file.yaml`

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeKnownError
metadata:
  name: gem-missing-file
  description: A gem source file is missing, and fails to be loaded
spec:
  pattern: "/lib/ruby/([[:digit:]]\\.[[:digit:]]\\.[[:digit:]]|gems)/.* `(require|require_relative)': cannot load such file --.*/lib/ruby/gems/.*(LoadError)"
  help: |
    A gem source file is missing and fails to be loaded. The cause of this is
    unknown and still being investigated (TICKET-123).

    The solution is to reinstall the gems to fix the missing file:
    1. Run `bundle pristine`
  fix:
    prompt:
      text: Run bundle pristine?
    commands:
      - bundle pristine
```

**Key Patterns**:

- Complex regex with alternation: `([[:digit:]]\\.[[:digit:]]\\.[[:digit:]]|gems)`
- Uses character classes: `[[:digit:]]`
- Multiple escaped characters in paths
- References tracking issue in help text
- Simple, safe fix command

### Git: Cannot Lock Ref

**File**: `known-errors/git/cannot-lock-ref.yaml`

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeKnownError
metadata:
  name: cannot-lock-ref
  description: Git cannot create lock file for ref
spec:
  pattern: "error: cannot lock ref '[^']+': Unable to create '[^']+\\.lock': File exists"
  help: |
    Another git process is running or crashed leaving a lock file.

    To resolve:
    1. Check for running git processes: `ps aux | grep git`
    2. If none running, remove the lock file mentioned in the error
    3. Example: `rm .git/refs/heads/branch-name.lock`
  fix:
    prompt:
      text: This requires manual intervention. Proceed with caution?
    commands:
      - echo "Check for git processes: ps aux | grep git"
      - echo "If safe, manually remove the .lock file mentioned above"
```

**Key Patterns**:

- Uses character class negation: `[^']+` (anything except single quote)
- Escaped special characters: `\\.lock`
- Fix provides diagnostic commands rather than automated fix
- Warns user about manual intervention

### MySQL: Connection Refused

**File**: `known-errors/mysql/trilogy-connection-refused.yaml`

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeKnownError
metadata:
  name: trilogy-connection-refused
  description: MySQL connection refused, service may not be running
spec:
  pattern: "Trilogy::ConnectionRefusedError.*Connection refused - connect\\(2\\)"
  help: |
    MySQL/MariaDB is not running or not accepting connections.

    To fix:
    1. Check if service is running: `brew services list | grep mysql`
    2. Start the service: `brew services start mysql@8.0`
    3. Or run: `scope doctor run --only database`
  fix:
    prompt:
      text: Attempt to start MySQL service?
    commands:
      - brew services restart mysql@8.0
```

**Key Patterns**:

- Escaped parentheses in regex: `\\(2\\)`
- Provides multiple resolution paths
- Delegates to doctor group for comprehensive fix
- Uses `restart` instead of `start` (idempotent)

## Doctor Groups

### Ruby Version Management

**File**: `application/ruby-version.yaml`

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeDoctorGroup
metadata:
  name: ruby-version
  description: Set up Ruby with accurate version
spec:
  include: when-required
  needs:
    - ruby-manager
  actions:
    - name: .ruby-version
      description: Verify a valid .ruby-version file is present.
      check:
        commands:
          - test -s .ruby-version
      fix:
        helpText: |
          The .ruby-version file must exist and not be blank.
    - name: install
      description: Ensures correct version of ruby is installed
      check:
        paths:
          - '{{ working_dir }}/.ruby-version'
      fix:
        commands:
          - ./bin/ruby-version.sh install
    - name: verify
      description: Verify the desired ruby version and current version are the same
      check:
        commands:
          - ./bin/ruby-version.sh verify
      fix:
        helpText: |
          Something went wrong.
          The ruby version was installed, but is not the version available in your current shell.
          See error messages above for additional details and possible solutions.
```

**Key Patterns**:

- Multiple sequential actions building on each other
- First action has no fix commands, only helpText (manual intervention)
- Second action watches file changes with `paths`
- Third action validates end state
- Uses template variable: `{{ working_dir }}`
- Delegates complex logic to external script

### Colima (Docker) Setup

**File**: `environment/colima.yaml`

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeDoctorGroup
metadata:
  name: company/docker@v1
  description: Colima
spec:
  include: when-required
  needs:
    - homebrew
  actions:
    - name: install
      description: company-docker is installed
      check:
        commands:
          - ./bin/colima.sh check install
      fix:
        commands:
          - ./bin/colima.sh fix install
    - name: profile
      description: The gusto profile exists
      check:
        commands:
          - ./bin/colima.sh check profile
      fix:
        commands:
          - ./bin/colima.sh fix profile
        helpText: |-
          The ~/.colima/company.yaml file still doesn't exist after running `sudo config-management`.
          Please contact #ops-channel in slack.
    - name: running
      description: service and vm are running
      check:
        commands:
          - ./bin/colima.sh check running
      fix:
        commands:
          - ./bin/colima.sh fix running
        helpText: |-
          We were unable to start the company-docker service and/or the colima vm.
          Please review the logs.

          tail "$(brew --prefix)/var/log/service.log"

          If you are not able to resolve the issue,
          please contact #help-channel in slack.
    - name: docker-context
      description: docker context is set to gusto
      check:
        commands:
          - ./bin/colima.sh check context
      fix:
        commands:
          - ./bin/colima.sh fix context
    - name: default-service
      description: The default colima brew service is stopped
      required: false
      check:
        commands:
          - ./bin/colima.sh check default-service
      fix:
        commands:
          - ./bin/colima.sh fix default-service
    - name: default-profile
      description: The default colima profile is stopped
      required: false
      check:
        commands:
          - ./bin/colima.sh check default-profile
      fix:
        commands:
          - ./bin/colima.sh fix default-profile
```

**Key Patterns**:

- Versioned name: `company/docker@v1` (allows breaking changes)
- All actions delegate to same script with subcommands
- Mix of required and optional actions
- Complex multi-step setup
- Detailed helpText with log locations
- Shell command expansion in helpText: `$(brew --prefix)`
- Last two actions are optional cleanup (`required: false`)

### Brewfile Package Management

**File**: `application/brewfile.yaml`

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeDoctorGroup
metadata:
  name: brewfile
  description: Homebrew managed packages
spec:
  include: when-required
  needs:
    - github-cli
    - homebrew
  actions:
    - name: brew-bundle
      description: Install Homebrew packages from Brewfile
      check:
        commands:
          - ./bin/brew-bundle.sh check
      fix:
        commands:
          - ./bin/brew-bundle.sh fix
        helpText: |
          brew dependencies cannot be satisfied

          Please review the output above for errors and possible solutions.
          If you need assistance, please contact #help-channel in slack.
```

**Key Patterns**:

- Multiple dependencies ensure prerequisites installed first
- Single action with simple check/fix delegation
- Generic helpText directs to previous output
- Minimal but effective

### Version Requirements Check

**File**: `.scope/scope.yaml` (project-specific)

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeDoctorGroup
metadata:
  name: scope
spec:
  include: when-required
  needs: []
  actions:
    - name: minimum-scope-version
      description: Ensures we have at least the minimum version of scope installed
      check:
        commands:
          - ./bin/check-scope-version.sh check scope 2024.2.68
      fix:
        helpText: |
          You don't have the minimum version of scope installed.
          Check the Managed Software Center for updates.

          If that doesn't work, please contact #help-channel in slack.
    - name: minimum-gusto-scope-version
      description: Ensures we have at least the minimum version of scope installed
      check:
        commands:
          - ./bin/check-scope-version.sh check gusto 2025.05.15.0001
      fix:
        helpText: |
          You don't have the minimum version of scope_config installed.
          Check the Managed Software Center for updates.

          If that doesn't work, please contact #help-channel in slack.
```

**Key Patterns**:

- No dependencies (runs first)
- No automated fix (requires external tool)
- Passes version as argument to script
- Consistent helpText pattern across actions

### Orchestrator Pattern

**File**: `.scope/project.yaml` (project-specific)

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeDoctorGroup
metadata:
  name: project
  description: Application setup
spec:
  needs:
    - scope
    - company/environment@v1
    - brewfile
    - company/ruby@v1
    - company/javascript@v1
    - gitconfig
    - lefthook
    - db
    - rubymine
    - ruby-next
    - kafka
  actions: []
```

**Key Patterns**:

- No actions, only dependencies
- Orchestrates entire setup in correct order
- Acts as entrypoint for `scope doctor run`
- Clear dependency chain

## Report Location

**File**: `reports/report-location.yaml`

```yaml
apiVersion: scope.github.com/v1alpha
kind: ScopeReportLocation
metadata:
  name: local
spec:
  destination:
    local:
      directory: /tmp/scope-reports
  additionalData:
    pwd: pwd
    username: id -un
    ruby: which ruby
    node: which node
    nodeVersion: node -v
    scopeVersion: scope version
    configVersion: config-tool --version
```

**Key Patterns**:

- Local filesystem destination (no auth required)
- Captures environment context
- Uses simple shell commands
- Platform-specific command: `pkgutil` (macOS)
- Mix of path commands (`which`) and version commands

## Helper Script Examples

### Check/Fix Pattern

**Example**: `bin/ruby-version.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
COMMAND="${2:-}"

check_file_exists() {
  test -s .ruby-version
}

install_version() {
  local desired_version
  desired_version=$(cat .ruby-version)

  if mise which ruby &> /dev/null; then
    echo "Ruby is already available"
    return 0
  fi

  mise install ruby@"${desired_version}"
}

verify_version() {
  local desired_version current_version
  desired_version=$(cat .ruby-version)
  current_version=$(ruby --version | awk '{print $2}')

  if [[ "$desired_version" == "$current_version" ]]; then
    return 0
  else
    echo "Desired: $desired_version, Current: $current_version" >&2
    return 1
  fi
}

case "$ACTION" in
  check)
    check_file_exists
    ;;
  install)
    install_version
    ;;
  verify)
    verify_version
    ;;
  *)
    echo "Usage: $0 [check|install|verify]" >&2
    exit 1
    ;;
esac
```

**Key Patterns**:

- Supports multiple subcommands
- Extracts values from files
- Uses command substitution
- Provides clear error messages to stderr
- Returns appropriate exit codes

### Version Comparison

**Example**: `bin/check-scope-version.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
PACKAGE="${2:-}"
MIN_VERSION="${3:-}"

check_version() {
  local current_version

  case "$PACKAGE" in
    scope)
      current_version=$(scope version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
      ;;
    gusto)
      current_version=$(config-tool --version 2>&1 | awk '/version:/ {print $2}')
      ;;
    *)
      echo "Unknown package: $PACKAGE" >&2
      exit 1
      ;;
  esac

  if [[ "$(printf '%s\n' "$MIN_VERSION" "$current_version" | sort -V | head -1)" == "$MIN_VERSION" ]]; then
    echo "Version $current_version meets minimum $MIN_VERSION"
    return 0
  else
    echo "Version $current_version does not meet minimum $MIN_VERSION" >&2
    return 1
  fi
}

case "$ACTION" in
  check)
    check_version
    ;;
  *)
    echo "Usage: $0 check <package> <min-version>" >&2
    exit 1
    ;;
esac
```

**Key Patterns**:

- Semantic version comparison using `sort -V`
- Multiple package sources
- Regex extraction of version numbers
- Parameter validation

## Lessons from Production

### What Works Well

1. **Versioned group names** (`company/docker@v1`) allow non-breaking changes
2. **Orchestrator groups** with no actions simplify complex setups
3. **Optional actions** (`required: false`) for nice-to-haves
4. **Delegating to scripts** keeps YAML simple, logic testable
5. **Consistent naming** (category/tool pattern) aids discovery
6. **Rich helpText** with log locations and Slack channels
7. **Multiple fix strategies** in help text (auto, manual, escalate)

### Common Pitfalls

1. **Overly broad patterns** catch unrelated errors
2. **Missing escaping** in regex patterns
3. **Hardcoded paths** instead of variables
4. **Complex logic in YAML** instead of scripts
5. **Missing error messages** when checks fail
6. **No test files** make pattern validation harder
7. **Circular dependencies** between groups

### Scale Insights

At 70+ known errors and 30+ doctor groups:

- Categorization prevents overwhelming users
- Consistent patterns make contribution easier
- Test files are essential for maintenance
- Versioning enables evolution without breaking changes
- Clear ownership (Slack channels) reduces support burden
