# Database Testing Skill

## When to Use

Testing queries, migrations, edge cases. Use real database to catch real issues.

## Test Database Setup

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    setupFiles: ['./vitest.setup.ts'],
    globals: true,
  },
});

// vitest.setup.ts
import { exec } from 'child_process';
import { PostgreSqlContainer } from 'testcontainers';

let postgres: PostgreSqlContainer;

beforeAll(async () => {
  postgres = await new PostgreSqlContainer().start();
  process.env.TEST_DATABASE_URL = postgres.getConnectionUri();
  
  await exec('npx prisma migrate deploy', {
    env: { DATABASE_URL: process.env.TEST_DATABASE_URL },
  });
});

afterAll(async () => {
  await postgres.stop();
});
```

## Query Testing

```typescript
it('should find user by email with case-insensitive match', async () => {
  // Create user
  const user = await db.user.create({
    data: { email: 'Test@Example.COM', name: 'User' },
  });
  
  // Query with different case
  const found = await db.$queryRaw`
    SELECT * FROM "User" WHERE LOWER(email) = LOWER(${'test@example.com'})
  `;
  
  expect(found).toHaveLength(1);
  expect(found[0].id).toBe(user.id);
});
```

## Test Data Cleanup

```typescript
describe('Order Repository', () => {
  afterEach(async () => {
    // Clean after each test
    await db.order.deleteMany();
    await db.user.deleteMany();
  });
  
  it('test 1', async () => { /* ... */ });
  it('test 2', async () => { /* ... */ });
});
```

