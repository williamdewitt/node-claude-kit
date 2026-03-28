# Modular Monolith - Claude Code Configuration

## Project Overview

Large-scale application with 5+ development teams. Monolithic deployment with strict module boundaries and event-driven communication between modules.

### Architecture

Modules are independently deployable units with clear public APIs:

```
src/
├── modules/
│   ├── orders/
│   │   ├── application/
│   │   │   └── create-order.ts
│   │   ├── domain/
│   │   │   └── order.ts
│   │   ├── adapters/
│   │   │   ├── http/
│   │   │   └── database/
│   │   └── index.ts (public API)
│   ├── products/
│   └── payments/
├── shared/
│   ├── events.ts (event bus)
│   ├── db.ts (connection pool)
│   └── middleware.ts
└── main.ts
```

## Tech Stack

- Fastify (shared HTTP layer)
- Prisma (shared database layer)
- Event-driven architecture (pub/sub pattern)
- pnpm workspaces (optional)

## Development Practices

- Follow feature boundaries strictly
- No cross-module imports except through public API
- Modules communicate via event bus
- Each module owns its tests

