# Coding Style Rule

## Enforcement

Use modern ESM syntax, const-first declarations, arrow functions, destructuring, and semantic naming. Write code that's immediately readable to any Node.js developer.

## What This Means

### ESM (ECMAScript Modules)

**BAD** - CommonJS patterns
```javascript
const express = require('express');
const { Router } = require('express');
module.exports = app;
```

**GOOD** - ESM patterns
```typescript
import express from 'express';
import { Router } from 'express';
export const app = express();
```

### Const-First Declaration

**BAD** - Let/var without reason
```typescript
let user = fetchUser();
let count = 0;
```

**GOOD** - Const unless reassignment is necessary
```typescript
const user = fetchUser();
const count = 0;

// Only use let when truly needed
let retries = 3;
while (retries-- > 0) { /* ... */ }
```

### Arrow Functions

**BAD** - Function declarations for callbacks
```typescript
const items = data.map(function(item) {
  return item.price * 2;
});

class Handler {
  handle() {
    setTimeout(function() {
      this.process();
    }, 1000);
  }
}
```

**GOOD** - Arrow functions with lexical this
```typescript
const items = data.map((item) => item.price * 2);

const handler = () => {
  setTimeout(() => {
    process();
  }, 1000);
};
```

### Destructuring

**BAD** - Accessing properties repeatedly
```typescript
const user = getUser();
const name = user.profile.name;
const email = user.profile.email;
const phone = user.phone;
```

**GOOD** - Destructure at assignment
```typescript
const { profile: { name, email }, phone } = getUser();

// Or inline
function createOrder({ customerId, items, notes }: CreateOrderDto) {
  // Use customerId, items, notes directly
}
```

### Semantic Naming

**BAD** - Non-descriptive names
```typescript
const x = getUserData();
const fn = (d) => d.age > 18;
const temp = data.filter(fn);
```

**GOOD** - Descriptive names that explain intent
```typescript
const user = getUserData();
const isAdult = (person) => person.age > 18;
const adults = users.filter(isAdult);

// or inline if obvious
const adults = users.filter((user) => user.age > 18);
```

## Type Annotations

Always include type annotations in function signatures and complex declarations:

```typescript
// GOOD - Clear input/output types
const calculateTotal = (items: OrderItem[]): number => {
  return items.reduce((sum, item) => sum + item.price * item.qty, 0);
};

const fetchUser = async (id: string): Promise<User | null> => {
  // ...
};
```

## Line Length

Keep lines under 100 characters. Break long chains across lines:

```typescript
// GOOD - Readable chains
const activeAdults = users
  .filter((user) => user.active)
  .filter((user) => user.age > 18)
  .map((user) => ({ id: user.id, name: user.name }));
```

## File Organization

```typescript
// 1. Imports
import type { User } from './types';
import { db } from './db';

// 2. Types/Interfaces
export interface CreateUserInput {
  email: string;
  name: string;
}

// 3. Constants
const RATE_LIMIT = 100;

// 4. Utilities/Helpers
const isValidEmail = (email: string): boolean => {
  // ...
};

// 5. Main functions/exports
export const createUser = async (input: CreateUserInput): Promise<User> => {
  // ...
};
```

## String Formatting

Use template literals, not string concatenation:

```typescript
// BAD
const message = 'Hello ' + name + ', welcome to ' + app;

// GOOD
const message = `Hello ${name}, welcome to ${app}`;
```

## Exceptions

None. These patterns are fundamental to readable modern Node.js code.

## Related Skills

- [typescript-patterns](../skills/language/typescript-patterns/SKILL.md)
- [modern-javascript](../skills/language/modern-javascript/SKILL.md)

