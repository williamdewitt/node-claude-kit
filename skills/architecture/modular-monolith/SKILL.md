# Modular Monolith

A monolith organized with explicit module boundaries, treating each module as a mini-service with published APIs. Modules communicate through event buses or internal RPCs rather than direct function calls.

## When to Use It

- **Team scaling**: 5+ teams working on same codebase
- **Deployment frequency**: Different modules deploy at different rates
- **Complexity**: Need to enforce coupling boundaries
- **Extraction prep**: Easy to extract modules into microservices

## vs Feature-Driven

| Aspect | Feature-Driven | Modular Monolith |
|--------|---|---|
| **Size** | Small to medium | Large (100+ engineers) |
| **Module Dependencies** | Direct calls | Events / internal RPCs |
| **Deployment** | Single artifact | Single artifact, separate concerns |
| **Team Coordination** | Minimal | Via contracts |

## Folder Structure

```
src/
├── modules/
│   ├── users/
│   │   ├── application/
│   │   │   └── user.controller.ts
│   │   ├── domain/
│   │   │   ├── user.ts
│   │   │   └── user.service.ts
│   │   ├── infrastructure/
│   │   │   ├── user.repository.ts
│   │   │   └── user.events.ts
│   │   └── users.module.ts     // Published API
│   ├── payments/
│   │   ├── application/
│   │   ├── domain/
│   │   ├── infrastructure/
│   │   └── payments.module.ts
│   └── notifications/
│       ├── application/
│       ├── domain/
│       ├── infrastructure/
│       └── notifications.module.ts
├── shared/                      // Truly shared (min 3 modules use)
│   ├── events/
│   ├── errors/
│   └── validation/
└── main.ts
```

## Example: Users Module

```typescript
// modules/users/users.module.ts (published interface)
export interface UsersModule {
  createUser(email: string, name: string): Promise<UserId>;
  getUserById(id: UserId): Promise<User | null>;
  events: EventBus;  // For listening to user events
}

// modules/users/domain/user.service.ts
export async function createUser(
  email: string,
  name: string,
  repo: UserRepository,
  events: EventBus,
): Promise<Result<User, CreateUserError>> {
  const existing = await repo.findByEmail(email);
  if (existing) return Err(new UserAlreadyExists());

  const user = { id: generateId(), email, name, createdAt: new Date() };
  await repo.save(user);

  // Publish event for other modules
  events.emit('user:created', { userId: user.id, email });

  return Ok(user);
}

// modules/users/infrastructure/user.events.ts
export interface UserEvents {
  'user:created': { userId: string; email: string };
  'user:deleted': { userId: string };
  'user:updated': { userId: string };
}

// modules/users/users.module.ts (full export)
export function createUsersModule(
  db: PrismaClient,
  events: EventBus,
): UsersModule {
  const repository = new PrismaUserRepository(db);

  return {
    async createUser(email, name) {
      const result = await createUser(email, name, repository, events);
      if (!result.ok) throw new Error(result.error.message);
      return result.value.id;
    },

    async getUserById(id) {
      return repository.findById(id);
    },

    events,
  };
}
```

## Listening to Module Events

```typescript
// modules/notifications/infrastructure/notification.listener.ts
export function setupNotificationListeners(
  usersModule: UsersModule,
  emailService: EmailService,
) {
  usersModule.events.on('user:created', async (event) => {
    await emailService.send({
      to: event.email,
      subject: 'Welcome!',
      body: 'Thanks for signing up.',
    });
  });
}
```

## Module Communication: Bad vs Good

```typescript
// ❌ BAD: Direct imports (tight coupling)
import { createUser } from '../users/domain/user.service';

export async function sendWelcomeEmail(email: string) {
  const user = await createUser(email, 'User');
  await emailService.send(email, 'Welcome');
}

// ✅ GOOD: Through module API + events
const usersModule = createUsersModule(db, eventBus);
eventBus.on('user:created', async (event) => {
  await emailService.send(event.email, 'Welcome');
});
```

## Enforcing Boundaries

Each module only exports from `*.module.ts`:

```typescript
// module-exports.ts - orchestrates all modules
import { createUsersModule } from './users/users.module';
import { createPaymentsModule } from './payments/payments.module';

const eventBus = createEventBus();

export const modules = {
  users: createUsersModule(db, eventBus),
  payments: createPaymentsModule(db, eventBus),
  notifications: createNotificationsModule(emailService),
};

// Setup cross-module communication
setupPaymentListeners(modules.payments, modules.notifications);
setupUserListeners(modules.users, modules.notifications);
```

## Testing a Module

```typescript
// modules/users/__tests__/user.service.test.ts
it('creates user and emits event', async () => {
  const mockRepo: UserRepository = { /* ... */ };
  const mockEvents = createMockEventBus();

  const result = await createUser(
    'test@example.com',
    'Test User',
    mockRepo,
    mockEvents,
  );

  expect(result.ok).toBe(true);
  expect(mockEvents.getEmitted('user:created')[0]).toEqual({
    userId: expect.any(String),
    email: 'test@example.com',
  });
});
```

## Extracting to Microservice

When a module is ready to be extracted:

```bash
# Create new service
npx create-app users-service

# Copy module files
cp -r modules/users/* users-service/src/

# Replace event bus with message queue
# Replace direct calls with HTTP clients
```

## Anti-Patterns to Avoid

1. **Hidden dependencies**: One module importing private code from another
2. **Bidirectional events**: Module A → B → A circular dependency
3. **Shared data models**: Using same entity across modules
4. **Synchronous RPC chains**: A → B → C → A in request path

## Monolith with Module Boundaries

Don't extract to microservices unless you have these problems:
- Modules deploy at different rates
- Different scaling requirements
- Different teams with separate deployment rights
- Massive codebase (100k+ LOC)

A well-organized monolith with events scales to 50+ engineers.
