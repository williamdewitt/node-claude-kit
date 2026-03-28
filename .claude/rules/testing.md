# Testing Rule

## Enforcement

Integration-first testing with real databases. Use Testcontainers for data stores. Test actual behavior, not implementation details. AAA pattern: Arrange, Act, Assert.

## Integration Tests Over Unit Tests

**BAD** - Mocked everything, unrealistic
```typescript
describe('OrderService', () => {
  it('should create order', async () => {
    const mockDb = { order: { create: vi.fn() } };
    const service = new OrderService(mockDb);
    
    await service.create({ customerId: '1', items: [] });
    
    expect(mockDb.order.create).toHaveBeenCalled();
  });
});
```

**GOOD** - Real database, realistic scenario
```typescript
describe('OrderService', () => {
  let db: PrismaClient;
  
  beforeAll(async () => {
    db = new PrismaClient({
      datasources: { db: { url: process.env.TEST_DATABASE_URL } },
    });
  });
  
  it('should create order with items', async () => {
    const result = await createOrder(
      {
        customerId: '1',
        items: [{ productId: '1', qty: 2, price: 100 }],
      },
      db,
    );
    
    expect(result.isOk()).toBe(true);
    const order = result.unwrap();
    expect(order.total).toBe(200);
  });
});
```

## Use Testcontainers

**BAD** - In-memory database for tests
```typescript
const db = new PrismaClient({
  datasources: { db: { url: 'file:./test.db' } },
});
```

**GOOD** - Real PostgreSQL via Testcontainers
```typescript
import { PostgreSqlContainer } from 'testcontainers';

let postgres: PostgreSqlContainer;
let db: PrismaClient;

beforeAll(async () => {
  postgres = await new PostgreSqlContainer().start();
  db = new PrismaClient({
    datasources: { db: { url: postgres.getConnectionUri() } },
  });
  await prisma.$executeRawUnsafe(`...migration SQL...`);
});

afterAll(async () => {
  await db.$disconnect();
  await postgres.stop();
});
```

## AAA Pattern: Arrange, Act, Assert

```typescript
it('should calculate order total correctly', async () => {
  // Arrange - set up test data
  const items = [
    { productId: '1', qty: 2, price: 50 },
    { productId: '2', qty: 1, price: 100 },
  ];
  
  // Act - perform the operation
  const total = calculateTotal(items);
  
  // Assert - verify results
  expect(total).toBe(200);
});
```

## Descriptive Test Names

**BAD** - Vague test names
```typescript
it('works', () => { });
it('test', () => { });
```

**GOOD** - Describe exact behavior
```typescript
it('should create order with items and calculate total price', () => { });
it('should reject order with invalid customer ID', () => { });
it('should cancel order and refund payment', () => { });
```

## Fixtures Over Setup

**BAD** - Manual setup in each test
```typescript
it('user can create order', async () => {
  const user = await db.user.create({ data: { email: '...' } });
  const product = await db.product.create({ data: { ... } });
  // ...
});
```

**GOOD** - Reusable fixtures
```typescript
const fixtures = {
  user: () => db.user.create({ 
    data: { email: `user-${Date.now()}@test.com` } 
  }),
  product: () => db.product.create({ 
    data: { sku: `PROD-${Date.now()}`, price: 100 } 
  }),
};

it('user can create order', async () => {
  const user = await fixtures.user();
  const product = await fixtures.product();
  // ...
});
```

## Test Isolation

Each test should be independent:

```typescript
describe('Orders', () => {
  beforeEach(async () => {
    // Clean database before each test
    await db.order.deleteMany();
    await db.product.deleteMany();
  });
  
  it('test 1', async () => { });
  it('test 2', async () => { });
  // Each test starts fresh
});
```

## Error Testing

```typescript
it('should reject invalid email', async () => {
  const result = await createUser({ email: 'not-an-email' });
  
  expect(result.isErr()).toBe(true);
  const error = result.unwrapErr();
  expect(error).toBeInstanceOf(ValidationError);
});
```

