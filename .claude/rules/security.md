# Security Rule

## Enforcement

No hardcoded secrets in code. Parameterized queries for all database operations. Explicit authentication/authorization. Validate all inputs at system boundaries.

## Environment Secrets

**BAD** - Hardcoded credentials
```typescript
const dbUrl = 'postgresql://user:password@localhost:5432/db';
const apiKey = 'sk-1234567890';

export const mongoConnect = 'mongodb+srv://admin:p@ssw0rd@cluster.mongodb.net';
```

**GOOD** - Environment variables
```typescript
const dbUrl = process.env.DATABASE_URL;
if (!dbUrl) throw new Error('DATABASE_URL not configured');

const apiKey = process.env.API_KEY;
if (!apiKey) throw new Error('API_KEY not configured');

// Validate at startup
export const validateEnv = () => {
  const required = ['DATABASE_URL', 'API_KEY', 'JWT_SECRET'];
  const missing = required.filter(key => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(`Missing environment variables: ${missing.join(', ')}`);
  }
};
```

## Parameterized Queries

**BAD** - SQL injection vulnerability
```typescript
const getUserByEmail = async (email: string) => {
  return await db.$queryRaw`SELECT * FROM users WHERE email = '${email}'`;
};
```

**GOOD** - Parameterized queries
```typescript
const getUserByEmail = async (email: string) => {
  return await db.user.findUnique({ where: { email } });
};

// Or with raw queries
const getUserByEmail = async (email: string) => {
  return await db.$queryRaw`SELECT * FROM users WHERE email = ${email}`;
};
```

## Explicit Authentication

**BAD** - Unclear auth
```typescript
const handler = (req: FastifyRequest) => {
  // Is this protected? Unclear.
  return req.user?.id;
};
```

**GOOD** - Explicit guards
```typescript
export const requireAuth = async (request: FastifyRequest) => {
  if (!request.user) {
    throw new UnauthorizedError('Authentication required');
  }
  return request.user;
};

const handler = async (req: FastifyRequest) => {
  const user = await requireAuth(req);
  return user.id;
};
```

## Input Validation

**BAD** - No validation
```typescript
const createUser = async (data: any) => {
  await db.user.create({ data });
};
```

**GOOD** - Zod validation at boundary
```typescript
import { z } from 'zod';

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  age: z.number().int().positive(),
});

type CreateUserInput = z.infer<typeof createUserSchema>;

const createUser = async (data: unknown): Promise<Result<User>> => {
  const validation = createUserSchema.safeParse(data);
  if (!validation.success) {
    return err(new ValidationError(validation.error.errors));
  }
  return await db.user.create({ data: validation.data });
};
```

## No Leaking Sensitive Data

**BAD** - Returns internal details
```typescript
const handler = (req: FastifyRequest) => {
  const user = db.user.findUnique({ where: { id: req.params.id } });
  return user; // Returns password hash, internal flags
};
```

**GOOD** - Explicit response schema
```typescript
const userResponseSchema = z.object({
  id: z.string(),
  email: z.string(),
  name: z.string(),
  createdAt: z.date(),
});

type UserResponse = z.infer<typeof userResponseSchema>;

const handler = async (req: FastifyRequest): Promise<UserResponse> => {
  const user = await db.user.findUnique({ where: { id: req.params.id } });
  if (!user) throw new NotFoundError();
  
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    createdAt: user.createdAt,
  };
};
```

## HTTPS Only

**BAD** - Allows HTTP
```typescript
// No explicit config
```

**GOOD** - Enforces HTTPS
```typescript
if (process.env.NODE_ENV === 'production') {
  app.register(require('@fastify/helmet'));
  // All traffic must be HTTPS
}
```

## Rate Limiting

```typescript
import rateLimit from '@fastify/rate-limit';

app.register(rateLimit, {
  max: 100,
  timeWindow: '15 minutes',
});
```

