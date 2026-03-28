# State Management Patterns

Managing application state in Next.js: Server state, client state, and when to use each approach.

## Three Types of State

### 1. Server State (Default in Next.js)

```typescript
// ✅ GOOD: Keep data on server, fetch fresh
// app/dashboard/page.tsx (Server Component)
export default async function Dashboard() {
  const posts = await db.post.findMany({
    where: { published: true },
    orderBy: { createdAt: 'desc' },
    take: 20,
  });

  return <PostList posts={posts} />;
}

// Invalidate cache when data changes
revalidatePath('/dashboard');
```

Benefits:
- No hydration issues
- SEO-friendly
- Automatic caching
- Secure (never exposed to client)

### 2. URL State (Querystring)

```typescript
// ✅ GOOD: Bookmarkable, shareable state
// app/search/page.tsx
export default function SearchPage({
  searchParams,
}: {
  searchParams: { q: string; sort: 'newest' | 'popular' };
}) {
  return (
    <>
      <SearchForm initialQuery={searchParams.q} />
      <Results query={searchParams.q} sort={searchParams.sort} />
    </>
  );
}

// app/components/search-form.tsx
'use client';
import { useRouter, useSearchParams } from 'next/navigation';

export function SearchForm() {
  const router = useRouter();
  const searchParams = useSearchParams();

  function handleSearch(query: string) {
    const params = new URLSearchParams(searchParams);
    params.set('q', query);
    router.push(`?${params.toString()}`);
  }

  return <input onChange={e => handleSearch(e.target.value)} />;
}
```

### 3. Client State (useState)

```typescript
// ✅ GOOD: Local UI state only
'use client';
import { useState } from 'react';

export function Accordion() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div>
      <button onClick={() => setIsOpen(!isOpen)}>Toggle</button>
      {isOpen && <content />}
    </div>
  );
}
```

Use for:
- Form input (temporarily)
- UI visibility (expanded/collapsed)
- Animation state
- Temporary filters

## Context for Shared Client State

```typescript
// app/lib/auth-context.tsx
'use client';
import { createContext, useContext, useState } from 'react';

interface AuthContext {
  user: User | null;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContext | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  async function logout() {
    await fetch('/api/auth/logout', { method: 'POST' });
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be inside AuthProvider');
  return context;
}

// app/layout.tsx
import { AuthProvider } from './lib/auth-context';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html>
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}

// Any client component can use it
'use client';
import { useAuth } from '@/lib/auth-context';

export function UserMenu() {
  const { user, logout } = useAuth();

  return (
    <menu>
      <p>{user?.name}</p>
      <button onClick={logout}>Logout</button>
    </menu>
  );
}
```

## Advanced Pattern: Server State + Mutations

```typescript
// app/lib/actions.ts
'use server';

export async function updateUserName(userId: string, newName: string) {
  const user = await db.user.update({
    where: { id: userId },
    data: { name: newName },
  });

  revalidatePath(`/users/${userId}`);
  return user;
}

// app/components/edit-profile.tsx
'use client';
import { useFormStatus, useTransition } from 'react-dom';
import { updateUserName } from '@/lib/actions';

export function EditProfile({ user }: { user: User }) {
  const [pending, startTransition] = useTransition();

  function handleSave(formData: FormData) {
    const newName = formData.get('name') as string;
    startTransition(async () => {
      await updateUserName(user.id, newName);
    });
  }

  return (
    <form action={handleSave}>
      <input defaultValue={user.name} name='name' />
      <button disabled={pending}>{pending ? 'Saving...' : 'Save'}</button>
    </form>
  );
}
```

## BAD: Over-Complex State

```typescript
// ❌ BAD: Using Redux for simple app
import { useSelector, useDispatch } from 'react-redux';

export function Counter() {
  const count = useSelector(state => state.counter.value);
  const dispatch = useDispatch();

  return (
    <>
      <p>{count}</p>
      <button onClick={() => dispatch(increment())}>+</button>
    </>
  );
}

// ✅ GOOD: Simple useState
'use client';
import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <>
      <p>{count}</p>
      <button onClick={() => setCount(count + 1)}>+</button>
    </>
  );
}
```

## Data Fetching with Cache Invalidation

```typescript
// app/lib/cache.ts
import { revalidatePath, revalidateTag } from 'next/cache';

export async function createPost(data: CreatePostInput) {
  const post = await db.post.create({ data });

  // Invalidate specific page
  revalidatePath('/posts');

  // OR use tags for granular control
  // fetch('/api/posts', { next: { tags: ['posts'] } })
  // revalidateTag('posts');

  return post;
}
```

## Testing State Updates

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { EditProfile } from '@/components/edit-profile';

it('saves profile changes', async () => {
  const user = userEvent.setup();

  render(<EditProfile user={{ id: '1', name: 'Alice' }} />);

  const input = screen.getByDisplayValue('Alice');
  await user.clear(input);
  await user.type(input, 'Bob');

  const button = screen.getByRole('button', { name: 'Save' });
  await user.click(button);

  expect(button).toHaveTextContent('Saving...');
  await waitFor(() => {
    expect(button).toHaveTextContent('Save');
  });
});
```

## Decision Tree

```
Does the state need to be shared across pages?
├─ Yes → Use Server State + revalidateTag()
└─ No
   └─ Is it UI-only (expanded, theme, form input)?
      ├─ Yes → Use useState
      └─ No
         └─ Is it shareable within page?
            ├─ Yes → Use Context
            └─ No → Use URL params
```
