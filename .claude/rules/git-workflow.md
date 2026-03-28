# Git Workflow Rule

## Enforcement

Use conventional commits. Make atomic commits. Never force-push to main. Squash feature branches before merge. Keep commit history clean.

## Conventional Commits

Format: `type(scope): description`

**BAD** - Unclear commit messages
```
fixed stuff
update code
working on feature
bump version
```

**GOOD** - Conventional commits
```
feat(orders): add order pagination to list endpoint
fix(orders): prevent duplicate order creation
refactor(db): extract query builder into shared module
test(orders): add integration tests for order service
chore: upgrade TypeScript to 5.3
docs: add API versioning guide
```

Types:
- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code reorganization without behavior change
- `test` - Add or update tests
- `docs` - Documentation changes
- `chore` - Build, dependencies, tooling
- `perf` - Performance improvement

## Atomic Commits

Each commit should be logically complete and independently valuable:

**BAD** - Mixed concerns in one commit
```
feat(orders): 
- Add pagination to orders list
- Update order status enum values
- Fix unrelated bug in product service
- Update dependencies
```

**GOOD** - Separate logical concerns
```
1. feat(orders): add pagination to list endpoint
2. refactor(orders): update status enum values
3. fix(products): prevent product name override
4. chore: update dependencies to latest versions
```

## Commit Scopes

Scopes should map to your module/feature structure:

```
feat(auth): implement JWT token refresh
fix(orders): calculate tax correctly
refactor(db): extract connection pooling
test(users): add password validation tests
```

## Squash Before Merge

Squash feature branch commits to keep main history clean:

```bash
# Before merge to main
git rebase -i main

# Mark commits as 'squash' (or 's') to combine
# Result: one clean feature commit
```

## Never Force-Push Main

**BAD** - Destructive operations
```bash
git push --force origin main      # NEVER
git reset --hard HEAD~5           # NEVER
git rebase -i origin/main         # Risky on shared branch
```

**GOOD** - Safe workflow
```bash
git push origin feature/my-feature
# Create PR, get review
git merge --squash feature/my-feature
git push origin main
```

## Branch Naming

Use descriptive, hierarchical names:

```
feature/add-order-pagination
fix/orders-duplicate-prevention
refactor/extract-query-builder
docs/api-versioning-guide
```

## PR Discipline

```
Title: Concise description

Description:
- What problem does this solve?
- How does it solve it?
- Are there trade-offs?

Testing:
- [ ] Unit tests added
- [ ] Integration tests added
- [ ] Manual testing on [environment]

Related to issue #123
```

## Revert Policy

If you need to undo a commit:

```bash
# Instead of reset
git revert <commit-hash>

# This creates a new commit that undoes the changes
# Safe for shared history
```

## Local vs Remote

Push early, push often to remote:

```bash
git push origin feature/my-feature

# Don't accumulate unpushed commits
# Makes collaboration and backup safe
```

