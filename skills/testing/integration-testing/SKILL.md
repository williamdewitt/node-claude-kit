# Integration Testing Skill

## When to Use

Testing entire features with real databases, real HTTP calls, realistic scenarios. Integration-first development.

## Real Database Testing

```typescript
import { PostgreSqlContainer } from 'testcontainers';

describe('Order Service Integration', () => {
  let postgres: PostgreSqlContainer;
  let db: PrismaClient;
  
  beforeAll(async () => {
    // Spin up real PostgreSQL
    postgres = await new PostgreSqlContainer().start();
    
    const url = postgres.getConnectionUri();
    db = new PrismaClient({ datasources: { db: { url } } });
    
    // Run migrations
    await exec('npx prisma migrate deploy', { env: { DATABASE_URL: url } });
  });
  
  afterAll(async () => {
    await db.$disconnect();
    await postgres.stop();
  });
  
  it('should create order with items', async () => {
    const result = await createOrder(
      { customerId: '1', items: [{ productId: '1', qty: 2 }] },
      db,
    );
    
    expect(result.ok).toBe(true);
    
    // Verify in database
    const order = await db.order.findUnique({ where: { id: result.value.id } });
    expect(order?.total).toBe(200);
  });
});
```

## Test Fixtures

```typescript
const fixtures = {
  user: (overrides?: Partial<User>) => db.user.create({
    data: {
      email: `user-${Date.now()}@test.com`,
      name: 'Test User',
      ...overrides,
    },
  }),
  
  order: (userId: string, overrides?: Partial<Order>) => db.order.create({
    data: {
      userId,
      status: 'pending',
      total: 100,
      ...overrides,
    },
  }),
  
  product: (overrides?: Partial<Product>) => db.product.create({
    data: {
      sku: `PROD-${Date.now()}`,
      name: 'Test Product',
      price: 50,
      stock: 100,
      ...overrides,
    },
  }),
};

it('user can order product', async () => {
  const user = await fixtures.user();
  const product = await fixtures.product();
  
  const order = await createOrder({ userId: user.id, items: [product.id] }, db);
  expect(order.ok).toBe(true);
});
```

