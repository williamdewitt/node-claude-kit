# Error Handling Rule

## Enforcement

Use custom Error subclasses for domain-specific errors. Never swallow exceptions. Use Result pattern for expected failures. Provide context in error messages.

## Custom Error Subclasses

**BAD** - Generic Error class
```typescript
throw new Error('Order not found');
throw new Error('Invalid email format');
throw new Error('Database connection failed');
```

**GOOD** - Typed Error hierarchy
```typescript
export class ApplicationError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends ApplicationError {
  constructor(message: string, options?: ErrorOptions) {
    super(message, 'VALIDATION_ERROR', 400, options);
  }
}

export class NotFoundError extends ApplicationError {
  constructor(message: string, options?: ErrorOptions) {
    super(message, 'NOT_FOUND', 404, options);
  }
}

export class DatabaseError extends ApplicationError {
  constructor(message: string, options?: ErrorOptions) {
    super(message, 'DATABASE_ERROR', 500, options);
  }
}

// Usage
throw new NotFoundError('User not found');
throw new ValidationError('Email is required');
```

## Result Pattern for Expected Errors

**BAD** - Exceptions for control flow
```typescript
const createUser = async (data: CreateUserInput) => {
  if (!data.email.includes('@')) {
    throw new ValidationError('Invalid email');
  }
  
  const existing = await db.user.findUnique({ where: { email: data.email } });
  if (existing) {
    throw new ConflictError('Email already in use');
  }
  
  return await db.user.create({ data });
};
```

**GOOD** - Result pattern
```typescript
type Result<T, E = Error> = 
  | { ok: true; value: T }
  | { ok: false; error: E };

const createUser = async (data: CreateUserInput): Promise<Result<User>> => {
  // Validate
  if (!data.email.includes('@')) {
    return { ok: false, error: new ValidationError('Invalid email') };
  }
  
  // Check existence
  const existing = await db.user.findUnique({ where: { email: data.email } });
  if (existing) {
    return { ok: false, error: new ConflictError('Email already in use') };
  }
  
  // Create
  const user = await db.user.create({ data });
  return { ok: true, value: user };
};

// Usage
const result = await createUser(input);
if (!result.ok) {
  return reply.code(result.error.statusCode).send(result.error);
}
return reply.send(result.value);
```

## Never Ignore Errors

**BAD** - Silent failures
```typescript
db.order.create({ data: order }).catch(() => {});

const email = getEmail(user).catch(() => 'unknown');
```

**GOOD** - Explicit error handling
```typescript
try {
  await db.order.create({ data: order });
} catch (error) {
  logger.error('Failed to create order', { error, order });
  throw new DatabaseError('Order creation failed', { cause: error });
}

const email = await getEmail(user)
  .catch((error) => {
    logger.error('Failed to get email', { error });
    throw error;
  });
```

## Error Context

**BAD** - Generic message
```typescript
throw new Error('Failed');
```

**GOOD** - Specific context
```typescript
throw new DatabaseError('Failed to update user order status', {
  cause: originalError,
});

// In logs
logger.error('User creation failed', {
  error,
  input: { email, name },
  statusCode: error.statusCode,
  correlationId: req.id,
});
```

## Structured Error Responses

```typescript
type ErrorResponse = {
  code: string;
  message: string;
  timestamp: string;
  path: string;
  details?: Record<string, unknown>;
};

const errorHandler = (error: Error, request: FastifyRequest) => {
  if (error instanceof ApplicationError) {
    return {
      code: error.code,
      message: error.message,
      timestamp: new Date().toISOString(),
      path: request.url,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined,
    };
  }
  
  // Unknown error
  return {
    code: 'INTERNAL_ERROR',
    message: 'An unexpected error occurred',
    timestamp: new Date().toISOString(),
    path: request.url,
  };
};
```

