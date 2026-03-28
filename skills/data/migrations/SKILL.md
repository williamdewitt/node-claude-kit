# Database Migrations Skill

## When to Use

Any schema change. Create migrations for every alteration, test them locally, run them in production.

## Create Migration

```bash
# Make schema changes in schema.prisma, then:
npx prisma migrate dev --name add_user_email_unique
```

## Migration File Structure

```sql
-- Generated migration file
-- prisma/migrations/20240315_add_user_email_unique/migration.sql

-- AlterTable
ALTER TABLE "User" ADD CONSTRAINT "User_email_unique" UNIQUE ("email");
```

## Safe Migration Pattern

```typescript
// Before making breaking changes, add new field
// Migration 1: Add email_new
ALTER TABLE users ADD COLUMN email_new VARCHAR;

// Migration 2: Copy data
UPDATE users SET email_new = email;

// Migration 3: Validate data (manual check)
// SELECT COUNT(*) FROM users WHERE email_new IS NULL;

// Migration 4: Drop old column and rename
ALTER TABLE users DROP COLUMN email;
ALTER TABLE users RENAME COLUMN email_new TO email;

// Update code to use new column between migrations
```

## Rollback Strategy

```bash
# Never use
npx prisma migrate reset # Deletes all data!

# Instead, create a reverse migration
# prisma/migrations/20240315_add_user_email_unique/migration.sql
ALTER TABLE "User" DROP CONSTRAINT "User_email_unique";
```

## Test Migrations

```typescript
// vitest.setup.ts
beforeAll(async () => {
  // Run migrations on test database
  await exec('npx prisma migrate deploy');
});

it('migration succeeds', async () => {
  const user = await db.user.create({ data: { email: 'test@example.com' } });
  expect(user.email).toBe('test@example.com');
});
```

