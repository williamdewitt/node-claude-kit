# Authentication Skill

## When to Use

Any endpoint that requires identifying the user. Use JWT with secure refresh token pattern.

## JWT Setup

```typescript
import jwt from '@fastify/jwt';
import fastifySecure from '@fastify/secure-session';

export const setupAuth = async (app: FastifyInstance) => {
  await app.register(jwt, {
    secret: process.env.JWT_SECRET!,
    sign: { expiresIn: '15m' },
  });
  
  // Verify token on protected routes
  app.register(async (fastify) => {
    fastify.addHook('preHandler', async (request) => {
      await request.jwtVerify();
    });
  }, { prefix: '/api/protected' });
};
```

## Login Flow

```typescript
const loginHandler = async (request: FastifyRequest) => {
  const { email, password } = request.body;
  
  // Verify credentials
  const user = await db.user.findUnique({ where: { email } });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    throw new UnauthorizedError('Invalid credentials');
  }
  
  // Issue tokens
  const accessToken = request.jwt.sign({ userId: user.id });
  const refreshToken = crypto.randomBytes(32).toString('hex');
  
  // Store refresh token
  await db.session.create({
    data: { userId: user.id, token: refreshToken, expiresAt: futureDate },
  });
  
  return {
    accessToken,
    refreshToken,
    expiresIn: 900, // 15 minutes
  };
};
```

## Refresh Token Flow

```typescript
const refreshHandler = async (request: FastifyRequest) => {
  const { refreshToken } = request.body;
  
  // Verify refresh token
  const session = await db.session.findUnique({ where: { token: refreshToken } });
  if (!session || session.expiresAt < new Date()) {
    throw new UnauthorizedError('Refresh token invalid or expired');
  }
  
  // Issue new access token
  const accessToken = request.jwt.sign({ userId: session.userId });
  
  return { accessToken, expiresIn: 900 };
};
```

## Protected Routes

```typescript
app.get<{ Params: { id: string } }>(
  '/api/protected/users/:id',
  {
    onRequest: async (request) => {
      await request.jwtVerify();
      
      // Optional: Check authorization
      if (request.user.userId !== request.params.id && !request.user.isAdmin) {
        throw new ForbiddenError('Access denied');
      }
    },
  },
  async (request) => {
    const user = await db.user.findUnique({ where: { id: request.user.userId } });
    return user;
  },
);
```

