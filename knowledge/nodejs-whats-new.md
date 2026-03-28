# Node.js 20+ / TypeScript 5.3+ Features

## Node.js 20+ Features

### Native Fetch API
```javascript
const response = await fetch('https://example.com');
const data = await response.json();
```

### URL Constructor
```javascript
const url = new URL('https://example.com/path?query=value');
console.log(url.searchParams.get('query')); // 'value'
```

### AbortController
```javascript
const controller = new AbortController();
setTimeout(() => controller.abort(), 5000);

const response = await fetch(url, { signal: controller.signal });
```

## TypeScript 5.3+ Features

### const Type Parameters
```typescript
function getArray<const T extends readonly string[]>(arr: T) {
  return arr; // preserves exact type
}
```

### Satisfies Operator
```typescript
type Role = 'admin' | 'user';
const config = {
  userRole: 'admin' as const,
} satisfies { userRole: Role };
```

## Recommended Patterns

- Use native `fetch` instead of axios
- Use `AbortController` for cancellation
- Use `URL` constructor for URL parsing
- Use TypeScript strict mode always
- Use async/await, never Promise chains

