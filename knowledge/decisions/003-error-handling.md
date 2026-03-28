# ADR-003: Error Handling - Custom Error Classes + Result Pattern

## Decision

Use custom Error subclasses for domain errors. Implement Result<T, E> pattern for expected failures (validation, conflicts).

## Rationale

1. **Type Safety**: Compiler ensures errors are handled
2. **Clarity**: Distinguishes exceptional vs expected failures
3. **Debugging**: Stack traces preserved, error context included
4. **Production**: Structured error responses for APIs

## Implications

- Create error hierarchy (ValidationError, NotFoundError, etc)
- Use Result pattern in service layers
- Never throw for control flow
- Always include error context

