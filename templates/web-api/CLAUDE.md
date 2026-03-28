# Web API Project - Claude Code Configuration

## Project Overview

REST API backend built with Fastify, Prisma, and Zod validation. Single deployment unit, feature-driven architecture.

### Tech Stack

- **Runtime**: Node.js 20+
- **Framework**: Fastify 4.x
- **Database**: PostgreSQL with Prisma ORM
- **Validation**: Zod
- **Testing**: Vitest with Testcontainers
- **Logging**: Pino structured logging
- **Authentication**: JWT with refresh tokens

### Architecture

Feature-driven (vertical slice) architecture. Each feature owns its domain, service, and API layers.

```
src/
├── features/
│   ├── orders/
│   │   ├── order.service.ts
│   │   ├── order.api.ts
│   │   └── order.types.ts
│   └── products/
├── shared/
│   ├── db.ts
│   ├── middleware.ts
│   └── types.ts
├── main.ts
└── server.ts
```

## Development Practices

### Database

- Direct Prisma usage, no repository abstractions
- Query optimization and index coverage
- Transactions for multi-step operations
- Migrations tracked in version control

### APIs

- OpenAPI metadata on every endpoint
- Proper HTTP status codes and semantics
- Pagination for list endpoints
- Versioning ready (use /api/v1, /api/v2)

### Error Handling

- Custom Error subclasses for domain errors
- Result pattern for expected failures
- Structured error responses
- Never swallow exceptions

### Testing

- Integration-first with real PostgreSQL
- Vitest + Testcontainers
- Fixtures for test data
- Real scenarios, not mocks

### Logging

- Structured logging with Pino
- Correlation IDs for tracing
- Proper log levels (debug, info, warn, error)
- Performance metrics

## Key Commands

```bash
npm run dev              # Start development server
npm run build            # Compile TypeScript
npm run type-check      # Type checking
npm run lint            # ESLint
npm test                # Run Vitest
npm run test:coverage   # Coverage report
npm run migrate         # Run pending migrations
npm run migrate:create  # Create new migration
```

## Environment Variables

```
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost:5432/db
JWT_SECRET=your-secret-key
LOG_LEVEL=info
```

## API Documentation

OpenAPI documentation available at `/api/docs` (via Fastify Swagger plugin).

## Deployment

Built for containerization:
- Multi-stage Dockerfile included
- Health check endpoint at `/health`
- Graceful shutdown handling
- Zero-downtime migrations

## Team Conventions

- Async/await throughout, no callbacks
- Const-first declarations
- Arrow functions for all callbacks
- Destructuring at assignment
- TypeScript strict mode mandatory
- No `any` types
- Result pattern for business logic errors

