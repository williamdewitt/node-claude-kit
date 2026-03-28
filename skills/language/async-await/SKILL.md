# Async/Await Patterns Skill

## When to Use

All asynchronous operations. Always use async/await, never Promise chains.

## Basic Pattern

```typescript
// GOOD - Clear, readable async/await
const fetchUserOrders = async (userId: string): Promise<Order[]> => {
  try {
    const user = await getUser(userId);
    const orders = await getOrders(user.id);
    return orders;
  } catch (error) {
    throw new FetchError('Failed to fetch orders', { cause: error });
  }
};

// BAD - Promise chains
const fetchUserOrders = (userId) => {
  return getUser(userId)
    .then(user => getOrders(user.id))
    .catch(error => { throw error; });
};
```

## Error Handling

Always wrap in try/catch:

```typescript
// GOOD
const create = async (data: CreateUserInput): Promise<User> => {
  try {
    return await db.user.create({ data });
  } catch (error) {
    throw new DatabaseError('User creation failed', { cause: error });
  }
};

// BAD
const create = async (data) => {
  return await db.user.create({ data }); // Error swallowed
};
```

## Parallel Operations

Use Promise.all for independent operations:

```typescript
// GOOD - Parallel
const [user, orders, profile] = await Promise.all([
  getUser(id),
  getOrders(id),
  getProfile(id),
]);

// BAD - Sequential (3x slower)
const user = await getUser(id);
const orders = await getOrders(id);
const profile = await getProfile(id);
```

## Array Operations

Use for...of for async iteration:

```typescript
// GOOD
for (const item of items) {
  const result = await process(item);
}

// BAD - .forEach doesn't await properly
items.forEach(async (item) => {
  await process(item); // Race condition
});
```

