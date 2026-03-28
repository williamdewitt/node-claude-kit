# Distributed Tracing for Full-Stack Applications

Tracking requests across services with OpenTelemetry, connecting frontend actions to backend operations.

## Why Distributed Tracing

In microservices, a single user action spans multiple services:
- API Request → Auth Service → User Service → Payment Service → Notification Service

Without tracing, you can't see the complete picture. Debugging is slow.

## Setup with OpenTelemetry

```bash
npm install @opentelemetry/api @opentelemetry/sdk-node @opentelemetry/auto \
  @opentelemetry/exporter-trace-otlp-http @opentelemetry/resources \
  @opentelemetry/semantic-conventions
```

```typescript
// instrumentation.ts (runs at app startup)
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

const traceExporter = new OTLPTraceExporter({
  url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces',
});

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'user-service',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
  }),
  traceExporter,
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
console.log('Tracing started');
```

## Creating Spans

```typescript
// lib/tracing.ts
import { trace } from '@opentelemetry/api';

const tracer = trace.getTracer('user-service', '1.0.0');

export async function createUser(email: string, name: string) {
  // Create root span
  const span = tracer.startSpan('create_user', {
    attributes: {
      'user.email': email,
      'db.system': 'postgresql',
    },
  });

  try {
    // Add event
    span.addEvent('validating_input');
    validateEmail(email);

    // Create child span
    const dbSpan = tracer.startSpan('db.insert', {
      parent: span,
      attributes: {
        'db.operation': 'insert',
        'db.table': 'users',
      },
    });

    const user = await db.user.create({ data: { email, name } });
    dbSpan.end();

    span.setStatus({ code: 0 }); // Success
    return user;
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: 2, message: error.message });
    throw error;
  } finally {
    span.end();
  }
}
```

## Fastify Middleware for Request Tracing

```typescript
// lib/trace-middleware.ts
import { FastifyRequest, FastifyReply } from 'fastify';
import { trace, context, propagation } from '@opentelemetry/api';

const tracer = trace.getTracer('api');

export async function traceRequest(
  request: FastifyRequest,
  reply: FastifyReply,
) {
  // Extract trace context from headers (for distributed tracing)
  const tracingContext = propagation.extract(
    context.active(),
    request.headers,
  );

  // Create span for this request
  const span = tracer.startSpan(
    `${request.method} ${request.url}`,
    {
      attributes: {
        'http.method': request.method,
        'http.url': request.url,
        'http.user_agent': request.headers['user-agent'],
      },
    },
    tracingContext,
  );

  // Add trace ID to response for client tracking
  reply.header('x-trace-id', span.spanContext().traceId);

  reply.addHook('onResponse', async () => {
    span.setAttributes({
      'http.status_code': reply.statusCode,
    });
    span.end();
  });
}

// app.ts
app.addHook('preHandler', traceRequest);
```

## Cross-Service Tracing

```typescript
// services/user-service/routes.ts
import { trace, propagation } from '@opentelemetry/api';

app.post<{ Body: CreateUserInput }>('/users', async (request, reply) => {
  const span = tracer.startSpan('handle_create_user');

  try {
    const user = await createUser(request.body);

    // Call another service while propagating trace
    const paymentSpan = tracer.startSpan('call_payment_service');

    const headers = {};
    propagation.inject(context.active(), headers);

    const subscription = await fetch(
      `${process.env.PAYMENT_SERVICE_URL}/subscriptions`,
      {
        method: 'POST',
        headers,
        body: JSON.stringify({ userId: user.id }),
      },
    );

    paymentSpan.end();

    return reply.code(201).send(user);
  } finally {
    span.end();
  }
});
```

## Tracing Database Queries

```typescript
// lib/db.ts
import { PrismaClient } from '@prisma/client';
import { tracer } from './tracing';

const db = new PrismaClient({
  log: [{ level: 'query', emit: 'stdout' }],
});

// Add tracing middleware
db.$use(async (params, next) => {
  const span = tracer.startSpan('db_query', {
    attributes: {
      'db.model': params.model,
      'db.action': params.action,
    },
  });

  try {
    const result = await next(params);
    span.addEvent('query_success');
    return result;
  } catch (error) {
    span.recordException(error);
    throw error;
  } finally {
    span.end();
  }
});

export { db };
```

## Client-Side Tracing

```typescript
// app/lib/tracing.ts (client)
export class ClientTracer {
  private traceId = generateTraceId();

  async fetch<T>(url: string, options?: RequestInit): Promise<T> {
    const spanId = generateSpanId();
    const startTime = performance.now();

    try {
      const response = await fetch(url, {
        ...options,
        headers: {
          ...options?.headers,
          'x-trace-id': this.traceId,
          'x-span-id': spanId,
        },
      });

      const duration = performance.now() - startTime;
      this.recordMetric('api_request', {
        url,
        status: response.status,
        duration,
        method: options?.method || 'GET',
      });

      return response.json();
    } catch (error) {
      this.recordError('api_error', error, { url });
      throw error;
    }
  }

  private recordMetric(name: string, data: Record<string, any>) {
    // Send to analytics service
    console.log(`[${name}]`, data);
  }

  private recordError(
    name: string,
    error: any,
    context: Record<string, any>,
  ) {
    console.error(`[${name}]`, error, context);
  }
}

export const tracer = new ClientTracer();
```

## Using in React Components

```typescript
// app/components/create-user-form.tsx
'use client';
import { tracer } from '@/lib/tracing';

export function CreateUserForm() {
  async function handleSubmit(formData: FormData) {
    const startTime = performance.now();

    try {
      await tracer.fetch('/api/users', {
        method: 'POST',
        body: formData,
      });

      const duration = performance.now() - startTime;
      console.log(`User created in ${duration}ms`);
    } catch (error) {
      console.error('Failed to create user:', error);
    }
  }

  return <form action={handleSubmit}>...</form>;
}
```

## Visualization

Use Jaeger or Zipkin to visualize traces:

```bash
# Docker Compose for local tracing
docker run -d -p 16686:16686 jaegertracing/all-in-one
```

Then visit http://localhost:16686 to see traces.

## Best Practices

1. **Create spans for operations > 100ms**: Avoid noise
2. **Use meaningful span names**: "db.insert" not "query"
3. **Add relevant attributes**: Context helps debugging
4. **Propagate context across services**: Use standard headers
5. **Sample in production**: Don't trace 100% of requests
6. **Monitor trace volume**: Tracing has overhead

## Sampling Strategy

```typescript
// Only trace 1% of requests in production
const sampler = new TraceIdRatioBasedSampler(
  process.env.NODE_ENV === 'production' ? 0.01 : 1.0,
);

const sdk = new NodeSDK({
  sampler,
  // ...
});
```
