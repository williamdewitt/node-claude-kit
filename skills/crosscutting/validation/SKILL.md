# Input Validation with Zod

Runtime validation of user input, API payloads, and configuration with TypeScript integration.

## Basic Validation with Zod

```bash
npm install zod
```

```typescript
// lib/schemas.ts
import { z } from 'zod';

// User schemas
export const CreateUserSchema = z.object({
  email: z.string().email('Invalid email'),
  name: z.string().min(2).max(100),
  password: z.string().min(8).regex(/[A-Z]/, 'Must contain uppercase'),
});

export type CreateUserInput = z.infer<typeof CreateUserSchema>;

// Post schemas
export const CreatePostSchema = z.object({
  title: z.string().min(5).max(200),
  content: z.string().min(10),
  published: z.boolean().default(false),
});

// List query schemas
export const PaginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});
```

## API Route Validation

```typescript
// app/api/users/route.ts
import { CreateUserSchema } from '@/lib/schemas';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const body = await request.json();

  // Parse and validate
  const parsed = CreateUserSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(
      {
        error: 'Validation failed',
        issues: parsed.error.flatten(),
      },
      { status: 400 },
    );
  }

  const { email, name, password } = parsed.data;

  // Create user...
}
```

## Custom Error Messages

```typescript
// lib/schemas.ts
export const CreateUserSchema = z.object({
  email: z
    .string({ required_error: 'Email is required' })
    .email('Please enter a valid email address'),

  name: z
    .string({ required_error: 'Name is required' })
    .min(2, 'Name must be at least 2 characters')
    .max(100, 'Name must not exceed 100 characters'),

  password: z
    .string({ required_error: 'Password is required' })
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),

  confirmPassword: z.string(),
}).refine(data => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
});
```

## Conditional Validation

```typescript
export const UpdatePostSchema = z.object({
  title: z.string().optional(),
  content: z.string().optional(),
  published: z.boolean().optional(),
  publishedAt: z.date().optional(),
}).refine(
  data => {
    // If publishing, publishedAt must be provided
    if (data.published && !data.publishedAt) {
      return false;
    }
    return true;
  },
  {
    message: 'publishedAt is required when publishing',
    path: ['publishedAt'],
  },
);
```

## Pre-Processing Input

```typescript
export const UserFilterSchema = z.object({
  name: z.string().trim().optional(),
  status: z.enum(['active', 'inactive']).optional(),
  createdAfter: z
    .string()
    .datetime()
    .pipe(z.coerce.date())
    .optional(),
});

// Input: { name: '  alice  ', status: 'active' }
// Output: { name: 'alice', status: 'active' }
```

## Array and Union Validation

```typescript
// Multiple types
export const SearchQuerySchema = z.object({
  q: z.string(),
  type: z.enum(['user', 'post', 'comment']),
  categories: z.array(z.string()).optional(),
  sortBy: z.union([
    z.literal('relevance'),
    z.literal('date'),
    z.literal('popularity'),
  ]),
});

// Dynamic discriminated union
export const EventSchema = z.discriminatedUnion('type', [
  z.object({
    type: z.literal('user.created'),
    userId: z.string(),
  }),
  z.object({
    type: z.literal('post.published'),
    postId: z.string(),
  }),
]);
```

## Async Validation

```typescript
export const CreateUserSchema = z.object({
  email: z
    .string()
    .email()
    .refine(
      async (email) => {
        // Check if email already exists
        const existing = await db.user.findUnique({
          where: { email },
        });
        return !existing;
      },
      {
        message: 'Email already registered',
      },
    ),

  username: z
    .string()
    .min(3)
    .refine(
      async (username) => {
        const available = await isUsernameAvailable(username);
        return available;
      },
      'Username already taken',
    ),
});

// Parse with async validation
const result = await CreateUserSchema.parseAsync(body);
```

## Error Handling Middleware

```typescript
// middleware/validation.ts
import { NextRequest, NextResponse } from 'next/server';
import { ZodSchema } from 'zod';

export function withValidation(schema: ZodSchema) {
  return async (request: NextRequest) => {
    try {
      const body = await request.json();
      const data = await schema.parseAsync(body);

      // Attach validated data to request
      (request as any).validated = data;

      return undefined; // Continue to handler
    } catch (error) {
      if (error instanceof ZodError) {
        return NextResponse.json(
          {
            error: 'Validation failed',
            details: error.flatten(),
          },
          { status: 400 },
        );
      }

      throw error;
    }
  };
}

// Usage in route
export async function POST(request: NextRequest) {
  const validationError = await withValidation(CreateUserSchema)(request);
  if (validationError) return validationError;

  const data = (request as any).validated;
  // data is now validated and typed
}
```

## Testing Validation

```typescript
// lib/schemas.test.ts
import { describe, it, expect } from 'vitest';
import { CreateUserSchema } from './schemas';

describe('CreateUserSchema', () => {
  it('validates correct input', () => {
    const result = CreateUserSchema.safeParse({
      email: 'test@example.com',
      name: 'Test User',
      password: 'SecurePass123',
    });

    expect(result.success).toBe(true);
  });

  it('rejects invalid email', () => {
    const result = CreateUserSchema.safeParse({
      email: 'not-an-email',
      name: 'Test User',
      password: 'SecurePass123',
    });

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.flatten().fieldErrors.email).toBeDefined();
    }
  });

  it('requires uppercase in password', () => {
    const result = CreateUserSchema.safeParse({
      email: 'test@example.com',
      name: 'Test User',
      password: 'securepass123', // No uppercase
    });

    expect(result.success).toBe(false);
  });
});
```

## Common Validation Patterns

```typescript
// Email
z.string().email()

// URL
z.string().url()

// Positive integer
z.number().int().positive()

// Enum
z.enum(['active', 'inactive', 'pending'])

// Date
z.date() // Already a date
z.string().datetime() // ISO 8601

// Optional with default
z.string().optional().default('default value')

// Array of items
z.array(z.string()).min(1).max(10)

// Record/object with unknown keys
z.record(z.string(), z.number())

// Nullable
z.string().nullable()

// Union
z.union([z.string(), z.number()])
```

## Best Practices

1. **Fail fast**: Validate at entry point
2. **Type safety**: Use `z.infer<typeof Schema>`
3. **Custom messages**: Help users understand errors
4. **Async validation**: Check uniqueness async
5. **Pre-process**: Trim, lowercase, etc.
6. **Test schemas**: Validate edge cases
7. **Document constraints**: Comment on why limits exist
