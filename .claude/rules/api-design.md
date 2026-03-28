# API Design Rule

## Enforcement

Include OpenAPI metadata on all endpoints. Use proper HTTP status codes. Implement versioning. Paginate list endpoints. Provide clear error responses.

## OpenAPI Metadata

**BAD** - No documentation
```typescript
app.post('/orders', async (req, reply) => {
  // What are expected inputs?
  // What response structure?
  // What errors can occur?
});
```

**GOOD** - Full OpenAPI metadata
```typescript
app.post<{ Body: CreateOrderInput }>(
  '/api/v1/orders',
  {
    schema: {
      description: 'Create a new order',
      tags: ['Orders'],
      body: {
        type: 'object',
        properties: {
          customerId: { type: 'string', minLength: 1 },
          items: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                productId: { type: 'string' },
                quantity: { type: 'number', minimum: 1 },
              },
              required: ['productId', 'quantity'],
            },
          },
        },
        required: ['customerId', 'items'],
      },
      response: {
        201: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            total: { type: 'number' },
            createdAt: { type: 'string', format: 'date-time' },
          },
        },
        422: { $ref: '#/components/schemas/ValidationError' },
        400: { $ref: '#/components/schemas/BadRequest' },
      },
    },
  },
  createOrderHandler,
);
```

## HTTP Status Codes

```typescript
// Success responses
200 - OK
201 - Created
204 - No Content

// Client errors
400 - Bad Request (invalid input)
401 - Unauthorized (not authenticated)
403 - Forbidden (authenticated but no permission)
404 - Not Found
409 - Conflict (duplicate email, etc)
422 - Unprocessable Entity (validation failed)

// Server errors
500 - Internal Server Error
503 - Service Unavailable
```

## API Versioning

**BAD** - Unversioned endpoints break existing clients
```typescript
app.post('/orders', ...);
app.patch('/orders/:id', ...);
```

**GOOD** - Versioned routes
```typescript
app.post('/api/v1/orders', ...);
app.patch('/api/v1/orders/:id', ...);

// Support multiple versions if needed
app.post('/api/v2/orders', ...); // New endpoint with different contract
```

## Pagination

**BAD** - No pagination, returns all rows
```typescript
app.get('/users', async (req, reply) => {
  const users = await db.user.findMany();
  reply.send(users);
});
```

**GOOD** - Paginated response
```typescript
const paginationSchema = z.object({
  page: z.coerce.number().positive().default(1),
  limit: z.coerce.number().positive().max(100).default(20),
});

app.get('/users', async (req, reply) => {
  const { page, limit } = paginationSchema.parse(req.query);
  const skip = (page - 1) * limit;
  
  const [data, total] = await Promise.all([
    db.user.findMany({ skip, take: limit, orderBy: { createdAt: 'desc' } }),
    db.user.count(),
  ]);
  
  reply.send({
    data,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
      hasMore: page * limit < total,
    },
  });
});
```

## Error Response Format

```typescript
type ErrorResponse = {
  code: string;
  message: string;
  timestamp: string;
  path: string;
  details?: ValidationError[];
};

type ValidationError = {
  field: string;
  message: string;
  value?: unknown;
};

app.post('/users', async (req, reply) => {
  const validation = createUserSchema.safeParse(req.body);
  
  if (!validation.success) {
    const details = validation.error.issues.map((issue) => ({
      field: issue.path.join('.'),
      message: issue.message,
      value: issue.code === 'custom' ? issue.fatal : undefined,
    }));
    
    return reply.code(422).send({
      code: 'VALIDATION_ERROR',
      message: 'Request validation failed',
      timestamp: new Date().toISOString(),
      path: req.url,
      details,
    });
  }
  
  // ...
});
```

## Resource Naming

**BAD** - Unclear verbs
```typescript
GET /getUsers
POST /createUser
PATCH /updateUser/:id
DELETE /removeUser/:id
```

**GOOD** - RESTful resource names
```typescript
GET /api/v1/users (list)
GET /api/v1/users/:id (get one)
POST /api/v1/users (create)
PATCH /api/v1/users/:id (update)
DELETE /api/v1/users/:id (delete)
```

## Filtering and Sorting

```typescript
const listSchema = z.object({
  page: z.coerce.number().positive().default(1),
  limit: z.coerce.number().positive().max(100).default(20),
  sort: z.enum(['createdAt', 'name']).default('createdAt'),
  order: z.enum(['asc', 'desc']).default('desc'),
  status: z.enum(['active', 'inactive']).optional(),
});

app.get('/users', async (req, reply) => {
  const { page, limit, sort, order, status } = listSchema.parse(req.query);
  
  const users = await db.user.findMany({
    where: status ? { status } : undefined,
    orderBy: { [sort]: order },
    skip: (page - 1) * limit,
    take: limit,
  });
  
  reply.send(users);
});
```

