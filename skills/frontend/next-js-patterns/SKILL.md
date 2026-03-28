# Next.js Patterns for Full-Stack Development

Building fast, type-safe full-stack applications with Next.js 14+, Server Components, and API Routes.

## When to Use Next.js

- **Full-stack single repo**: Frontend and backend together
- **Server-side rendering**: SEO-important content
- **Real-time features**: WebSockets + instant updates
- **File-based routing**: Simple, automatic API routes

## Project Structure

```
app/
├── page.tsx                    // Homepage
├── layout.tsx                  // Root layout
├── api/
│   ├── auth/
│   │   ├── login/route.ts     // POST /api/auth/login
│   │   └── logout/route.ts    // POST /api/auth/logout
│   ├── users/
│   │   ├── route.ts           // GET /api/users, POST /api/users
│   │   └── [id]/route.ts      // GET /api/users/[id]
│   └── health/route.ts        // GET /api/health
├── dashboard/
│   ├── page.tsx               // Dashboard page
│   ├── layout.tsx             // Dashboard layout
│   ├── settings/
│   │   └── page.tsx           // Settings page
│   └── posts/
│       ├── page.tsx           // Posts listing
│       └── [id]/
│           └── page.tsx       // Post detail
├── components/
│   ├── header.tsx
│   ├── navigation.tsx
│   └── user-card.tsx
└── lib/
    ├── db.ts                  // Database client
    ├── auth.ts                // Auth utilities
    └── validation.ts          // Schema validation
```

## Server Components (Default)

```typescript
// app/dashboard/page.tsx
import { db } from '@/lib/db';

export default async function Dashboard() {
  // Runs on server, no JavaScript sent to client
  const posts = await db.post.findMany({
    where: { published: true },
    orderBy: { createdAt: 'desc' },
    take: 20,
  });

  return (
    <div>
      <h1>Dashboard</h1>
      {posts.map((post) => (
        <PostCard key={post.id} post={post} />
      ))}
    </div>
  );
}
```

## Client Components (When Needed)

```typescript
// app/components/counter.tsx
'use client'; // Runs on client

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
}

// Use in Server Component
export default async function Page() {
  return (
    <div>
      <Counter /> {/* Rendered on client */}
    </div>
  );
}
```

## API Routes

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { CreateUserSchema } from '@/lib/validation';

// GET /api/users
export async function GET(request: NextRequest) {
  const limit = request.nextUrl.searchParams.get('limit') || '10';

  const users = await db.user.findMany({
    take: Math.min(parseInt(limit), 100),
    select: { id: true, name: true, email: true },
  });

  return NextResponse.json(users);
}

// POST /api/users
export async function POST(request: NextRequest) {
  const body = await request.json();

  const parsed = CreateUserSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error }, { status: 400 });
  }

  const user = await db.user.create({
    data: parsed.data,
  });

  return NextResponse.json(user, { status: 201 });
}
```

## Dynamic Routes

```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } },
) {
  const user = await db.user.findUnique({
    where: { id: params.id },
  });

  if (!user) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  return NextResponse.json(user);
}

// PATCH /api/users/[id]
export async function PATCH(
  request: NextRequest,
  { params }: { params: { id: string } },
) {
  const body = await request.json();

  const user = await db.user.update({
    where: { id: params.id },
    data: body,
  });

  return NextResponse.json(user);
}
```

## Authentication in API Routes

```typescript
// app/lib/auth.ts
import { cookies } from 'next/headers';
import { jwtVerify } from 'jose';

const secret = new TextEncoder().encode(process.env.JWT_SECRET!);

export async function getUser(request: NextRequest) {
  const cookieStore = await cookies();
  const token = cookieStore.get('token')?.value;

  if (!token) {
    return null;
  }

  try {
    const verified = await jwtVerify(token, secret);
    return verified.payload as { userId: string };
  } catch {
    return null;
  }
}

// In route handler:
export async function POST(request: NextRequest) {
  const user = await getUser(request);

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // User is authenticated
  return NextResponse.json({ message: 'Success' });
}
```

## Server Actions for Mutations

```typescript
// app/lib/actions.ts
'use server'; // Runs only on server

import { db } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function createPost(title: string, content: string) {
  const post = await db.post.create({
    data: { title, content },
  });

  revalidatePath('/posts'); // Clear cache for /posts page

  return post;
}

// app/components/create-post-form.tsx
'use client';

import { createPost } from '@/lib/actions';

export function CreatePostForm() {
  async function handleSubmit(formData: FormData) {
    const title = formData.get('title') as string;
    const content = formData.get('content') as string;

    await createPost(title, content);
  }

  return (
    <form action={handleSubmit}>
      <input name='title' required />
      <textarea name='content' required />
      <button type='submit'>Create Post</button>
    </form>
  );
}
```

## Middleware for Authorization

```typescript
// middleware.ts
import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  // Protect /dashboard routes
  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    const token = request.cookies.get('token');

    if (!token) {
      return NextResponse.redirect(new URL('/login', request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/admin/:path*'],
};
```

## Environment Variables

```bash
# .env.local
DATABASE_URL=postgresql://...
JWT_SECRET=your-secret
NEXT_PUBLIC_API_URL=http://localhost:3000
```

```typescript
// Only accessible on server (starts with underscore for private)
const jwtSecret = process.env.JWT_SECRET!;

// Accessible on client (NEXT_PUBLIC_ prefix)
const apiUrl = process.env.NEXT_PUBLIC_API_URL;
```

## Data Fetching

```typescript
// ✅ Server Component with automatic caching
export default async function Page() {
  const data = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 }, // Cache for 1 hour
  });

  return <div>{/* ... */}</div>;
}
```

## Testing Routes

```typescript
// app/api/users/__tests__/route.test.ts
import { GET, POST } from '../route';
import { NextRequest } from 'next/server';

it('gets users', async () => {
  const request = new NextRequest('http://localhost/api/users');
  const response = await GET(request);
  const data = await response.json();

  expect(Array.isArray(data)).toBe(true);
});
```

## Performance Tips

1. **Use Server Components by default**: Less JavaScript to client
2. **Optimize images**: Use `<Image>` component
3. **Cache strategically**: `revalidatePath()` when data changes
4. **Lazy load client components**: Split code automatically
5. **Streaming**: Large pages render gradually with `<Suspense>`

## BAD vs GOOD

```typescript
// ❌ BAD: Client-side rendering of static content
'use client';
export default function Page() {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch('/api/posts').then(r => r.json()).then(setData);
  }, []);

  return <div>{data}</div>;
}

// ✅ GOOD: Server-side rendering
export default async function Page() {
  const posts = await db.post.findMany();
  return <div>{/* render posts */}</div>;
}
```
