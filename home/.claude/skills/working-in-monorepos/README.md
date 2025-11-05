# Working in Monorepos Skill

## Purpose

Helps Claude work effectively in monorepo environments by ensuring commands execute from correct locations using absolute paths.

## Problem Solved

Claude often loses track of directory context in monorepos, leading to:

- Redundant cd commands (`cd ruby && cd ruby`)
- Assuming current directory
- Commands executing from wrong locations

## Solution

**Core rule:** Always use absolute paths with explicit cd prefix for every command.

## Testing

Skill was developed using TDD methodology:

- RED: Baseline tests document failures without skill
- GREEN: Minimal skill addresses baseline failures
- REFACTOR: Iteratively close loopholes until bulletproof

See `tests/` directory for:

- `baseline-scenarios.md`: Test scenarios
- `baseline-results.md`: Failures without skill
- `green-results.md`: Results with skill, iteration notes

## Files

- `SKILL.md`: Main skill document
- `examples/`: Example .monorepo.json configs
- `tests/`: TDD test scenarios and results
- `scripts/monorepo-init`: Init script for config generation

## Usage

The skill activates automatically when working in monorepos. It will:

1. Check for `.monorepo.json`
2. Offer to run `~/.claude/skills/working-in-monorepos/scripts/monorepo-init` if missing
3. Enforce absolute path usage for all commands

## Related Tools

- `scripts/monorepo-init`: Auto-detect subprojects and generate config
