# Async Patterns Rule

## Enforcement

Use async/await for all async operations. Properly propagate errors. Cancel operations when appropriate. Never ignore Promise rejections.

## Async/Await, Not Promise Chains

**BAD** - Promise chains
```typescript
const fetchUserData = () => {
  return getUser()
    .then(user => getOrders(user.id))
    .then(orders => ({ user, orders }))
    .catch(error => console.error(error));
};
```

**GOOD** - Async/await
```typescript
const fetchUserData = async () => {
  try {
    const user = await getUser();
    const orders = await getOrders(user.id);
    return { user, orders };
  } catch (error) {
    throw new FetchError('Failed to fetch user data', { cause: error });
  }
};
```

## Proper Error Propagation

**BAD** - Swallowing errors
```typescript
const saveOrder = async (order: Order) => {
  try {
    await db.order.create({ data: order });
  } catch (error) {
    // Error lost
  }
};
```

**GOOD** - Re-throw with context
```typescript
const saveOrder = async (order: Order): Promise<Order> => {
  try {
    return await db.order.create({ data: order });
  } catch (error) {
    throw new DatabaseError('Failed to save order', { cause: error });
  }
};
```

## Cancellation Tokens

Always accept and respect cancellation signals:

```typescript
export const fetchUserOrders = async (
  userId: string,
  signal?: AbortSignal,
): Promise<Order[]> => {
  if (signal?.aborted) throw new AbortError();
  
  const controller = new AbortController();
  if (signal) signal.addEventListener('abort', () => controller.abort());
  
  try {
    return await db.order.findMany({
      where: { userId },
    });
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      throw new OperationCancelledError();
    }
    throw error;
  }
};

// Usage in FastifyRequest
const orderHandler = async (req: FastifyRequest, reply: FastifyReply) => {
  const orders = await fetchUserOrders(req.params.userId, req.signal);
  reply.send(orders);
};
```

## Never Ignore Promise Rejections

**BAD** - Fire and forget
```typescript
// Missing await, error ignored
db.order.create({ data: order });

sendEmail(user.email).catch(() => {}); // Silently ignored
```

**GOOD** - Handle or await
```typescript
// Option 1: await
await db.order.create({ data: order });

// Option 2: explicitly handle rejection
sendEmail(user.email)
  .catch((error) => logger.error('Email failed', { error }));

// Option 3: background tasks with error handling
queueEmailTask(user.email)
  .catch((error) => logger.error('Queue failed', { error }));
```

## Parallel Operations

Use Promise.all() for independent operations:

```typescript
// BAD - Sequential (slower)
const user = await getUser(userId);
const orders = await getOrders(userId);
const profile = await getProfile(userId);

// GOOD - Parallel
const [user, orders, profile] = await Promise.all([
  getUser(userId),
  getOrders(userId),
  getProfile(userId),
]);
```

## Timeouts

Always set timeouts for external operations:

```typescript
const fetchWithTimeout = async (url: string, timeoutMs = 5000): Promise<Response> => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  
  try {
    return await fetch(url, { signal: controller.signal });
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      throw new TimeoutError(`Request to ${url} timed out`);
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
};
```

## Type-Safe Async Functions

Always type return values:

```typescript
// GOOD - Clear intent
export const getUser = async (id: string): Promise<User> => { /* ... */ };
export const createOrder = async (data: CreateOrderInput): Promise<Result<Order>> => { /* ... */ };
export const deleteUser = async (id: string): Promise<void> => { /* ... */ };
```

