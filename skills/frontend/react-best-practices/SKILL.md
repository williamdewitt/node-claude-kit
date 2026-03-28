# React Best Practices for Next.js

Modern React 19 patterns: Server Components, hooks, performance optimization, and state management in Next.js projects.

## Server vs Client Components

```typescript
// ✅ Use Server Components for:
// - Fetching data
// - Accessing secrets
// - Direct database queries
export default async function UserList() {
  const users = await db.user.findMany();
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}

// ✅ Use Client Components for:
// - Interactivity (clicks, forms, state)
// - Hooks (useState, useEffect)
// - Browser APIs
'use client';
import { useState } from 'react';

export function UserFilter() {
  const [filter, setFilter] = useState('');
  return <input onChange={e => setFilter(e.target.value)} />;
}
```

## Hooks Best Practices

### useEffect: Fetch Server-Side Instead

```typescript
// ❌ BAD: Fetch in client component
'use client';
export function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState(null);

  useEffect(() => {
    fetch(`/api/users/${userId}`).then(r => r.json()).then(setUser);
  }, [userId]);

  return <div>{user?.name}</div>;
}

// ✅ GOOD: Fetch server-side
export default async function UserProfile({ userId }: { userId: string }) {
  const user = await db.user.findUnique({ where: { id: userId } });
  return <div>{user.name}</div>;
}
```

### useState: Keep State Local

```typescript
// ✅ GOOD: Local state for UI-only logic
'use client';
export function SearchFilter({ items }: { items: Item[] }) {
  const [query, setQuery] = useState('');

  const filtered = items.filter(i => i.name.includes(query));

  return (
    <>
      <input onChange={e => setQuery(e.target.value)} />
      <ul>{filtered.map(i => <li key={i.id}>{i.name}</li>)}</ul>
    </>
  );
}
```

### useCallback: Prevent Unnecessary Renders

```typescript
// ✅ GOOD: Memoize callback passed to children
'use client';
import { useCallback } from 'react';

export function UserTable({ users }: { users: User[] }) {
  const handleDelete = useCallback(async (userId: string) => {
    await fetch(`/api/users/${userId}`, { method: 'DELETE' });
  }, []);

  return <table>{users.map(u => <UserRow key={u.id} user={u} onDelete={handleDelete} />)}</table>;
}
```

## Rendering Patterns

### Suspense for Loading States

```typescript
import { Suspense } from 'react';

function UserFallback() {
  return <div className='skeleton'>Loading...</div>;
}

async function UserList() {
  const users = await db.user.findMany();
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}

export default function Page() {
  return (
    <Suspense fallback={<UserFallback />}>
      <UserList />
    </Suspense>
  );
}
```

### Streaming with Progressive Enhancement

```typescript
import { Suspense } from 'react';

async function AnalyticsDashboard() {
  return (
    <div>
      <h1>Dashboard</h1>

      {/* Critical content loads first */}
      <UserInfo />

      {/* Heavy analytics load later */}
      <Suspense fallback={<div>Loading analytics...</div>}>
        <Analytics />
      </Suspense>
    </div>
  );
}
```

## Form Handling with Server Actions

```typescript
// app/lib/actions.ts
'use server';
import { db } from '@/lib/db';
import { revalidatePath } from 'next/cache';
import { CreateUserSchema } from '@/lib/validation';

export async function createUser(formData: FormData) {
  const name = formData.get('name') as string;
  const email = formData.get('email') as string;

  const parsed = CreateUserSchema.safeParse({ name, email });
  if (!parsed.success) {
    return { error: parsed.error.flatten().fieldErrors };
  }

  const user = await db.user.create({ data: parsed.data });
  revalidatePath('/users');

  return { success: true, user };
}

// app/components/user-form.tsx
'use client';
import { useFormStatus } from 'react-dom';
import { createUser } from '@/lib/actions';

function SubmitButton() {
  const { pending } = useFormStatus();
  return <button disabled={pending}>{pending ? 'Creating...' : 'Create'}</button>;
}

export function CreateUserForm() {
  return (
    <form action={createUser}>
      <input name='name' required />
      <input name='email' type='email' required />
      <SubmitButton />
    </form>
  );
}
```

## Keys and List Rendering

```typescript
// ✅ GOOD: Unique, stable keys
export function UserList({ users }: { users: User[] }) {
  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}

// ❌ BAD: Array index as key (causes bugs on reorder)
{users.map((user, index) => (
  <li key={index}>{user.name}</li>
))}
```

## Prop Drilling Prevention

```typescript
// ✅ GOOD: Use Composition instead of deeply passing props
function Layout({ children }: { children: React.ReactNode }) {
  return (
    <div className='layout'>
      <Header />
      <main>{children}</main>
      <Footer />
    </div>
  );
}

// ❌ BAD: Prop drilling through many components
function App() {
  const user = useUser();
  return <Layout user={user} />;
}
function Layout({ user }: { user: User }) {
  return <Header user={user} />;
}
function Header({ user }: { user: User }) {
  return <UserMenu user={user} />;
}
```

## Memoization: When to Use

```typescript
'use client';
import { memo } from 'react';

// ✅ USE: Expensive rendering logic
const UserCard = memo(function UserCard({ user }: { user: User }) {
  // Complex calculations or renders
  const expensiveValue = complexCalc(user);
  return <div>{expensiveValue}</div>;
});

// ❌ DON'T: For simple components (overhead > benefit)
const SimpleText = memo(({ text }: { text: string }) => <p>{text}</p>);
```

## Image Optimization

```typescript
import Image from 'next/image';

// ✅ GOOD: Optimized images
<Image
  src='/users/alice.jpg'
  alt='Alice'
  width={100}
  height={100}
  priority // Load immediately
/>

// ❌ BAD: HTML img (no optimization)
<img src='/users/alice.jpg' alt='Alice' />
```

## Testing Components

```typescript
// app/components/__tests__/user-card.test.tsx
import { render, screen } from '@testing-library/react';
import { UserCard } from '../user-card';

it('renders user name', () => {
  render(<UserCard user={{ id: '1', name: 'Alice', email: 'alice@example.com' }} />);
  expect(screen.getByText('Alice')).toBeInTheDocument();
});

it('shows email on click', async () => {
  const { user } = render(<UserCard {...} />);
  await user.click(screen.getByRole('button'));
  expect(screen.getByText('alice@example.com')).toBeVisible();
});
```

## Performance Checklist

- [ ] Use Server Components by default
- [ ] Lazy load client components
- [ ] Memoize expensive computations
- [ ] Optimize images
- [ ] Suspense for loading states
- [ ] Remove unnecessary effects
- [ ] Use Server Actions for mutations
- [ ] Monitor Core Web Vitals
