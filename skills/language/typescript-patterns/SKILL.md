# TypeScript Patterns Skill

## When to Use

Writing TypeScript code. Always use strict mode and proper typing.

## Strict Mode Configuration

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true
  }
}
```

## Type Annotations

Always annotate function signatures:

```typescript
// GOOD
const fetchUser = async (id: string): Promise<User | null> => { /* ... */ };
const calculateTotal = (items: OrderItem[]): number => { /* ... */ };
const greet = (name: string, greeting: string = 'Hello'): void => { /* ... */ };

// BAD
const fetchUser = async (id) => { /* ... */ };
const calculateTotal = (items) => { /* ... */ };
```

## Interfaces vs Types

Use `interface` for object contracts, `type` for unions/aliases:

```typescript
// Objects - use interface
interface User {
  id: string;
  email: string;
  name: string;
}

// Unions/Aliases - use type
type Result<T> = { ok: true; value: T } | { ok: false; error: Error };
type Status = 'active' | 'inactive' | 'pending';
```

## Generics

Use generics for reusable, type-safe utilities:

```typescript
// GOOD
const cached = new Map<string, unknown>();
const getValue = <T>(key: string, defaultValue: T): T => {
  return (cached.get(key) as T) || defaultValue;
};

// BAD
const cached = new Map<string, any>();
const getValue = (key, defaultValue) => {
  return cached.get(key) || defaultValue;
};
```

## Discriminated Unions

Use discriminant fields for type-safe pattern matching:

```typescript
type Response = 
  | { status: 'success'; data: User }
  | { status: 'error'; error: string };

const handle = (response: Response) => {
  switch (response.status) {
    case 'success':
      return response.data.email;
    case 'error':
      return response.error;
  }
};
```

## Avoid

- `any` type - Always be specific
- Deep nesting - Extract to separate types
- Implicit returns - Always explicit
- Function overloads - Use unions instead

