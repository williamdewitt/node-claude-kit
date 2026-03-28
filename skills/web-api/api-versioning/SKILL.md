# API Versioning Skill

## When to Use

Any public-facing API that might change. Version from day one to avoid breaking clients.

## URL-Based Versioning (Recommended)

```typescript
// Routes
app.post('/api/v1/orders', createOrderV1Handler);
app.post('/api/v2/orders', createOrderV2Handler);

// Each version has its own handler
const createOrderV1Handler = async (request: FastifyRequest) => {
  // V1: Returns order and customer details
  return { order, customer };
};

const createOrderV2Handler = async (request: FastifyRequest) => {
  // V2: Returns only order with links
  return { order, links: { customer: `/api/v2/customers/${order.customerId}` } };
};
```

## Header-Based Versioning

```typescript
const getApiVersion = (request: FastifyRequest): number => {
  const version = request.headers['api-version'];
  return parseInt(version as string) || 1;
};

app.post('/orders', async (request, reply) => {
  const version = getApiVersion(request);
  
  if (version === 2) {
    return createOrderV2(request.body);
  }
  return createOrderV1(request.body);
});
```

## Deprecation Strategy

```typescript
app.addHook('onResponse', (request, reply) => {
  const version = getApiVersion(request);
  
  if (version === 1) {
    reply.header('Deprecation', 'true');
    reply.header('Sunset', new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString());
    reply.header('Link', '</api/v2/orders>; rel="successor-version"');
  }
});
```

## Migration Path

```typescript
// Version 1
{
  "order": { "id": "1", "total": 100 },
  "customer": { "email": "user@example.com" }
}

// Version 2 (breaking change - separated concerns)
{
  "order": { "id": "1", "total": 100, "customerId": "1" },
  "_links": { "customer": "/api/v2/customers/1" }
}

// Migration period: Support both
// After deprecation period: Remove v1
```

