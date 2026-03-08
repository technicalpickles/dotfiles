# ADR Directory Instructions

## Creating New ADRs

When creating new Architecture Decision Records:

1. **Use sequential numbering**: Check the highest ADR number in README.md and increment by 1
2. **Follow the naming convention**: `NNNN-kebab-case-title.md` (e.g., `0018-my-decision.md`)
3. **Use the standard format**: See existing ADRs for the template (Status, Context, Decision, Consequences sections)
4. **Update README.md**: Add a link to the new ADR in the list

### README.md Format

Each entry follows this pattern:

```markdown
- [N. title-in-kebab-case](NNNN-title-in-kebab-case.md)
```

Example:

```markdown
- [14. readopt-tmux-for-claude-code-workflows](0014-readopt-tmux-for-claude-code-workflows.md)
```

## ADR Template

```markdown
# N. Title

Date: YYYY-MM-DD

## Status

Accepted | Superseded by [ADR NNNN](NNNN-title.md) | Deprecated

## Context

What is the issue that we're seeing that is motivating this decision?

## Decision

What is the change that we're proposing and/or doing?

### Alternatives Considered (optional)

1. **Alternative name**
   - Pros: ...
   - Cons: ...
   - Rejected: reason

## Consequences

### Positive

- Benefit 1
- Benefit 2

### Negative

- Drawback 1
- Drawback 2
```

## Checklist for New ADRs

- [ ] ADR file created with correct number and naming
- [ ] Date set to today's date
- [ ] Status is "Accepted" (or appropriate status)
- [ ] Context explains the problem/motivation
- [ ] Decision clearly states what was decided
- [ ] Consequences list both positive and negative impacts
- [ ] README.md updated with link to new ADR
- [ ] Related ADRs cross-referenced if applicable
