# Modern JavaScript Skill

## When to Use

Writing any new JavaScript or TypeScript code. These patterns are the standard for Node.js 20+.

## Key Features

### Const-First
Always use `const` by default. Use `let` only if reassignment is necessary:

```javascript
// GOOD
const items = [1, 2, 3];
const user = { name: 'Alice' };

// BAD
let items = [1, 2, 3];
var user = { name: 'Alice' };
```

### Arrow Functions
Use arrow functions for all callbacks and higher-order functions:

```javascript
// GOOD
const double = (x) => x * 2;
const users = data.map((user) => user.name);
const handlers = {
  save: async () => { /* ... */ },
};

// BAD
function double(x) { return x * 2; }
const double = function(x) { return x * 2; };
```

### Template Literals
Use backticks for all string interpolation:

```javascript
// GOOD
const message = `Hello ${name}, you have ${count} items`;
const sql = `SELECT * FROM users WHERE id = ${id}`;

// BAD
const message = 'Hello ' + name + ', you have ' + count + ' items';
const sql = 'SELECT * FROM users WHERE id = ' + id;
```

### Destructuring
Extract values at assignment time:

```javascript
// GOOD
const { user, orders } = await fetchUserData();
const { name, email } = user;
const [first, second, ...rest] = items;

// BAD
const data = await fetchUserData();
const user = data.user;
const orders = data.orders;
```

### Default Parameters
Use defaults instead of || checks:

```javascript
// GOOD
const createUser = (name, status = 'active') => { /* ... */ };
const getUsers = (page = 1, limit = 20) => { /* ... */ };

// BAD
const createUser = (name, status) => {
  const s = status || 'active';
};
```

### Nullish Coalescing
Use ?? for defaults, not ||:

```javascript
// GOOD - Handles false/0/"" correctly
const count = userCount ?? 0;
const name = profile?.name ?? 'Anonymous';

// BAD - Treats false/0 as missing
const count = userCount || 0;
```

### Optional Chaining
Use ?. to safely access nested properties:

```javascript
// GOOD
const city = user?.profile?.address?.city;
const items = order?.items?.map(i => i.name);

// BAD
const city = user && user.profile && user.profile.address && user.profile.address.city;
```

## Avoid

- `var` - Use `const` and `let`
- Function declarations - Use arrow functions
- String concatenation - Use template literals
- Callback hell - Use async/await
- `Array.forEach()` - Use `.map()` or `.for...of`

