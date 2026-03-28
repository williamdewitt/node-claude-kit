# Feature-Driven Architecture

Feature-driven architecture (also called vertical slices) organizes code around user-facing features rather than technical layers. Each feature is a complete slice from API endpoint through database persistence, with its own folder structure.

## When to Use It

- **Default for monoliths**: Multi-team, full-stack projects
- **Scaling teams**: Teams can own features end-to-end without coordination
- **Rapid feature delivery**: Each team controls their entire stack
- **Microservices prep**: Easy to extract features into separate services later

## Core Patterns

### Folder Structure

```
src/
├── features/
│   ├── auth/
│   │   ├── routes.ts           // REST endpoints
│   │   ├── auth.service.ts      // Business logic
│   │   ├── auth.repository.ts   // Database queries (if needed)
│   │   ├── auth.types.ts        // Types & schemas
│   │   └── auth.test.ts         // Integration tests
│   ├── users/
│   │   ├── routes.ts
│   │   ├── users.service.ts
│   │   ├── users.types.ts
│   │   └── users.test.ts
│   └── posts/
│       ├── routes.ts
│       ├── posts.service.ts
│       ├── posts.types.ts
│       └── posts.test.ts
├── common/                      // Shared utilities
│   ├── middleware.ts
│   ├── errors.ts
│   └── validation.ts
└── main.ts
```

### Example: Auth Feature

```typescript
// features/auth/auth.types.ts
import { z } from 'zod';

export const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export type LoginRequest = z.infer<typeof LoginSchema>;
export type AuthToken = { accessToken: string; refreshToken: string };

// features/auth/auth.service.ts
export async function login(
  email: string,
  password: string,
  db: PrismaClient,
): Promise<Result<AuthToken, InvalidCredentials>> {
  const user = await db.user.findUnique({ where: { email } });
  if (!user || !await verifyPassword(password, user.passwordHash)) {
    return Err(new InvalidCredentials());
  }

  const tokens = await generateTokens(user.id);
  return Ok(tokens);
}

// features/auth/routes.ts
app.post<{ Body: LoginRequest }>('/auth/login', async (request, reply) => {
  const parsed = LoginSchema.safeParse(request.body);
  if (!parsed.success) {
    return reply.code(400).send({ error: 'Invalid input' });
  }

  const result = await login(
    parsed.data.email,
    parsed.data.password,
    db,
  );

  if (!result.ok) {
    return reply.code(401).send({ error: result.error.message });
  }

  return reply.code(200).send(result.value);
});
```

## BAD: Layered Architecture

```
❌ src/
   ├── controllers/
   │   └── auth.controller.ts
   ├── services/
   │   └── auth.service.ts
   ├── repositories/
   │   └── auth.repository.ts
   └── types/
       └── auth.types.ts
```

**Problems**:
- Request → Controller → Service → Repository → back up the chain
- Multiple files to understand a single feature
- Hard to test: every layer has different testing patterns
- Teams must coordinate across all layers

## GOOD: Feature-Driven

```
✅ src/features/auth/
   ├── routes.ts          // All routing logic
   ├── auth.service.ts    // All business logic
   ├── auth.types.ts      // All types
   └── auth.test.ts       // All tests
```

**Benefits**:
- Navigate one folder to understand a feature
- Clear ownership: one team owns the entire feature
- Easy to test: one test file per feature
- Easy to extract into a service later

## Key Principles

1. **Co-locate related code**: Types, logic, and tests live together
2. **Minimize dependencies across features**: Features should be loosely coupled
3. **Common utilities in shared folder**: Only truly shared code
4. **Direct database usage**: No repository abstraction layer
5. **Async/await throughout**: No Promise chains

## Communication Between Features

```typescript
// ❌ BAD: Feature A calls Feature B's service directly
import { getUserWithPosts } from '../posts/posts.service';

// ✅ GOOD: Use domain events or shared types
export interface PostCreatedEvent {
  userId: string;
  postId: string;
  createdAt: Date;
}

// features/users/users.service.ts - subscribes to events
eventBus.on('post:created', async (event: PostCreatedEvent) => {
  await db.user.update({
    where: { id: event.userId },
    data: { postCount: { increment: 1 } },
  });
});
```

## Migration to Microservices

When a feature grows large enough:

```bash
# Extract feature to its own service
npx create-app users-service
# Copy features/users/* → users-service/src/
# Replace direct function calls with HTTP clients
```

## When to Split

- Feature is 3+ folders deep
- Feature has 10+ Prisma models
- Feature requires its own database
- Different SLAs or scaling requirements
