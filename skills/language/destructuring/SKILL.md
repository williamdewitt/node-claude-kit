# Destructuring: Modern JavaScript Pattern

Destructuring extracts values from objects and arrays into distinct variables, replacing verbose object/array access patterns. Essential for clean, readable modern JavaScript.

## When to Use It

- **Function parameters**: Extract specific properties
- **Variable assignment**: Unpack object/array values
- **Imports**: Get specific exports
- **Loop variables**: Access multiple properties per iteration
- **Default values**: Provide fallbacks during extraction

## Object Destructuring

### Basic Pattern

```typescript
// ❌ BAD: Verbose property access
const user = { name: 'Alice', email: 'alice@example.com', age: 30 };
const name = user.name;
const email = user.email;

// ✅ GOOD: Destructuring extracts values
const { name, email } = user;
```

### Renaming

```typescript
// ✅ Extract with different variable names
const { name: fullName, email: emailAddress } = user;
```

### Nested Destructuring

```typescript
// ✅ Extract nested properties
const user = {
  name: 'Alice',
  address: { city: 'NYC', zipCode: '10001' },
};

const {
  name,
  address: { city, zipCode },
} = user;
```

### Default Values

```typescript
// ✅ Provide fallbacks
const { name, role = 'user', status = 'active' } = userData;
```

### Rest Pattern

```typescript
// ✅ Collect remaining properties
const { email, ...otherProperties } = user;
// otherProperties = { name, age, ... }
```

## Array Destructuring

### Basic Pattern

```typescript
// ❌ BAD: Index-based access
const arr = ['red', 'green', 'blue'];
const first = arr[0];
const second = arr[1];

// ✅ GOOD: Destructuring
const [first, second] = arr;
```

### Skipping Elements

```typescript
// ✅ Skip unwanted elements
const [first, , third] = arr; // second is skipped
```

### Rest Pattern

```typescript
// ✅ Collect remaining elements
const [first, ...rest] = ['red', 'green', 'blue'];
// rest = ['green', 'blue']
```

### Swap Variables

```typescript
// ✅ Elegant variable swapping
let a = 1,
  b = 2;
[a, b] = [b, a]; // a = 2, b = 1
```

## Function Parameters

### Object Parameter Destructuring

```typescript
// ❌ BAD: Verbose parameter access
function createUser(userData) {
  const name = userData.name;
  const email = userData.email;
  const age = userData.age;
}

// ✅ GOOD: Destructure in parameter list
function createUser({ name, email, age }) {
  // Use name, email, age directly
}

// ✅ BETTER: With defaults and types
function createUser({
  name,
  email,
  age = 18,
  role = 'user',
}: CreateUserInput) {
  // ...
}
```

### Array Parameter Destructuring

```typescript
// ✅ Extract first two elements
function processCoordinates([x, y, ...extra]) {
  console.log(`Point: (${x}, ${y})`);
  if (extra.length > 0) console.log('Extra:', extra);
}

processCoordinates([10, 20, 30, 40]);
```

## Real-World Patterns

### React Props

```typescript
// ✅ Destructure props in function signature
function UserCard({ name, email, avatar, role = 'user' }) {
  return <div className='user'>{name}</div>;
}
```

### API Response Handling

```typescript
// ✅ Extract relevant fields from API response
async function fetchUser(id: string) {
  const response = await fetch(`/api/users/${id}`);
  const { data, error, statusCode } = await response.json();

  if (error) throw new Error(error);
  return data;
}
```

### Prisma Query Results

```typescript
// ✅ Extract only needed fields
const { id, name, email } = await db.user.findUnique({
  where: { id },
  select: { id: true, name: true, email: true },
});
```

### Event Handler Unpacking

```typescript
// ✅ Destructure event properties
app.post('/users', async (request, reply) => {
  const { name, email, password } = request.body;
  // Use directly
});

// ❌ BAD: Verbose access
request.body.name;
request.body.email;
```

## Common Mistakes

```typescript
// ❌ DON'T: Destructure undefined/null without checks
function processUser(user) {
  const { name, email } = user; // Crashes if user is null!
}

// ✅ DO: Check first or provide defaults
function processUser(user = {}) {
  const { name, email } = user;
}

// ✅ DO: Use optional chaining
function processUser(user) {
  const { name, email } = user || {};
}
```

```typescript
// ❌ DON'T: Destructure in loop header (confusing)
for (const { id, name } in users) {
  // ...
}

// ✅ DO: Destructure in loop body or use forEach
for (const user of users) {
  const { id, name } = user;
}

users.forEach(({ id, name }) => {
  // Clear this is destructuring
});
```

## TypeScript with Destructuring

```typescript
// ✅ Maintain type safety while destructuring
interface User {
  id: string;
  name: string;
  email: string;
  role?: 'admin' | 'user';
}

function processUser({ name, email, role = 'user' }: User) {
  // Types are preserved
}

// ✅ Destructure with type annotations
const { name, email }: User = userData;
```

## Performance Note

Destructuring is not slower than property access—it's just syntax sugar. Modern JS engines optimize both identically.

## Best Practices

1. **Destructure at source**: Get values where you need them
2. **Use meaningful names**: Rename if property names are unclear
3. **Provide defaults**: Avoid undefined surprises
4. **Keep depth reasonable**: Don't nest more than 2-3 levels
5. **Use in parameters**: Makes functions self-documenting
6. **Rest operator sparingly**: Only when you actually need remaining props
