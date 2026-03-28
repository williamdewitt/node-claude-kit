# Workflow Mastery: Efficient Development Practices

Systematic approaches to planning, building, testing, and shipping features effectively with Claude Code.

## The Development Cycle

```
Planning → Implementation → Testing → Shipping → Iteration
```

### 1. Planning Phase (5-10 minutes)

**Before coding, understand the problem:**

- [ ] Read requirements carefully
- [ ] Identify existing patterns to match
- [ ] List affected files/modules
- [ ] Define acceptance criteria
- [ ] Consider edge cases

```typescript
// BAD: Start coding immediately
// GOOD: Plan first
// Q: Where does this feature live?
// Q: What existing patterns should I match?
// Q: What files will change?
// Q: What are the edge cases?
```

### 2. Implementation Phase (30-90 minutes)

**Write code intentionally:**

- [ ] Match existing patterns exactly
- [ ] Handle errors explicitly
- [ ] Add logging for debugging
- [ ] Type everything strictly
- [ ] Don't skip tests

```bash
# Typical order of work:
1. Create types/schemas (defines contract)
2. Implement core logic
3. Add error handling
4. Write tests
5. Add logging
6. Polish and document
```

### 3. Testing Phase (15-30 minutes)

**Verify behavior at multiple levels:**

```typescript
// Unit: Test individual functions
describe('createUser', () => {
  it('creates user in database', async () => {
    // Test the business logic
  });
});

// Integration: Test with real database
describe('POST /users', () => {
  it('returns 201 with user data', async () => {
    // Test the full request/response cycle
  });
});

// E2E: Test user journeys
test('user can sign up and create post', async ({ page }) => {
  // Test complete feature
});
```

### 4. Shipping Phase (5-10 minutes)

**Get code reviewed and merged:**

- [ ] Self-review: Does this match the plan?
- [ ] Run tests: All passing?
- [ ] Check linting: No style issues?
- [ ] Verify deployment: Works in staging?

### 5. Iteration Phase (Continuous)

**Learn from what you built:**

- [ ] Did this solve the problem?
- [ ] What was harder than expected?
- [ ] What would you do differently?
- [ ] Update CLAUDE.md with learnings

## Time Management Patterns

### The 90-Minute Deep Work Session

```
0-10 min:  Planning & context-building
10-75 min: Implementation & testing
75-90 min: Polish & documentation
```

### Breaking Down Large Features

**Don't attempt 500-LOC features in one session.** Break into:

1. **Foundation** (Database schema, core types)
2. **Core API** (Main endpoint, business logic)
3. **Validation & Errors** (Input validation, error handling)
4. **Testing** (Unit, integration, E2E)
5. **Polish** (Logging, documentation, optimization)

Commit after each phase.

## Common Bottlenecks

### Unclear Requirements
```
BEFORE: "Build a user profile"
AFTER: "Create /api/users/:id endpoint that returns:
        - name, email, avatar, postCount
        - Accessible to user and admins only
        - Return 404 if user not found"
```

### Over-Engineering
```
❌ "I'll build a generic repository pattern"
✅ "I'll query the database with Prisma directly"
```

### Missing Tests
```
❌ "I'll test manually in Postman"
✅ "Write integration test that verifies the happy path"
```

### No Error Handling
```
❌ "It usually works"
✅ "Handle missing user, invalid input, database errors"
```

## Decision Checklist

**Before committing code, verify:**

- [ ] Code matches existing patterns
- [ ] All error cases handled
- [ ] Tests pass (unit + integration)
- [ ] No console.log left behind
- [ ] TypeScript strict mode passes
- [ ] Commit message is clear
- [ ] Related documentation updated

## Code Review Checklist

**What to look for when reviewing own work:**

1. **Correctness**: Does it do what was requested?
2. **Completeness**: All edge cases handled?
3. **Consistency**: Matches existing code style?
4. **Clarity**: Would another developer understand it?
5. **Performance**: Any obvious inefficiencies?
6. **Security**: Any secrets in code? SQL injection?
7. **Testing**: Adequate test coverage?

## Learning from Mistakes

**Keep a learning log:**

```markdown
# What I Learned This Week

- [x] Feature X took 2x longer because I skipped planning
- [x] Validation error on line Y could have been caught with a test
- [x] Pattern Z from feature A should be reused in feature B

# Next Time
- Plan for 10 minutes before coding
- Write tests alongside implementation
- Check for similar features before starting
```

## Collaboration Patterns

### Pair Programming
- One person drives (types)
- Other person navigates (thinks ahead)
- Switch every 30 minutes

### Code Review
- Submit small PRs (< 400 LOC)
- Include context in description
- Be specific about what changed and why

### Async Work
- Document decisions in ADRs
- Comment on reasoning in code
- Update CLAUDE.md with patterns

## Tools and Commands

```bash
# Quick test
npm test -- --watch

# Type check
npm run type-check

# Lint and format
npm run lint:fix

# Build and verify
npm run build

# Run in dev
npm run dev

# Database migrations
npx prisma migrate dev
```

## When You Get Stuck

**Use this decision tree:**

```
Did you understand the problem?
├─ No → Re-read requirements, ask questions
└─ Yes
   ├─ Is the code compiling?
   │  ├─ No → Fix type errors first
   │  └─ Yes → Is the test passing?
   │     ├─ No → Debug test assertions
   │     └─ Yes → Are you happy with the code?
   │        ├─ No → Refactor
   │        └─ Yes → Commit!
```

## Productivity Tips

1. **Time-box exploration**: Max 15 minutes investigating before asking
2. **Single focus**: Don't refactor while implementing
3. **Commit often**: Small, logical commits
4. **Test as you go**: Write test, implement, see pass
5. **Document unknowns**: "TODO: fix this" doesn't help
6. **Talk to yourself**: Explain code out loud while writing
7. **Take breaks**: 5-minute break every 30 minutes

## Anti-Patterns

```typescript
// ❌ Building in the dark
// Start coding without understanding requirements

// ❌ Premature optimization
// Optimize before profiling shows bottleneck

// ❌ Solo debugging
// Stare at code for 30 minutes—ask for help after 10

// ❌ Testing after writing all code
// Test as you implement

// ❌ Ignoring warnings
// Fix warnings immediately—they become bugs

// ❌ Over-commenting obvious code
// Code should be clear; comments explain why
```

## Example Efficient Session

**Goal**: Add email verification to signup

**Time breakdown:**
- 0-5 min: Review requirements, check for similar features
- 5-30 min: Add schema, create endpoint, basic validation
- 30-50 min: Add email sending with circuit breaker
- 50-70 min: Write integration test + E2E test
- 70-85 min: Error handling, logging, documentation
- 85-90 min: Code review self-check, commit, deploy to staging

**Result**: Complete feature, tested, documented, ready to ship

## Key Principle

> Speed comes from clarity, not from rushing.
>
> Plan thoroughly → implement with confidence → test thoroughly → ship fearlessly.
