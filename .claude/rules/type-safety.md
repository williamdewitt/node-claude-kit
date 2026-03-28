# Type Safety Rule

## Enforcement

Use strict TypeScript mode. No `any` type. Exhaustive type guards. Proper generics. Let TypeScript catch errors at compile time, not runtime.

## Strict Mode

Always enable in tsconfig.json:

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

## Never Use `any`

**BAD** - Bypasses type safety
```typescript
const handleData = (data: any) => {
  return data.property.nested.value;
};
```

**GOOD** - Explicit typing
```typescript
interface DataShape {
  property: {
    nested: {
      value: string;
    };
  };
}

const handleData = (data: DataShape) => {
  return data.property.nested.value;
};
```

## Exhaustive Type Guards

**BAD** - Missing cases
```typescript
const format = (value: User | Order | Product) => {
  if (value instanceof User) {
    return value.email;
  }
  if (value instanceof Order) {
    return value.id;
  }
  // Product case missing - compiles anyway
};
```

**GOOD** - Exhaustive checking
```typescript
const format = (value: User | Order | Product): string => {
  if (value instanceof User) {
    return value.email;
  }
  if (value instanceof Order) {
    return value.id;
  }
  if (value instanceof Product) {
    return value.sku;
  }
  const _exhaustive: never = value;
  throw new UnexpectedTypeError(`Unhandled type: ${_exhaustive}`);
};
```

## Discriminated Unions Over Inheritance

**BAD** - Class hierarchies
```typescript
class ApiResponse {}
class SuccessResponse extends ApiResponse {
  data: any;
}
class ErrorResponse extends ApiResponse {
  error: any;
}
```

**GOOD** - Discriminated unions
```typescript
type ApiResponse = 
  | { status: 'success'; data: unknown }
  | { status: 'error'; error: string };

const handleResponse = (response: ApiResponse) => {
  switch (response.status) {
    case 'success':
      return response.data;
    case 'error':
      return response.error;
  }
};
```

## Generics Over Unions

**BAD** - Unclear parameter types
```typescript
const cache = new Map<string, any>();
const getValue = (key: string): any => cache.get(key);
```

**GOOD** - Generic with proper type safety
```typescript
const cache = new Map<string, unknown>();

const getValue = <T>(key: string, defaultValue: T): T => {
  const value = cache.get(key);
  return typeof value !== 'undefined' ? (value as T) : defaultValue;
};

// Usage
const userId = getValue<string>('user_id', '');
const count = getValue<number>('count', 0);
```

## Type Narrow Properly

**BAD** - Incomplete narrowing
```typescript
const getName = (user: User | null) => {
  if (user) {
    return user.name; // What if user.name is null?
  }
};
```

**GOOD** - Full narrowing
```typescript
const getName = (user: User | null): string => {
  if (!user) {
    throw new ValidationError('User is required');
  }
  if (!user.name) {
    throw new ValidationError('User name is required');
  }
  return user.name; // Now guaranteed non-null string
};
```

## Const Assertions for Literals

**BAD** - Type widening
```typescript
const roles = ['admin', 'user'];
// roles is string[] not ['admin', 'user']

const config = {
  maxRetries: 3,
  timeout: 5000,
};
// config is { maxRetries: number; timeout: number }
```

**GOOD** - Literal types
```typescript
const roles = ['admin', 'user'] as const;
// roles is readonly ['admin', 'user']

const config = {
  maxRetries: 3,
  timeout: 5000,
} as const;
// config.maxRetries is 3 not number
```

## Function Return Types

Always explicit:

```typescript
// GOOD
export const createUser = async (data: CreateUserInput): Promise<User> => { /* ... */ };
export const getUserById = (id: string): User | null => { /* ... */ };
export const sendEmail = async (to: string): Promise<void> => { /* ... */ };
```

## Exception

Use `unknown` as escape hatch only in error catching:

```typescript
try {
  // ...
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  logger.error(message);
}
```

