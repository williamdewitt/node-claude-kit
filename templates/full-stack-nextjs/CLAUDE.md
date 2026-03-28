# Full-Stack Next.js Project - Claude Code Configuration

## Project Overview

Full-stack web application with Next.js App Router, React Server Components, TypeScript, and Prisma ORM.

### Tech Stack

- **Frontend**: Next.js 14+ with React 19
- **Backend**: Next.js API routes + Server Actions
- **Database**: PostgreSQL with Prisma ORM
- **Styling**: Tailwind CSS
- **Validation**: Zod
- **Testing**: Vitest (backend), Vitest + Testing Library (frontend)

### Architecture

Next.js App Router with feature-driven folder structure:

```
app/
├── (auth)/
│   ├── login/
│   │   └── page.tsx
│   └── register/
├── dashboard/
│   ├── layout.tsx
│   ├── page.tsx
│   └── orders/
│       └── page.tsx
├── api/
│   ├── auth/
│   │   └── [...nextauth]/
│   └── orders/
│       └── route.ts
└── layout.tsx

lib/
├── prisma.ts (Prisma client)
├── auth.ts (NextAuth setup)
└── validation.ts (Zod schemas)
```

## Development Practices

### Server Components

- Use Server Components by default
- Fetch data directly in components
- Database queries server-side only
- API routes for mutations

### API Routes

- Create only for mutations and webhooks
- Queries via Server Component data fetching
- Proper error handling with typed responses
- JWT authentication support

### Database

- Prisma for all database access
- Migrations tracked in version control
- Seed file for initial data

### Validation

- Zod for API request/response validation
- Form validation on client (react-hook-form)
- Server-side validation always

## Key Commands

```bash
npm run dev              # Start dev server
npm run build            # Build for production
npm run type-check      # Type checking
npm run lint            # ESLint
npm test                # Run tests
npm run migrate         # Run migrations
npm run seed            # Seed database
```

## Environment Variables

```
DATABASE_URL=postgresql://...
NEXTAUTH_SECRET=...
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_PROVIDERS=github|google
```

## Deployment

- Optimized for Vercel
- Environment-specific builds
- Database migrations on deploy
- Edge function support

