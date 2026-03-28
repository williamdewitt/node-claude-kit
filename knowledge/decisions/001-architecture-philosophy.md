# ADR-001: Architecture Philosophy

## Decision

Embrace feature-driven (vertical slice) architecture as the default for new projects. Only recommend hexagonal or modular monolith when domain complexity or team structure demand it.

## Rationale

1. **Simplicity**: Most Node.js projects are CRUD-heavy web services
2. **Productivity**: Developers own full feature stack, fewer dependencies
3. **Flexibility**: Easy to refactor into modular monolith as complexity grows
4. **Clarity**: Clear folder structure matches business domains

## Implications

- ASK before recommending architecture (don't assume)
- Feature folders organize code vertically, not by layer
- No generic repository abstractions
- ORM used directly (Prisma)

