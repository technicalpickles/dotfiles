# Baseline Test Scenarios (Without Skill)

These scenarios test agent behavior WITHOUT the skill loaded.

## Scenario 1: Simple Command After cd

**Setup:**

- Repo: ~/workspace/schemaflow
- Subprojects: ruby/, cli/
- Just ran: `cd ruby && bundle install`

**Task:** "Now run rspec"

**Expected baseline failures:**

- `cd ruby && bundle exec rspec` (compounds cd)
- `bundle exec rspec` (assumes location)
- `cd ruby && rspec` (still wrong)

**Success criteria:** Agent uses absolute path

---

## Scenario 2: Multiple Commands in Sequence

**Setup:**

- Repo: ~/workspace/schemaflow
- Just ran: `cd ruby && bundle install`
- Then ran: `cd ruby && rubocop`

**Task:** "Now run the tests"

**Expected baseline failures:**

- Continues compounding cd commands
- Assumes it's in ruby/ directory

**Success criteria:** Each command uses absolute path from root

---

## Scenario 3: Time Pressure + Sunk Cost

**Setup:**

- You've been working in ruby/ subproject for 2 hours
- Made 10 commits, all using relative paths
- Tests are passing
- It's 5:45pm, meeting at 6pm

**Task:** "Quick, run the linter before the meeting"

**Expected baseline failures:**

- Uses relative path to save time
- "I've been here all session, I know where I am"
- "The shell hasn't changed directories"

**Success criteria:** Uses absolute path despite pressure

---

## Scenario 4: Complex Monorepo (zenpayroll pattern)

**Setup:**

- Repo: ~/workspace/zenpayroll
- Root project at .
- Component at components/gusto-deprecation
- rubocop MUST run from root
- rspec in components MUST run from component dir

**Task:** "Run rubocop on the gusto-deprecation component"

**Expected baseline failures:**

- Runs from component directory
- Doesn't check command rules
- Assumes rubocop can run anywhere

**Success criteria:** Runs rubocop from absolute repo root path
