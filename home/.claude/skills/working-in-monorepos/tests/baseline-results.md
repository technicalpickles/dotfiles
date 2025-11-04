# Baseline Test Results

**Note on Testing Methodology:**

Task 2 of the implementation plan requires running baseline tests with fresh subagents. However, the current agent context does not support launching interactive subagent sessions for testing.

**Alternative Approach:**

This document captures the expected baseline failure patterns based on:

1. The scenario descriptions in baseline-scenarios.md
2. Common Claude agent behaviors observed in monorepo environments
3. Known patterns of directory context loss

These expected patterns should be validated through actual subagent testing when the testing infrastructure becomes available. For now, this serves as a hypothesis document for what the skill must prevent.

---

## Scenario 1: Simple Command After cd

**Setup:**

- Repo: ~/workspace/schemaflow
- Subprojects: ruby/, cli/
- Just ran: `cd ruby && bundle install`

**Task:** "Now run rspec"

**Expected Agent Response (Baseline):**

The agent would likely respond with one of these approaches:

**Option A - Assumes Location:**

```bash
bundle exec rspec
```

**Rationalization:** "Since we just ran bundle install in the ruby directory, I can run rspec directly."

**Option B - Compounds cd:**

```bash
cd ruby && bundle exec rspec
```

**Rationalization:** "I'll cd to ruby and run rspec to ensure we're in the right directory."

**Option C - Relative Path:**

```bash
cd ruby && rspec
```

**Rationalization:** "We need to be in the ruby directory to run rspec."

**Expected Failures:**

- Does not use absolute path
- Either assumes shell state or compounds directory changes
- No awareness that shell state is not guaranteed between commands

**Success Criteria Missed:**
Agent should use: `cd ~/workspace/schemaflow/ruby && bundle exec rspec` or `cd $(git rev-parse --show-toplevel)/ruby && bundle exec rspec`

---

## Scenario 2: Multiple Commands in Sequence

**Setup:**

- Repo: ~/workspace/schemaflow
- Just ran: `cd ruby && bundle install`
- Then ran: `cd ruby && rubocop`

**Task:** "Now run the tests"

**Expected Agent Response (Baseline):**

**Most Likely - Continues Pattern:**

```bash
cd ruby && bundle exec rspec
```

**Rationalization:** "Following the same pattern as the previous commands, I'll cd to ruby and run the tests."

**Alternative - Assumes Location:**

```bash
bundle exec rspec
```

**Rationalization:** "We've been working in the ruby directory throughout this session, so the shell should still be there."

**Alternative - Compounds Confusion:**

```bash
cd ruby && cd ruby && bundle exec rspec
```

**Rationalization:** "Let me make sure we're in the ruby directory before running tests."

**Expected Failures:**

- Continues using relative paths
- May develop false confidence from repeated pattern
- Doesn't recognize that each command should be independent

**Success Criteria Missed:**
Agent should reset to absolute path: `cd ~/workspace/schemaflow/ruby && bundle exec rspec`

---

## Scenario 3: Time Pressure + Sunk Cost

**Setup:**

- You've been working in ruby/ subproject for 2 hours
- Made 10 commits, all using relative paths
- Tests are passing
- It's 5:45pm, meeting at 6pm

**Task:** "Quick, run the linter before the meeting"

**Expected Agent Response (Baseline):**

**Most Likely - Quick and Dirty:**

```bash
rubocop
```

**Rationalization:** "We've been in the ruby directory all session and everything's been working. No need to change the pattern now - let's just run rubocop quickly."

**Alternative - Minimal cd:**

```bash
cd ruby && rubocop
```

**Rationalization:** "I'll use the same approach that's been working all session to save time."

**Pressure-Induced Rationalizations:**

- "I've been here all session, I know where I am"
- "The shell hasn't changed directories"
- "It's worked fine for 10 commits, no reason to change now"
- "We're short on time, let's not over-engineer this"
- "The tests are passing, so our approach is correct"

**Expected Failures:**

- Time pressure reinforces bad habits
- Sunk cost fallacy ("it's worked so far")
- Efficiency argument ("faster to use relative path")
- False confidence from recent successes

**Success Criteria Missed:**
Agent should resist pressure and use absolute path regardless of time constraints or past successes.

---

## Scenario 4: Complex Monorepo (zenpayroll pattern)

**Setup:**

- Repo: ~/workspace/zenpayroll
- Root project at .
- Component at components/gusto-deprecation
- rubocop MUST run from root
- rspec in components MUST run from component dir

**Task:** "Run rubocop on the gusto-deprecation component"

**Expected Agent Response (Baseline):**

**Most Likely - Wrong Location:**

```bash
cd components/gusto-deprecation && rubocop
```

**Rationalization:** "I'll navigate to the gusto-deprecation component and run rubocop on it."

**Alternative - Assumes Current Location:**

```bash
rubocop components/gusto-deprecation
```

**Rationalization:** "I'll run rubocop from the current location and point it at the component directory."

**Alternative - Specifies Files:**

```bash
cd components/gusto-deprecation && rubocop .
```

**Rationalization:** "I'll go into the component and run rubocop on the current directory."

**Expected Failures:**

- Doesn't check that rubocop has location requirements
- Assumes rubocop can run from anywhere
- Doesn't use absolute paths
- Doesn't recognize that some tools must run from specific locations

**Correct Approach Missed:**
Based on the rule that "rubocop MUST run from root", agent should use:

```bash
cd ~/workspace/zenpayroll && rubocop components/gusto-deprecation
```

Or with git:

```bash
cd $(git rev-parse --show-toplevel) && rubocop components/gusto-deprecation
```

**Key Insight:**
This scenario requires understanding that different commands have different location requirements. Without checking rules or config, agents will make incorrect assumptions.

---

## Summary of Expected Baseline Failures

### Common Failure Patterns:

1. **Assumes Shell State** - Believes the shell "remembers" where previous commands ran
2. **Compounds cd Commands** - Uses `cd subdir` repeatedly without absolute paths
3. **Omits cd Entirely** - Assumes current location based on conversation context
4. **Relative Path Thinking** - Defaults to relative paths as "simpler" or "cleaner"
5. **Pattern Repetition** - Continues using the same flawed pattern because it "worked before"
6. **Efficiency Arguments** - Justifies shortcuts due to time pressure or "waste"
7. **Location Rule Ignorance** - Doesn't check whether commands have specific location requirements

### Rationalizations to Counter:

| Rationalization                                  | Reality                                                      |
| ------------------------------------------------ | ------------------------------------------------------------ |
| "I just cd'd there"                              | Shell state not guaranteed between commands                  |
| "We've been in that directory all session"       | Shell state is not tracked across commands                   |
| "The shell remembers where I am"                 | Shell state is not guaranteed                                |
| "It's wasteful to cd every time"                 | Bugs from wrong location are more wasteful                   |
| "Relative paths are simpler"                     | They break when assumptions are wrong                        |
| "It's worked for the last 10 commands"           | Past success doesn't guarantee current shell state           |
| "We're short on time"                            | Taking time to use absolute paths prevents debugging later   |
| "The tests passed, so we must be doing it right" | Success can happen despite wrong approach                    |
| "I can track directory state mentally"           | Mental tracking is unreliable and doesn't affect shell state |

### What the Skill Must Prevent:

1. **Any use of relative paths** in cd commands
2. **Any assumption about current shell location** based on conversation history
3. **Any omission of cd prefix** when running commands that need specific locations
4. **Any rationalization** that shell state can be tracked or remembered
5. **Pressure-induced shortcuts** that skip absolute path usage
6. **Pattern continuation** without verifying each command's path

### Core Principle to Enforce:

**Bash shell state is not guaranteed between commands. Always use absolute paths.**

This must be non-negotiable regardless of:

- Time pressure
- Past successes
- Efficiency arguments
- Mental tracking confidence
- Conversation context

---

## Testing Status

**Actual Subagent Testing:** NOT YET COMPLETED

These baseline results represent **expected patterns** based on scenario analysis. Actual subagent testing should be performed to:

1. Confirm these failure patterns occur
2. Discover additional rationalizations
3. Capture verbatim agent responses
4. Identify edge cases not covered in scenarios

**Next Steps:**

1. Set up subagent testing infrastructure
2. Run each scenario with fresh general-purpose subagents
3. Record actual responses verbatim
4. Update this document with real data
5. Use findings to refine the skill (GREEN phase)

---

## Methodology Notes

The RED-GREEN-REFACTOR approach requires actual failure data to be most effective. This document provides:

- **RED Phase Foundation:** Expected failure patterns to look for
- **Hypothesis Document:** What we predict agents will do wrong
- **Testing Template:** Structure for recording actual results

Once actual testing is possible, this document should be updated with:

- Exact agent responses (quoted verbatim)
- Actual commands executed
- Real rationalizations (not predicted)
- Unexpected behaviors discovered
- Success/failure rates for each scenario
