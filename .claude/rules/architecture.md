# Architecture Rule

## Enforcement

Always ask about domain and project scope before recommending architecture. Avoid one-size-fits-all patterns. Match architecture to actual needs.

## Architecture Options

### Feature-Driven (Vertical Slice)

**When**: CRUD applications, simple domains, single team

```
src/
├── features/
│   ├── orders/
│   │   ├── api.ts (routes)
│   │   ├── service.ts (business logic)
│   │   ├── db.ts (database access)
│   │   └── types.ts (types)
│   └── products/
│       └── ...
├── shared/
│   ├── db.ts (connection)
│   ├── middleware.ts
│   └── types.ts
└── main.ts
```

### Hexagonal (Ports & Adapters)

**When**: Complex business logic, multiple interfaces (API, CLI, events)

```
src/
├── domain/
│   ├── entities/
│   └── value-objects/
├── application/
│   ├── services/
│   └── dto/
├── adapters/
│   ├── http/
│   ├── database/
│   └── events/
└── ports/
    ├── IRepository
    └── IEmailService
```

### Modular Monolith

**When**: Multiple teams, shared infrastructure, large codebase

```
src/
├── modules/
│   ├── orders/
│   │   ├── application/
│   │   ├── domain/
│   │   ├── adapters/
│   │   └── index.ts (public API)
│   └── products/
│       └── ...
├── shared/
└── main.ts
```

### Serverless-First

**When**: Event-driven, variable load, minimal overhead, AWS/Vercel

```
functions/
├── api/
│   ├── orders/
│   │   ├── create.ts
│   │   └── get.ts
│   └── products/
├── events/
│   ├── order-created.ts
│   └── payment-processed.ts
└── scheduled/
    └── cleanup.ts
```

## Dependency Direction

Always inward toward domain/business logic:

**BAD** - Business logic depends on HTTP/database frameworks
```typescript
// BAD
export const createOrder = async (req: FastifyRequest) => {
  const order = new Order(req.body.customerId);
  await db.query(`INSERT INTO orders ...`);
  return req.reply.code(201).send(order);
};
```

**GOOD** - Domain logic independent, adapters depend on it
```typescript
// GOOD
// Domain
export const createOrder = async (input: CreateOrderInput): Promise<Result<Order>> => {
  // Pure business logic
  const order = Order.create(input.customerId, input.items);
  return ok(order);
};

// Adapter (HTTP)
export const createOrderHandler = async (request: FastifyRequest) => {
  const result = await createOrder(request.body);
  return result.match(
    (order) => ({ statusCode: 201, body: order }),
    (error) => ({ statusCode: 400, body: error }),
  );
};
```

## Folder Organization

Use feature/module folders, not layers:

**BAD** - Layer-based (horizontal)
```
src/
├── services/
│   ├── order.service.ts
│   ├── product.service.ts
│   └── user.service.ts
├── repositories/
├── dto/
└── types/
```

**GOOD** - Feature-based (vertical)
```
src/
├── features/
│   ├── orders/
│   │   ├── order.service.ts
│   │   ├── order.repository.ts
│   │   ├── order.types.ts
│   │   └── order.api.ts
│   └── products/
└── shared/
```

## No Repository Abstractions Over ORM

Use Prisma/Sequelize directly, don't wrap with generic repositories:

**BAD** - Unnecessary abstraction
```typescript
interface IOrderRepository {
  create(order: Order): Promise<Order>;
  findById(id: string): Promise<Order | null>;
}

class OrderRepository implements IOrderRepository {
  async create(order: Order) {
    return await prisma.order.create({ data: order });
  }
}
```

**GOOD** - Direct ORM usage
```typescript
export const createOrder = async (data: CreateOrderInput) => {
  return await prisma.order.create({
    data,
    include: { items: true },
  });
};

export const getOrderById = async (id: string) => {
  return await prisma.order.findUnique({
    where: { id },
    include: { items: true },
  });
};
```

## Exception

Only abstract database access when:
- Supporting multiple database backends
- Testing without real database (rare — use Testcontainers instead)

