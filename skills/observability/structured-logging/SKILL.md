# Structured Logging Skill

## When to Use

Every application. Use Pino for high-performance structured logging.

## Setup

```typescript
import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV === 'development' 
    ? { target: 'pino-pretty', options: { colorize: true } }
    : undefined,
});
```

## Logging Levels

```typescript
logger.debug({ data }, 'Debug information');        // Development only
logger.info({ action }, 'Informational');           // Normal operations
logger.warn({ issue }, 'Warning');                  // Should investigate
logger.error({ error }, 'Error occurred');          // Errors
logger.fatal({ issue }, 'Fatal error');             // Application fatal
```

## Structured Context

```typescript
// BAD - Unstructured
logger.info(`User ${userId} created order ${orderId}`);

// GOOD - Structured fields
logger.info({
  userId,
  orderId,
  total: order.total,
  itemCount: order.items.length,
  action: 'order_created',
}, 'Order successfully created');
```

## Child Loggers with Context

```typescript
// In request handler
const childLogger = logger.child({
  requestId: request.id,
  userId: request.user?.id,
  path: request.url,
});

childLogger.info('Request received');
// Output includes requestId and userId in all logs
```

## Error Logging

```typescript
try {
  await saveOrder(order);
} catch (error) {
  logger.error({
    error,
    stack: error instanceof Error ? error.stack : undefined,
    order,
    timestamp: new Date().toISOString(),
  }, 'Failed to save order');
}
```

