# Serverless-First Architecture

Event-driven, stateless functions triggered by external events (HTTP requests, queues, timers). No servers to manage, automatic scaling, pay-per-execution.

## When to Use It

- **Variable load**: Traffic spikes (daily digest, Black Friday, webhooks)
- **Cost-conscious**: Only pay for actual execution time
- **No persistent state**: Data lives in databases/object storage
- **Simple workflows**: Request → Process → Response
- **Async tasks**: Background jobs, scheduled tasks

## NOT a good fit for:
- Long-running processes (> 15 min)
- Stateful services (WebSockets, persistent connections)
- Real-time systems with <100ms latency requirements

## Folder Structure (AWS Lambda)

```
src/
├── functions/
│   ├── api/
│   │   ├── create-user.handler.ts
│   │   ├── get-user.handler.ts
│   │   └── create-user.test.ts
│   ├── async-tasks/
│   │   ├── process-payment.handler.ts
│   │   └── send-email.handler.ts
│   └── scheduled/
│       ├── daily-digest.handler.ts
│       └── cleanup-old-files.handler.ts
├── lib/
│   ├── database.ts
│   ├── errors.ts
│   └── validation.ts
└── types.ts
```

## Example: API Function

```typescript
// src/functions/api/create-user.handler.ts
import { APIGatewayProxyHandler } from 'aws-lambda';
import { db } from '../../lib/database';
import { CreateUserSchema } from '../../types';

export const handler: APIGatewayProxyHandler = async (event) => {
  // Validate input
  const parsed = CreateUserSchema.safeParse(JSON.parse(event.body || '{}'));
  if (!parsed.success) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Invalid input' }),
    };
  }

  try {
    const user = await db.user.create({
      data: parsed.data,
    });

    return {
      statusCode: 201,
      body: JSON.stringify(user),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to create user' }),
    };
  }
};
```

## Example: Async Handler

```typescript
// src/functions/async-tasks/process-payment.handler.ts
import { SQSHandler } from 'aws-lambda';
import { db } from '../../lib/database';
import { stripe } from '../../lib/stripe';

export const handler: SQSHandler = async (event) => {
  const results = await Promise.allSettled(
    event.Records.map(async (record) => {
      const { paymentId } = JSON.parse(record.body);

      const payment = await db.payment.findUnique({
        where: { id: paymentId },
      });

      if (!payment) return;

      const result = await stripe.charges.create({
        amount: payment.amount,
        currency: payment.currency,
      });

      await db.payment.update({
        where: { id: paymentId },
        data: { stripeId: result.id, status: 'completed' },
      });
    }),
  );

  // Log failures for DLQ
  const failures = results
    .map((r, i) => (r.status === 'rejected' ? i : null))
    .filter((i): i is number => i !== null);

  if (failures.length > 0) {
    console.error(`Failed to process ${failures.length} records`);
  }
};
```

## Key Patterns

### Connection Pooling

```typescript
// src/lib/database.ts
let prisma: PrismaClient;

export function getDb() {
  if (!prisma) {
    prisma = new PrismaClient({
      datasources: {
        db: {
          url: process.env.DATABASE_URL,
        },
      },
    });
  }
  return prisma;
}

// Reuse connection across warm invocations
export const db = getDb();
```

### Environment Variables

```bash
# .env.local
DATABASE_URL=postgresql://...
STRIPE_API_KEY=sk_...
JWT_SECRET=...
NODE_ENV=production
```

```typescript
// src/lib/config.ts
export const config = {
  databaseUrl: process.env.DATABASE_URL!,
  stripeKey: process.env.STRIPE_API_KEY!,
  jwtSecret: process.env.JWT_SECRET!,
  nodeEnv: process.env.NODE_ENV || 'development',
};
```

### Error Handling

```typescript
// ✅ GOOD: Structured errors that API Gateway understands
return {
  statusCode: error instanceof ValidationError ? 400 : 500,
  body: JSON.stringify({
    error: error.message,
    code: error.code,
  }),
};
```

## BAD vs GOOD

```typescript
// ❌ BAD: Storing state in memory
let cache: Map<string, User> = new Map();

export const handler = async () => {
  cache.set('user', user); // Lost on next invocation!
  return cache.get('user');
};

// ✅ GOOD: Store in DynamoDB, ElastiCache, or RDS
export const handler = async () => {
  await cache.set('user', user); // Persists across invocations
  return await cache.get('user');
};
```

```typescript
// ❌ BAD: Synchronous wait (wastes billable time)
await sleep(5000); // 5 seconds of billing!

// ✅ GOOD: Async task that runs separately
await queue.send('send-email', { userId });
// Return immediately, task processes later
```

## Deployment (with IaC)

```typescript
// serverless.yml
functions:
  createUser:
    handler: src/functions/api/create-user.handler
    events:
      - http:
          path: users
          method: post
    environment:
      DATABASE_URL: ${env:DATABASE_URL}

  processPayment:
    handler: src/functions/async-tasks/process-payment.handler
    events:
      - sqs:
          arn: arn:aws:sqs:...
          batchSize: 10

  dailyDigest:
    handler: src/functions/scheduled/daily-digest.handler
    events:
      - schedule: cron(0 9 * * ? *)
```

## Cost Optimization

1. **Connection pooling**: RDS Proxy reduces cold starts
2. **Async processing**: Pay only for actual work
3. **Memory tuning**: More memory = faster CPU = lower cost
4. **Reserved capacity**: Predictable baseline load

## When to Go Back to Monolith

- Adding features slower than expected
- Database costs exceed compute costs
- Team needs shared session state
- Real-time updates (WebSockets)
