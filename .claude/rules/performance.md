# Performance Rule

## Enforcement

Use connection pooling. Lazy load relationships. Implement caching for read-heavy operations. Prevent N+1 queries. Monitor query performance.

## Connection Pooling

**BAD** - New connection per request
```typescript
const user = await new PrismaClient().user.findUnique({ where: { id } });
```

**GOOD** - Reuse connection pool
```typescript
// Global instance
export const prisma = new PrismaClient({
  connectionLimit: 5, // Pool size
});

// All requests use same pool
const user = await prisma.user.findUnique({ where: { id } });
```

## Lazy Loading Prevents N+1

**BAD** - N+1 query problem
```typescript
const users = await db.user.findMany(); // 1 query
for (const user of users) {
  const orders = await db.order.findMany({ where: { userId: user.id } }); // N queries
}
```

**GOOD** - Eager loading with include/select
```typescript
const users = await db.user.findMany({
  include: { orders: true }, // Single query with join
});

for (const user of users) {
  const orders = user.orders; // Already loaded
}
```

## Pagination for Large Result Sets

**BAD** - Returns all rows
```typescript
const users = await db.user.findMany();
```

**GOOD** - Paginated with skip/take
```typescript
const page = parseInt(req.query.page || '1');
const pageSize = 20;

const [users, total] = await Promise.all([
  db.user.findMany({
    skip: (page - 1) * pageSize,
    take: pageSize,
    orderBy: { createdAt: 'desc' },
  }),
  db.user.count(),
]);

return {
  data: users,
  pagination: {
    page,
    pageSize,
    total,
    pages: Math.ceil(total / pageSize),
  },
};
```

## Caching Strategies

```typescript
import { createClient } from 'redis';

const redis = createClient();

// Cache for 5 minutes
const getUser = async (id: string): Promise<User | null> => {
  const cached = await redis.get(`user:${id}`);
  if (cached) return JSON.parse(cached);
  
  const user = await db.user.findUnique({ where: { id } });
  if (user) {
    await redis.setEx(`user:${id}`, 300, JSON.stringify(user));
  }
  
  return user;
};

// Invalidate cache on update
const updateUser = async (id: string, data: Partial<User>) => {
  const user = await db.user.update({ where: { id }, data });
  await redis.del(`user:${id}`);
  return user;
};
```

## Index Critical Queries

```prisma
model User {
  id String @id
  email String @unique // Auto-indexed due to unique
  createdAt DateTime @default(now()) @db.Timestamptz()
  
  @@index([createdAt])
  @@index([email, createdAt])
}
```

## Monitor Slow Queries

```typescript
const logSlowQueries = (threshold = 100) => {
  return prisma.$use(async (params, next) => {
    const before = Date.now();
    const result = await next(params);
    const duration = Date.now() - before;
    
    if (duration > threshold) {
      logger.warn('Slow query detected', {
        model: params.model,
        action: params.action,
        duration,
      });
    }
    
    return result;
  });
};
```

