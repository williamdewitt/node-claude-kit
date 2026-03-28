# Caching Skill

## When to Use

Caching read-heavy operations, expensive computations, or external API calls.

## In-Memory Caching

```typescript
const cache = new Map<string, { value: unknown; expiry: number }>();

const memoize = <T extends (...args: any[]) => Promise<any>>(
  fn: T,
  ttl = 5 * 60 * 1000, // 5 minutes
): T => {
  return (async (...args: any[]) => {
    const key = JSON.stringify([fn.name, ...args]);
    const cached = cache.get(key);
    
    if (cached && cached.expiry > Date.now()) {
      return cached.value;
    }
    
    const value = await fn(...args);
    cache.set(key, { value, expiry: Date.now() + ttl });
    return value;
  }) as T;
};

// Usage
const getUser = memoize(async (id: string) => {
  return await db.user.findUnique({ where: { id } });
}, 10 * 60 * 1000); // Cache for 10 minutes
```

## Redis Caching

```typescript
import { createClient } from 'redis';

const redis = createClient();

const getUser = async (id: string): Promise<User | null> => {
  const cached = await redis.get(`user:${id}`);
  if (cached) return JSON.parse(cached);
  
  const user = await db.user.findUnique({ where: { id } });
  if (user) {
    await redis.setEx(`user:${id}`, 300, JSON.stringify(user)); // 5 minutes
  }
  return user;
};

// Invalidate on update
const updateUser = async (id: string, data: Partial<User>) => {
  const user = await db.user.update({ where: { id }, data });
  await redis.del(`user:${id}`); // Clear cache
  return user;
};
```

## Cache Invalidation

```typescript
const invalidateUserCache = async (userId: string) => {
  await redis.del(`user:${userId}`);
  await redis.del(`user:${userId}:orders`);
  await redis.del(`users:all`);
};

// On create
await redis.del('users:all'); // Invalidate list cache

// On update
await invalidateUserCache(userId);

// On delete
await invalidateUserCache(userId);
```

