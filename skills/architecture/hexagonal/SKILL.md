# Hexagonal Architecture (Ports & Adapters)

Hexagonal architecture isolates core business logic from infrastructure dependencies (databases, APIs, external services). Dependencies point inward—external code depends on domain code, never vice versa.

## When to Use It

- **Complex domain logic**: Business rules that need testing without infrastructure
- **Multiple interfaces**: CLI, REST API, GraphQL, webhooks all serving same domain
- **External API integrations**: Stripe, SendGrid, etc. need to be swappable
- **High-risk projects**: Payment systems, compliance-heavy domains

## Core Concepts

### Ports (Interfaces)
Contracts that external code must implement. Domain code depends on ports, not concrete implementations.

### Adapters (Implementations)
Concrete implementations of ports for specific technologies (PostgreSQL, Stripe API, etc).

## Folder Structure

```
src/
├── domain/                      // Core business logic (zero dependencies)
│   ├── user/
│   │   ├── user.ts             // Domain model
│   │   ├── user.errors.ts       // Domain errors
│   │   └── user.service.ts      // Business logic
│   └── payment/
│       ├── payment.ts
│       ├── payment.errors.ts
│       └── payment.service.ts
├── ports/                       // Interfaces (owned by domain)
│   ├── user-repository.port.ts
│   ├── payment-processor.port.ts
│   ├── email-service.port.ts
│   └── logger.port.ts
├── adapters/                    // Implementations
│   ├── repositories/
│   │   └── prisma-user.repository.ts
│   ├── payment/
│   │   └── stripe-payment.adapter.ts
│   ├── email/
│   │   └── sendgrid-email.adapter.ts
│   └── logging/
│       └── pino-logger.adapter.ts
├── interfaces/                  // API entry points
│   ├── http/
│   │   ├── routes.ts
│   │   └── controllers/
│   └── cli/
│       └── commands.ts
└── main.ts
```

## Example: Payment Processing

```typescript
// domain/payment/payment.ts
export interface Payment {
  id: string;
  userId: string;
  amount: number;
  status: 'pending' | 'completed' | 'failed';
  createdAt: Date;
}

// ports/payment-processor.port.ts (domain owns this)
export interface PaymentProcessor {
  process(amount: number, currency: string): Promise<Result<string, PaymentError>>;
  refund(transactionId: string): Promise<Result<void, RefundError>>;
}

// domain/payment/payment.service.ts (zero infrastructure dependencies)
export async function createPayment(
  userId: string,
  amount: number,
  processor: PaymentProcessor, // Injected port
): Promise<Result<Payment, PaymentError>> {
  if (amount <= 0) return Err(new InvalidAmountError());

  const txId = await processor.process(amount, 'USD');
  if (!txId.ok) return Err(txId.error);

  return Ok({
    id: generateId(),
    userId,
    amount,
    status: 'completed',
    createdAt: new Date(),
  });
}

// adapters/payment/stripe-payment.adapter.ts (infrastructure)
import Stripe from 'stripe';

export class StripePaymentAdapter implements PaymentProcessor {
  constructor(private stripe: Stripe) {}

  async process(
    amount: number,
    currency: string,
  ): Promise<Result<string, PaymentError>> {
    try {
      const charge = await this.stripe.charges.create({
        amount: Math.round(amount * 100),
        currency,
      });
      return Ok(charge.id);
    } catch (error) {
      return Err(new PaymentProcessingError(error));
    }
  }

  async refund(transactionId: string): Promise<Result<void, RefundError>> {
    try {
      await this.stripe.refunds.create({ charge: transactionId });
      return Ok(undefined);
    } catch (error) {
      return Err(new RefundError(error));
    }
  }
}

// adapters/payment/mock-payment.adapter.ts (for testing)
export class MockPaymentAdapter implements PaymentProcessor {
  async process(): Promise<Result<string, PaymentError>> {
    return Ok('mock-tx-123');
  }

  async refund(): Promise<Result<void, RefundError>> {
    return Ok(undefined);
  }
}

// interfaces/http/routes.ts
app.post('/payments', async (request, reply) => {
  const { amount } = request.body;

  const result = await createPayment(
    request.user.id,
    amount,
    container.get(PaymentProcessor), // Dependency injection
  );

  if (!result.ok) {
    return reply.code(400).send({ error: result.error.message });
  }

  return reply.code(201).send(result.value);
});
```

## BAD: Infrastructure Bleeding

```typescript
// ❌ Domain depends on Prisma (infrastructure)
import { PrismaClient } from '@prisma/client';

export async function createPayment(
  userId: string,
  amount: number,
  db: PrismaClient,
) {
  const payment = await db.payment.create({
    data: { userId, amount },
  });
  return payment;
}
```

**Problems**:
- Can't test without database
- Can't use with different database
- Domain is tightly coupled to ORM

## GOOD: Inverted Dependencies

```typescript
// ✅ Domain defines interface, adapters implement it
export interface PaymentRepository {
  create(payment: Payment): Promise<Payment>;
}

// Test with mock
const mockRepo: PaymentRepository = {
  create: async (p) => ({ ...p, id: 'test-123' }),
};

// Production with Prisma
class PrismaPaymentRepository implements PaymentRepository {
  constructor(private db: PrismaClient) {}

  async create(payment: Payment) {
    return this.db.payment.create({ data: payment });
  }
}
```

## When Hexagonal Is Overkill

- Simple CRUD APIs with no business logic
- Prototypes and MVPs
- Single-adapter projects (only one database, no external APIs)

Use feature-driven architecture for these.

## Combining with Feature-Driven

Large projects often combine both:

```
src/
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   ├── ports/
│   │   └── adapters/
│   └── payments/
│       ├── domain/
│       ├── ports/
│       └── adapters/
```
