# Prisma Patterns Skill

## When to Use

All database operations. Use Prisma directly without wrapper abstractions.

## Initialization

```typescript
import { PrismaClient } from '@prisma/client';

// Global instance for all requests
export const prisma = new PrismaClient({
  log: [
    { emit: 'event', level: 'query' },
    { emit: 'stdout', level: 'error' },
  ],
});

// Log slow queries
prisma.$on('query', (e) => {
  if (e.duration > 100) {
    logger.warn(`Slow query (${e.duration}ms): ${e.query}`);
  }
});
```

## Create

```typescript
const user = await prisma.user.create({
  data: {
    email: input.email,
    name: input.name,
    profile: {
      create: { bio: input.bio },
    },
  },
  include: { profile: true }, // Eager load related data
});
```

## Read

```typescript
// Single record
const user = await prisma.user.findUnique({ where: { email } });

// With relations
const order = await prisma.order.findUnique({
  where: { id },
  include: {
    items: { select: { productId: true, qty: true } },
    customer: { select: { email: true, name: true } },
  },
});

// List with pagination
const [users, total] = await Promise.all([
  prisma.user.findMany({
    skip: (page - 1) * limit,
    take: limit,
    orderBy: { createdAt: 'desc' },
  }),
  prisma.user.count(),
]);
```

## Update

```typescript
const user = await prisma.user.update({
  where: { id },
  data: { email: newEmail, name: newName },
});

// Conditional update
await prisma.order.updateMany({
  where: { status: 'pending', createdAt: { lt: Date.now() - 24 * 60 * 60 * 1000 } },
  data: { status: 'cancelled' },
});
```

## Delete

```typescript
const user = await prisma.user.delete({ where: { id } });

// Multiple
await prisma.order.deleteMany({
  where: { userId: id },
});
```

## Transactions

```typescript
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { email } });
  const order = await tx.order.create({
    data: { userId: user.id, items: [...] },
  });
  return { user, order };
});
```

## Avoid

- Repository pattern wrappers
- Generic CRUD classes
- Abstraction layers over Prisma

