# Environment Configuration for Node.js Applications

Managing configuration across development, staging, and production environments securely.

## Environment Variables Approach

```bash
# .env.local (development, never commit)
DATABASE_URL=postgresql://localhost/dev_db
JWT_SECRET=dev-secret-key-not-secure
STRIPE_SECRET_KEY=sk_test_...
REDIS_URL=redis://localhost:6379
NODE_ENV=development
LOG_LEVEL=debug

# .env.production (deployed via CI/CD, never in repo)
DATABASE_URL=postgresql://prod.rds.amazonaws.com/prod_db
JWT_SECRET=<generated-by-vault>
STRIPE_SECRET_KEY=sk_live_...
REDIS_URL=redis://prod-redis.internal
NODE_ENV=production
LOG_LEVEL=warn
```

## Validating Environment Variables

```typescript
// lib/env.ts
import { z } from 'zod';

const EnvSchema = z.object({
  // Database
  DATABASE_URL: z.string().url(),

  // Auth
  JWT_SECRET: z.string().min(32),

  // APIs
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),

  // Cache
  REDIS_URL: z.string().url(),

  // Server
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z
    .enum(['development', 'staging', 'production'])
    .default('development'),

  // Logging
  LOG_LEVEL: z
    .enum(['debug', 'info', 'warn', 'error'])
    .default('info'),
});

// Parse and validate
const env = EnvSchema.parse(process.env);

// Export typed environment
export const config = {
  database: {
    url: env.DATABASE_URL,
  },
  auth: {
    jwtSecret: env.JWT_SECRET,
  },
  stripe: {
    secretKey: env.STRIPE_SECRET_KEY,
  },
  cache: {
    redisUrl: env.REDIS_URL,
  },
  server: {
    port: env.PORT,
    isDev: env.NODE_ENV === 'development',
    isProd: env.NODE_ENV === 'production',
  },
  logging: {
    level: env.LOG_LEVEL,
  },
};
```

## Environment-Specific Configuration

```typescript
// lib/config.ts
import { config } from './env';

export const getConfig = () => {
  if (config.server.isProd) {
    return {
      ...config,
      cache: {
        ...config.cache,
        ttl: 3600, // 1 hour in prod
      },
      rateLimit: {
        windowMs: 15 * 60 * 1000, // 15 minutes
        maxRequests: 100,
      },
    };
  }

  if (config.server.isDev) {
    return {
      ...config,
      cache: {
        ...config.cache,
        ttl: 0, // No cache in dev
      },
      rateLimit: {
        windowMs: 15 * 60 * 1000,
        maxRequests: 10000, // Unlimited in dev
      },
    };
  }

  // Staging
  return {
    ...config,
    cache: {
      ...config.cache,
      ttl: 600, // 10 minutes
    },
  };
};
```

## Secrets Management

```bash
# Never commit secrets to git
# Use environment variables provided by:
# - Docker secrets
# - Environment variables from deployment platform
# - Secret manager (AWS Secrets Manager, HashiCorp Vault, etc.)
```

```typescript
// lib/secrets.ts
import { SecretsManager } from '@aws-sdk/client-secrets-manager';

const secretsManager = new SecretsManager();

export async function getSecret(secretName: string): Promise<string> {
  // Cache in memory to avoid repeated API calls
  const cached = secretCache.get(secretName);
  if (cached) return cached;

  const response = await secretsManager.getSecretValue({
    SecretId: secretName,
  });

  const secret = response.SecretString!;
  secretCache.set(secretName, secret);

  return secret;
}

const secretCache = new Map<string, string>();

// Usage
const jwtSecret = await getSecret('jwt-secret');
```

## .gitignore for Secrets

```
# Never commit local environment files
.env.local
.env.*.local
.env
.env.development
.env.staging
.env.production

# IDE secrets
.idea/**
.vscode/settings.json

# Third-party secrets
config/secrets.json
config/private/

# Logs with sensitive data
*.log
logs/

# OS files that might contain secrets
.DS_Store
Thumbs.db
```

## Docker Environment Configuration

```dockerfile
# Dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY src ./src

# Don't copy .env file
# Secrets provided at runtime

EXPOSE 3000
CMD ["node", "src/main.ts"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    build: .
    ports:
      - '3000:3000'
    environment:
      # For development only!
      DATABASE_URL: postgresql://postgres:password@db:5432/app
      JWT_SECRET: dev-secret-key
      NODE_ENV: development
    depends_on:
      - db

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_DB: app
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Kubernetes Secrets

```yaml
# k8s/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  JWT_SECRET: <actual-secret>
  DATABASE_URL: postgresql://...
  STRIPE_SECRET_KEY: sk_...

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  NODE_ENV: production
  LOG_LEVEL: info

---
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
    - name: app
      image: app:latest
      envFrom:
        - secretRef:
            name: app-secrets
        - configMapRef:
            name: app-config
```

## Local Development Setup

```bash
# 1. Copy template
cp .env.example .env.local

# 2. Fill in local values
# DATABASE_URL=postgresql://localhost/dev_db
# JWT_SECRET=dev-key-not-secure
# NODE_ENV=development

# 3. Load into shell (using direnv)
echo "export $(cat .env.local | xargs)" > .envrc
direnv allow
```

## Environment-Specific Database Migrations

```typescript
// scripts/migrate.ts
import { config } from '@/lib/env';
import { db } from '@/lib/db';

async function migrate() {
  console.log(`Running migrations for ${config.server.port === 3000 ? 'development' : 'production'}...`);

  if (config.server.isProd) {
    // Extra checks in production
    const backupBefore = true; // Always backup before prod migrations
    console.log('Creating backup...');
    // Backup logic
  }

  // Run migrations
  await db.$executeRawUnsafe(`SELECT 1`);

  console.log('Migrations complete');
}

migrate();
```

## Testing Different Environments

```typescript
// tests/integration.test.ts
beforeAll(() => {
  process.env.NODE_ENV = 'test';
  process.env.DATABASE_URL = 'postgresql://localhost/test_db';
  process.env.JWT_SECRET = 'test-secret';
  process.env.REDIS_URL = 'redis://localhost:6380';
});

it('works in test environment', async () => {
  const config = getConfig();
  expect(config.server.isDev).toBe(false);
  // Test with test database
});
```

## Checklist

- [ ] All secrets in environment variables
- [ ] `.env.local` in `.gitignore`
- [ ] `process.env` validated on startup
- [ ] Separate configs per environment
- [ ] Secrets in vault/secret manager
- [ ] Never log secrets
- [ ] Database backups before prod migrations
- [ ] Audit trail of secret access
