# Microservices Architecture

Independent, loosely-coupled services each handling one business capability, deployed separately, communicating via APIs and events. Each service owns its data.

## When to Use It

- **Independent scaling**: Some services need 100x more capacity than others
- **Polyglot stack**: Different services use different technologies
- **Independent deployment**: Teams deploy without coordinating
- **Fault isolation**: One service crashes, others continue
- **Large teams**: 50+ engineers on same domain

## BEFORE Going Microservices

You probably don't need microservices if:
- Single team
- Monolith is fast enough
- Deploy less than once per day
- <100 engineers
- No polyglot needs

**Rule of thumb**: Start with feature-driven monolith. Extract to microservices when pain is undeniable.

## Service Boundaries

Services own:
- Database(s) - no shared databases
- Source code - separate repository
- Deployment - independent schedule
- Team - single team owns top-to-bottom

```
User Service          Payment Service       Notification Service
├── user.db          ├── payment.db        ├── notification.db
├── src/             ├── src/              ├── src/
├── package.json     ├── package.json      ├── package.json
└── Dockerfile       └── Dockerfile        └── Dockerfile
```

## Communication Patterns

### Synchronous: REST + HTTP

```typescript
// payment-service/src/routes.ts
app.post('/payments', async (request, reply) => {
  const user = await userService.getUserById(request.body.userId);
  if (!user) return reply.code(404);
  // ...
});

// user-service/src/lib/client.ts
export const paymentServiceClient = {
  async createPayment(userId: string, amount: number) {
    const response = await fetch(
      `${process.env.PAYMENT_SERVICE_URL}/payments`,
      {
        method: 'POST',
        body: JSON.stringify({ userId, amount }),
      },
    );
    return response.json();
  },
};
```

### Asynchronous: Message Queue

```typescript
// user-service: Publish event when user created
app.post('/users', async (request, reply) => {
  const user = await db.user.create({ data: request.body });

  // Publish event - consumers decide what to do
  await messageQueue.publish('user.created', {
    userId: user.id,
    email: user.email,
  });

  return reply.code(201).send(user);
});

// notification-service: Subscribe to user.created
messageQueue.subscribe('user.created', async (event) => {
  await emailService.send({
    to: event.email,
    subject: 'Welcome!',
  });
});

// analytics-service: Also subscribes
messageQueue.subscribe('user.created', async (event) => {
  await analytics.track('user_signup', { userId: event.userId });
});
```

## Folder Structure (Mono-Repo)

```
services/
├── user-service/
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── package.json
├── payment-service/
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── package.json
├── notification-service/
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── package.json
└── docker-compose.yml
```

## Testing Services

```typescript
// payment-service/__tests__/integration.test.ts
describe('Payment Service', () => {
  let app: FastifyInstance;
  let paymentDb: PrismaClient;

  beforeAll(async () => {
    // Start isolated database
    const container = await startContainer('postgres');
    paymentDb = new PrismaClient({
      datasources: { db: { url: container.url } },
    });

    app = setupApp(paymentDb);
    await app.listen();
  });

  it('creates payment', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/payments',
      payload: { userId: 'user-123', amount: 100 },
    });

    expect(response.statusCode).toBe(201);
  });

  afterAll(async () => {
    await app.close();
  });
});
```

## Service Discovery

```typescript
// config/services.ts
export const services = {
  user: process.env.USER_SERVICE_URL || 'http://user-service:3001',
  payment: process.env.PAYMENT_SERVICE_URL || 'http://payment-service:3002',
  notification:
    process.env.NOTIFICATION_SERVICE_URL || 'http://notification-service:3003',
};
```

## Deployment: Docker + Orchestration

```dockerfile
# payment-service/Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY src ./src
EXPOSE 3002
CMD ["node", "src/main.ts"]
```

```yaml
# docker-compose.yml (development)
version: '3.8'
services:
  user-service:
    build: ./services/user-service
    ports:
      - '3001:3001'
    environment:
      DATABASE_URL: postgresql://postgres:password@user-db:5432/users
    depends_on:
      - user-db

  payment-service:
    build: ./services/payment-service
    ports:
      - '3002:3002'
    environment:
      DATABASE_URL: postgresql://postgres:password@payment-db:5432/payments
      USER_SERVICE_URL: http://user-service:3001
    depends_on:
      - payment-db

  user-db:
    image: postgres:16
    environment:
      POSTGRES_DB: users
      POSTGRES_PASSWORD: password

  payment-db:
    image: postgres:16
    environment:
      POSTGRES_DB: payments
      POSTGRES_PASSWORD: password

  rabbitmq:
    image: rabbitmq:4-management
    ports:
      - '5672:5672'
      - '15672:15672'
```

## Distributed Tracing

```typescript
// Trace requests across services
import { trace } from '@opentelemetry/api';

const tracer = trace.getTracer('payment-service');

app.post('/payments', async (request, reply) => {
  const span = tracer.startSpan('create_payment');

  span.addEvent('fetching_user');
  const user = await userService.getUser(request.body.userId);

  span.addEvent('processing_payment');
  const result = await stripe.charges.create({...});

  span.end();
  return reply.send(result);
});
```

## Monorepo vs Separate Repos

| Aspect | Monorepo | Separate |
|--------|----------|----------|
| **Coordination** | Easier cross-service PRs | Independent changes |
| **Testing** | Test all services together | Each service isolated |
| **Deployment** | Shared CI/CD | Independent CI/CD |
| **Build time** | Slower | Faster per service |
| **Best for** | <10 services | >10 services |

## Red Flags: Time to Split

1. Services have different scaling requirements
2. Different teams own services
3. Services have conflicting dependencies
4. Service is 100k+ LOC

Don't split just because the tutorial shows it.
