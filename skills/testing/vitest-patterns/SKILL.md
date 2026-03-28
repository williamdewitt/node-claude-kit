# Vitest Patterns Skill

## When to Use

All testing. Vitest is fast, ES module native, and TypeScript-first.

## Setup

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: { provider: 'v8', reporter: ['text', 'json'] },
  },
});
```

## Basic Test Structure

```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest';

describe('Order Service', () => {
  let db: PrismaClient;
  
  beforeEach(async () => {
    // Setup - runs before each test
    db = new PrismaClient();
  });
  
  afterEach(async () => {
    // Cleanup
    await db.$disconnect();
  });
  
  it('should create order with items', async () => {
    // Arrange
    const input = { customerId: '1', items: [{ productId: '1', qty: 2 }] };
    
    // Act
    const result = await createOrder(input, db);
    
    // Assert
    expect(result.ok).toBe(true);
    expect(result.value.total).toBe(200);
  });
  
  it('should reject invalid order', async () => {
    const result = await createOrder({}, db);
    expect(result.ok).toBe(false);
  });
});
```

## Mocking

```typescript
import { vi } from 'vitest';

// Mock module
vi.mock('./email', () => ({
  sendEmail: vi.fn().mockResolvedValue(true),
}));

// Verify calls
expect(sendEmail).toHaveBeenCalledWith('test@example.com');
```

## Fixtures

```typescript
const fixtures = {
  user: () => db.user.create({
    data: { email: `user-${Date.now()}@test.com`, name: 'Test' },
  }),
  order: (userId: string) => db.order.create({
    data: { userId, status: 'pending', total: 100 },
  }),
};

it('user can create order', async () => {
  const user = await fixtures.user();
  const order = await fixtures.order(user.id);
  expect(order.userId).toBe(user.id);
});
```

