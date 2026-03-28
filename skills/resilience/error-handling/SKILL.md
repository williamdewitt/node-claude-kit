# Error Handling Skill

## When to Use

Every part of your application that can fail. Proper error handling is critical for production reliability.

## Error Subclasses

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
  constructor(message: string, issues?: object) {
    super(message, 'VALIDATION_ERROR', 400);
    this.issues = issues;
  }
}

export class NotFoundError extends ApplicationError {
  constructor(message: string) {
    super(message, 'NOT_FOUND', 404);
  }
}

export class ConflictError extends ApplicationError {
  constructor(message: string) {
    super(message, 'CONFLICT', 409);
  }
}

export class DatabaseError extends ApplicationError {
  constructor(message: string, cause?: Error) {
    super(message, 'DATABASE_ERROR', 500, { cause });
  }
}
```

## Result Pattern

```typescript
export type Result<T, E = ApplicationError> = 
  | { ok: true; value: T }
  | { ok: false; error: E };

export const ok = <T>(value: T): Result<T> => ({ ok: true, value });
export const err = <E>(error: E): Result<unknown, E> => ({ ok: false, error });

// Usage
const createUser = async (input: CreateUserInput): Promise<Result<User>> => {
  // Validation
  if (!input.email.includes('@')) {
    return err(new ValidationError('Invalid email'));
  }
  
  // Business logic
  const existing = await db.user.findUnique({ where: { email: input.email } });
  if (existing) {
    return err(new ConflictError('Email already in use'));
  }
  
  const user = await db.user.create({ data: input });
  return ok(user);
};

// In handler
const result = await createUser(input);
if (!result.ok) {
  return reply.code(result.error.statusCode).send(result.error);
}
return reply.send(result.value);
```

## Never Swallow Errors

```typescript
// GOOD - Re-throw with context
const saveOrder = async (order: Order): Promise<Order> => {
  try {
    return await db.order.create({ data: order });
  } catch (error) {
    logger.error('Order creation failed', { order, error });
    throw new DatabaseError('Could not save order', { cause: error as Error });
  }
};

// BAD - Error lost
const saveOrder = async (order: Order) => {
  try {
    await db.order.create({ data: order });
  } catch (error) {
    // Error disappears
  }
};
```

