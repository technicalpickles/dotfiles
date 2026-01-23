---
name: colima-commands
description: Use when executing commands in Colima-managed VMs, especially with profiles like incus. Covers SSH syntax, command chaining, and profile handling.
---

# Colima Commands

## Overview

Colima VMs require specific syntax for remote command execution. The key insight: `colima ssh` passes arguments directly to the VM, so shell operators (`&&`, `|`, `;`) need explicit bash wrapping.

## When to Use

- Executing commands in a Colima VM
- Working with non-default profiles (e.g., `incus`, `docker`)
- Chaining multiple commands remotely
- Installing or configuring software in the VM

## Core Pattern

```bash
# Single command - works without wrapper
colima ssh -p <profile> -- <command>

# Multiple commands or shell operators - REQUIRES bash -c
colima ssh -p <profile> -- bash -c "<command1> && <command2>"
```

## Quick Reference

| Task              | Command                                                           |
| ----------------- | ----------------------------------------------------------------- |
| Single command    | `colima ssh -p incus -- uname -a`                                 |
| Multiple commands | `colima ssh -p incus -- bash -c "cmd1 && cmd2"`                   |
| Pipes             | `colima ssh -p incus -- bash -c "cat /etc/os-release \| head -5"` |
| With variables    | `colima ssh -p incus -- bash -c "export FOO=bar && echo \$FOO"`   |
| List profiles     | `colima list`                                                     |
| Check VM status   | `colima status -p <profile>`                                      |

## Common Mistakes

### Wrong: Quoting entire command string

```bash
# Fails - treats entire string as command name
colima ssh -p incus "uname -a && whoami"
# Error: No such file or directory
```

### Wrong: Shell operators without wrapper

```bash
# Fails - && interpreted by local shell, not VM
colima ssh -p incus -- uname -a && whoami
# Runs whoami locally, not in VM
```

### Correct: Explicit bash wrapper

```bash
colima ssh -p incus -- bash -c "uname -a && whoami"
```

## Testing Pattern

When working with unfamiliar Colima setups, always verify syntax first:

```bash
# Step 1: Test basic connectivity
colima ssh -p echo "test" < profile > --

# Step 2: Test command chaining
colima ssh -p bash -c "echo one && echo two" < profile > --

# Step 3: Proceed with actual commands
```

## Profile Discovery

```bash
# List all Colima instances and their profiles
colima list

# Check specific profile status
colima status -p incus

# Start a profile if stopped
colima start -p incus
```

## Escaping

Inside `bash -c "..."`, escape:

- `$` as `\$` (unless you want local expansion)
- `"` as `\"`
- Pipes `|` may need escaping depending on local shell

```bash
# Variable in VM
colima ssh -p incus -- bash -c "echo \$HOME"

# Pipe in VM
colima ssh -p incus -- bash -c "cat /etc/passwd \| grep root"
```
