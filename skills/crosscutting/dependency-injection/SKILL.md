# Dependency Injection for Node.js

Decoupling components by injecting dependencies rather than creating them internally.

## Why Dependency Injection

```typescript
// ❌ BAD: Tightly coupled
class UserService {
  private db = new PrismaClient(); // Creates own instance
  private emailService = new SendGridService(); // Creates own instance

  async createUser(email: string, name: string) {
    const user = await this.db.user.create({ data: { email, name } });
    await this.emailService.sendWelcome(email);
    return user;
  }
}

// Hard to test: Must use real database and email service
const service = new UserService();

// ✅ GOOD: Injected dependencies
class UserService {
  constructor(
    private db: PrismaClient,
    private emailService: EmailService,
  ) {}

  async createUser(email: string, name: string) {
    const user = await this.db.user.create({ data: { email, name } });
    await this.emailService.sendWelcome(email);
    return user;
  }
}

// Easy to test: Pass mocks
const mockDb = { user: { create: () => ({ id: '123' }) } };
const mockEmail = { sendWelcome: () => {} };
const service = new UserService(mockDb, mockEmail);
```

## Manual Dependency Injection

```typescript
// lib/container.ts
import { PrismaClient } from '@prisma/client';
import { SendGridEmailService } from '@/services/sendgrid-email.service';
import { StripePaymentService } from '@/services/stripe-payment.service';
import { UserService } from '@/services/user.service';

// Initialize dependencies
const db = new PrismaClient();
const emailService = new SendGridEmailService(process.env.SENDGRID_API_KEY);
const paymentService = new StripePaymentService(process.env.STRIPE_SECRET_KEY);

// Create services with injected dependencies
const userService = new UserService(db, emailService);
const paymentService = new PaymentService(db, stripeService);

export const services = {
  db,
  emailService,
  paymentService,
  userService,
};

// app.ts
import { services } from '@/lib/container';

app.post('/users', async (request, reply) => {
  const user = await services.userService.createUser(
    request.body.email,
    request.body.name,
  );
  return reply.send(user);
});
```

## IOC Container with TSyringe

```bash
npm install tsyringe reflect-metadata
```

```typescript
// services/user.service.ts
import { injectable, inject } from 'tsyringe';
import { PrismaClient } from '@prisma/client';
import { EmailService } from '@/services/email.service';

@injectable()
export class UserService {
  constructor(
    @inject('db') private db: PrismaClient,
    @inject('emailService') private emailService: EmailService,
  ) {}

  async createUser(email: string, name: string) {
    const user = await this.db.user.create({ data: { email, name } });
    await this.emailService.sendWelcome(email);
    return user;
  }
}

// lib/container.ts
import 'reflect-metadata';
import { container } from 'tsyringe';
import { PrismaClient } from '@prisma/client';
import { SendGridEmailService } from '@/services/sendgrid-email.service';
import { UserService } from '@/services/user.service';

// Register dependencies
container.register('db', { useValue: new PrismaClient() });
container.register('emailService', {
  useClass: SendGridEmailService,
});

// Auto-register marked classes
container.registerSingleton(UserService);

export { container };

// app.ts
import 'reflect-metadata';
import { container } from '@/lib/container';
import { UserService } from '@/services/user.service';

app.post('/users', async (request, reply) => {
  const userService = container.resolve(UserService);
  const user = await userService.createUser(
    request.body.email,
    request.body.name,
  );
  return reply.send(user);
});
```

## Testing with Dependency Injection

```typescript
// services/user.service.test.ts
import { describe, it, expect } from 'vitest';
import { UserService } from '@/services/user.service';

describe('UserService', () => {
  it('creates user and sends email', async () => {
    // Mock dependencies
    const mockDb = {
      user: {
        create: vi.fn().mockResolvedValue({ id: '123', email: 'test@example.com', name: 'Test' }),
      },
    };

    const mockEmailService = {
      sendWelcome: vi.fn().mockResolvedValue(undefined),
    };

    // Inject mocks
    const service = new UserService(mockDb as any, mockEmailService as any);

    // Test
    const user = await service.createUser('test@example.com', 'Test User');

    expect(user.id).toBe('123');
    expect(mockDb.user.create).toHaveBeenCalledWith({
      data: {
        email: 'test@example.com',
        name: 'Test User',
      },
    });
    expect(mockEmailService.sendWelcome).toHaveBeenCalledWith('test@example.com');
  });
});
```

## Singleton vs Transient

```typescript
// lib/container.ts
import { container, Lifetime } from 'tsyringe';

// Singleton: Same instance everywhere (for database, cache, etc)
container.register('db', {
  useValue: new PrismaClient(),
});

// Transient: New instance each time (for services)
container.register(UserService, {
  useClass: UserService,
  scope: Lifetime.Transient,
});

// Or with decorator
@injectable({ lifetime: Lifetime.Singleton })
export class Config {
  // ...
}
```

## Factory Pattern

```typescript
// lib/container.ts
container.register('emailService', {
  useFactory: () => {
    if (process.env.NODE_ENV === 'test') {
      return new MockEmailService();
    }
    return new SendGridEmailService(process.env.SENDGRID_API_KEY);
  },
});
```

## Middleware with DI

```typescript
// middleware/error-handler.ts
import { FastifyInstance } from 'fastify';
import { container } from '@/lib/container';
import { Logger } from '@/services/logger.service';

export async function setupErrorHandler(app: FastifyInstance) {
  const logger = container.resolve(Logger);

  app.setErrorHandler(async (error, request, reply) => {
    logger.error('Request error', {
      path: request.url,
      error: error.message,
    });

    reply.code(500).send({ error: 'Internal server error' });
  });
}
```

## Benefits

1. **Testability**: Mock dependencies easily
2. **Flexibility**: Swap implementations
3. **Loose coupling**: Services don't create dependencies
4. **Single Responsibility**: Each service has one job
5. **Configuration management**: All wiring in one place

## When to Use

- **Large applications**: Multiple services needing coordination
- **Testability required**: Unit tests with mocks
- **Multiple implementations**: Different for dev/test/prod

## When to Avoid

- **Simple scripts**: Overkill for one-off scripts
- **Prototypes**: Add after MVP validates idea
- **Tiny projects**: Direct instantiation is fine
