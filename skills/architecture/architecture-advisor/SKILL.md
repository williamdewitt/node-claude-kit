# Architecture Advisor Skill

## When to Use

You're starting a new project or major refactoring and need to choose an architecture pattern. The domain complexity, team size, and deployment model should inform the decision.

## Ask Before Recommending

Never assume architecture. Always ask:
1. How complex is the business logic?
2. Is this CRUD-heavy or algorithm-heavy?
3. How many developers?
4. Deployment constraints (cloud, on-premise, serverless)?

## Architecture Options

### Feature-Driven (Vertical Slice)
**Best for**: CRUD apps, simple domains, 1-3 devs

```
src/
├── features/
│   ├── orders/
│   │   ├── order.service.ts
│   │   ├── order.repository.ts
│   │   ├── order.api.ts
│   │   └── order.types.ts
│   └── products/
├── shared/
│   ├── db.ts
│   └── middleware.ts
└── main.ts
```

### Hexagonal (Ports & Adapters)
**Best for**: Complex business logic, rich domains, 2-5 devs

```
src/
├── domain/
│   ├── order.ts (business logic)
│   └── product.ts
├── application/
│   ├── create-order.ts (use case)
│   └── get-orders.ts
├── adapters/
│   ├── http/
│   ├── database/
│   └── events/
└── ports/
    ├── IOrderRepository
    └── IEmailService
```

### Modular Monolith
**Best for**: Multiple teams, 5+ devs, complex codebase

```
src/
├── modules/
│   ├── orders/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── adapters/
│   │   └── index.ts (public API)
│   └── products/
└── shared/
    ├── db.ts
    └── events.ts
```

### Serverless-First
**Best for**: Event-driven, variable load, AWS/Vercel

```
functions/
├── api/
│   ├── orders/
│   │   ├── [POST].ts
│   │   └── [id].ts
│   └── products/
├── events/
│   ├── order-created.ts
│   └── payment-processed.ts
└── scheduled/
    └── cleanup.ts
```

## Decision Matrix

| Aspect | Feature-Driven | Hexagonal | Modular Monolith | Serverless |
|--------|---|---|---|---|
| **CRUD focus** | ✓ High | ✗ Low | ✗ Medium | ✗ Event-based |
| **Complex logic** | ✗ | ✓ High | ✓ Medium | ✗ |
| **Team size** | 1-3 | 2-5 | 5-20 | Any |
| **Deployment** | Single | Single | Single | Per-function |
| **Setup cost** | Low | Medium | High | High (vendor) |

## Red Flags

- **Over-engineering CRUD**: Don't use hexagonal for a simple API
- **Premature microservices**: Start monolithic, split later
- **Repository abstractions**: Use ORM directly
- **Serverless for stateful apps**: Bad for connections, caching

