# Query Optimization with Prisma

Techniques for writing efficient database queries: selecting specific fields, batching operations, avoiding N+1 queries, and using indexes strategically.

## Common Performance Problems

### N+1 Query Problem

```typescript
// ❌ BAD: N+1 queries
const users = await db.user.findMany();
for (const user of users) {
  user.posts = await db.post.findMany({ where: { authorId: user.id } });
  // If 100 users, runs 101 total queries!
}

// ✅ GOOD: Single query with relation
const users = await db.user.findMany({
  include: { posts: true },
});
```

### Over-Fetching Data

```typescript
// ❌ BAD: Fetch all fields when only some needed
const user = await db.user.findUnique({ where: { id } });
// Returns: id, name, email, passwordHash, phoneNumber, address, ...

// ✅ GOOD: Select only required fields
const user = await db.user.findUnique({
  where: { id },
  select: { id: true, name: true, email: true },
});
```

### Missing Indexes

```typescript
// prisma/schema.prisma

// ❌ BAD: Frequently queried field has no index
model User {
  id String @id @default(cuid())
  email String
  name String
}

// ✅ GOOD: Index on frequently filtered fields
model User {
  id String @id @default(cuid())
  email String @unique // Unique creates index
  name String

  @@index([email]) // If not unique, add explicit index
  @@index([name]) // For sorted results
}
```

## Query Optimization Patterns

### 1. Select Only Needed Fields

```typescript
// ❌ BAD: Entire object
async function getActiveUsers() {
  return db.user.findMany({
    where: { isActive: true },
  });
}

// ✅ GOOD: Selected fields
async function getActiveUsers() {
  return db.user.findMany({
    where: { isActive: true },
    select: {
      id: true,
      name: true,
      email: true,
      // Exclude: passwordHash, phoneNumber, ...
    },
  });
}
```

### 2. Batch Operations

```typescript
// ❌ BAD: Individual updates
for (const userId of userIds) {
  await db.user.update({
    where: { id: userId },
    data: { isActive: false },
  });
}

// ✅ GOOD: Batch update
await db.user.updateMany({
  where: { id: { in: userIds } },
  data: { isActive: false },
});
```

### 3. Pagination Instead of Loading All

```typescript
// ❌ BAD: Load 10k records
const allUsers = await db.user.findMany();
const page1 = allUsers.slice(0, 20);

// ✅ GOOD: Offset/limit pagination
const page1 = await db.user.findMany({
  skip: 0,
  take: 20,
  orderBy: { createdAt: 'desc' },
});

// ✅ BETTER: Cursor-based pagination (more efficient)
const firstPage = await db.user.findMany({
  take: 20,
  cursor: undefined,
  orderBy: { id: 'asc' },
});

const secondPage = await db.user.findMany({
  take: 20,
  skip: 1, // Skip the cursor
  cursor: { id: firstPage[firstPage.length - 1].id },
  orderBy: { id: 'asc' },
});
```

### 4. Conditional Relations

```typescript
// ❌ BAD: Always include large relation
const user = await db.user.findUnique({
  where: { id },
  include: {
    posts: true, // 1000+ posts? Slow!
  },
});

// ✅ GOOD: Include only when requested
interface GetUserOptions {
  includePosts?: boolean;
}

async function getUser(id: string, options?: GetUserOptions) {
  return db.user.findUnique({
    where: { id },
    include: {
      posts: options?.includePosts ? true : false,
    },
  });
}

const user = await getUser('user-123', { includePosts: false });
```

### 5. Aggregations Instead of Loading Data

```typescript
// ❌ BAD: Load all and count in code
const posts = await db.post.findMany({ where: { authorId } });
const count = posts.length;

// ✅ GOOD: Database aggregation
const { _count } = await db.post.aggregate({
  where: { authorId },
  _count: true,
});
const count = _count;
```

## Complex Query Optimization

### Counting with Filters

```typescript
// ❌ BAD: Load all records to count
const posts = await db.post.findMany({
  where: {
    authorId,
    status: 'published',
    createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
  },
});
const count = posts.length;

// ✅ GOOD: Count query
const count = await db.post.count({
  where: {
    authorId,
    status: 'published',
    createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
  },
});
```

### Finding Max/Min Values

```typescript
// ❌ BAD: Load all and find max
const posts = await db.post.findMany({ where: { authorId } });
const maxLikes = Math.max(...posts.map((p) => p.likes));

// ✅ GOOD: Database aggregation
const result = await db.post.aggregate({
  where: { authorId },
  _max: { likes: true },
});
const maxLikes = result._max.likes;
```

### Grouping and Sorting

```typescript
// ✅ Find top authors by post count
const topAuthors = await db.post.groupBy({
  by: ['authorId'],
  _count: { id: true },
  orderBy: { _count: { id: 'desc' } },
  take: 10,
});
```

## Transaction Optimization

```typescript
// ✅ Single transaction for multi-step operation
const result = await db.$transaction(async (tx) => {
  // Create user
  const user = await tx.user.create({
    data: { email, name },
  });

  // Create welcome post
  const post = await tx.post.create({
    data: {
      authorId: user.id,
      title: 'Welcome!',
      content: 'Thanks for joining.',
    },
  });

  return { user, post };
});
```

## Monitoring Slow Queries

```typescript
// Add query logging
const prisma = new PrismaClient({
  log: [
    { level: 'query', emit: 'stdout' }, // See all queries
    { level: 'warn', emit: 'stdout' }, // Show warnings
  ],
});

// Or with middleware
prisma.$use(async (params, next) => {
  const before = Date.now();
  const result = await next(params);
  const after = Date.now();

  if (after - before > 100) {
    console.warn(
      `Slow query (${after - before}ms): ${params.model}.${params.action}`,
    );
  }

  return result;
});
```

## Indexing Strategy

```prisma
// schema.prisma

model User {
  id String @id @default(cuid())
  email String @unique // Used in WHERE frequently
  name String
  createdAt DateTime @default(now())
  status String // Filtered in queries

  // Compound index for common WHERE combinations
  @@index([status, createdAt])
}

model Post {
  id String @id @default(cuid())
  authorId String // Foreign key for relations
  title String @db.VarChar(255)
  content String @db.Text
  createdAt DateTime @default(now())

  author User @relation(fields: [authorId], references: [id])

  // Index for finding posts by author
  @@index([authorId])
  // Compound index for pagination by creation date
  @@index([authorId, createdAt])
}
```

## Caching Hot Data

```typescript
// ✅ Cache frequently accessed data
const cache = new Map<string, User>();

async function getUserWithCache(id: string) {
  if (cache.has(id)) return cache.get(id)!;

  const user = await db.user.findUnique({
    where: { id },
    select: { id: true, name: true, email: true },
  });

  if (user) cache.set(id, user);
  return user;
}

// Invalidate cache on update
await db.user.update({
  where: { id },
  data: { name },
});
cache.delete(id); // Invalidate
```

## Key Metrics to Monitor

1. **Query count per request**: Should be consistent, not N+1
2. **Data transferred**: Only fetch needed fields
3. **Query execution time**: Should be <100ms
4. **Cache hit rate**: High hit rate = good selection
