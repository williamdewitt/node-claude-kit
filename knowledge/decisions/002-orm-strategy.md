# ADR-002: ORM Strategy - Prisma Primary

## Decision

Use Prisma as primary ORM. No repository abstraction layers on top of Prisma.

## Rationale

1. **Type Safety**: Generates TypeScript types automatically
2. **DX**: Excellent developer experience, migrations, seeding
3. **Performance**: Optimized queries, lazy loading support
4. **Adoption**: Industry standard, large ecosystem

## Implications

- No generic IRepository interfaces
- Direct Prisma calls in service/handler layers
- Transactions with `prisma.$transaction()`
- Migrations tracked in version control

