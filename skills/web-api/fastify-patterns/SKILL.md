# Fastify Patterns Skill

## When to Use

Building REST APIs with Fastify. Modern, fast, with built-in JSON Schema support and plugin ecosystem.

## Basic Server Setup

```typescript
import fastify from 'fastify';
import helmet from '@fastify/helmet';

export const createApp = async () => {
  const app = fastify({ logger: true });
  
  // Security
  await app.register(helmet);
  
  // Routes
  app.post<{ Body: CreateUserInput }>(
    '/users',
    {
      schema: {
        tags: ['Users'],
        body: createUserSchema,
        response: { 201: userSchema },
      },
    },
    async (request, reply) => {
      const user = await createUser(request.body);
      return reply.code(201).send(user);
    },
  );
  
  return app;
};

const app = await createApp();
await app.listen({ port: 3000, host: '0.0.0.0' });
```

## Route Groups

Use RoutePrefix for organization:

```typescript
const registerUserRoutes = (app: FastifyInstance) => {
  app.register(async (fastify) => {
    fastify.post('/users', createUserHandler);
    fastify.get('/users', listUsersHandler);
    fastify.get('/users/:id', getUserHandler);
    fastify.patch('/users/:id', updateUserHandler);
    fastify.delete('/users/:id', deleteUserHandler);
  }, { prefix: '/api/v1' });
};
```

## Hooks for Cross-Cutting Concerns

```typescript
// Logging
app.addHook('preHandler', async (request, reply) => {
  request.startTime = Date.now();
});

app.addHook('onResponse', async (request, reply) => {
  const duration = Date.now() - request.startTime;
  logger.info({ duration, method: request.method, path: request.url });
});

// Authentication
app.addHook('preHandler', async (request, reply) => {
  const token = request.headers.authorization?.split(' ')[1];
  if (!token) throw new UnauthorizedError();
  request.user = verifyToken(token);
});
```

## Type-Safe Handlers

```typescript
type CreateUserHandler = FastifyRequestHandler<{
  Body: CreateUserInput;
  Reply: User;
}>;

const createUserHandler: CreateUserHandler = async (request, reply) => {
  const result = await createUser(request.body);
  return reply.code(201).send(result);
};
```

## Error Handling

```typescript
app.setErrorHandler((error, request, reply) => {
  if (error instanceof ApplicationError) {
    return reply.code(error.statusCode).send({
      code: error.code,
      message: error.message,
    });
  }
  
  logger.error({ error, request });
  return reply.code(500).send({ error: 'Internal Server Error' });
});
```

