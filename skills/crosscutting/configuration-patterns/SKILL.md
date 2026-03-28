# Configuration Patterns for Modular Applications

Building flexible, type-safe configuration systems that work across features and modules.

## Simple Configuration Object

```typescript
// lib/config.ts
import { z } from 'zod';

const ConfigSchema = z.object({
  server: z.object({
    port: z.number().default(3000),
    nodeEnv: z.enum(['development', 'staging', 'production']),
  }),

  database: z.object({
    url: z.string().url(),
    pool: z.object({
      min: z.number().default(2),
      max: z.number().default(10),
    }),
  }),

  auth: z.object({
    jwtSecret: z.string().min(32),
    tokenExpiryHours: z.number().default(24),
  }),

  cache: z.object({
    type: z.enum(['redis', 'memory']),
    ttl: z.number().default(3600),
  }),

  external: z.object({
    stripe: z.object({
      apiKey: z.string(),
    }),
    sendgrid: z.object({
      apiKey: z.string(),
    }),
  }),
});

export type AppConfig = z.infer<typeof ConfigSchema>;

// Load and validate
export const config: AppConfig = ConfigSchema.parse({
  server: {
    port: parseInt(process.env.PORT || '3000'),
    nodeEnv: process.env.NODE_ENV || 'development',
  },

  database: {
    url: process.env.DATABASE_URL,
    pool: {
      min: parseInt(process.env.DB_POOL_MIN || '2'),
      max: parseInt(process.env.DB_POOL_MAX || '10'),
    },
  },

  auth: {
    jwtSecret: process.env.JWT_SECRET,
    tokenExpiryHours: parseInt(process.env.JWT_EXPIRY || '24'),
  },

  cache: {
    type: process.env.CACHE_TYPE === 'redis' ? 'redis' : 'memory',
    ttl: parseInt(process.env.CACHE_TTL || '3600'),
  },

  external: {
    stripe: { apiKey: process.env.STRIPE_API_KEY },
    sendgrid: { apiKey: process.env.SENDGRID_API_KEY },
  },
});
```

## Feature-Specific Configuration

```typescript
// features/auth/auth.config.ts
import { z } from 'zod';
import { config } from '@/lib/config';

const AuthConfigSchema = z.object({
  jwtSecret: z.string(),
  tokenExpiryHours: z.number(),
  allowedOrigins: z.array(z.string()),
  sessionTimeout: z.number(),
});

export type AuthConfig = z.infer<typeof AuthConfigSchema>;

export const authConfig: AuthConfig = AuthConfigSchema.parse({
  jwtSecret: config.auth.jwtSecret,
  tokenExpiryHours: config.auth.tokenExpiryHours,
  allowedOrigins: process.env.ALLOWED_ORIGINS?.split(',') || [
    'http://localhost:3000',
  ],
  sessionTimeout: parseInt(process.env.SESSION_TIMEOUT || '3600000'),
});

// features/auth/routes.ts
import { authConfig } from './auth.config';

app.post('/login', async (request, reply) => {
  const token = await generateToken(user, authConfig.tokenExpiryHours);
  // ...
});
```

## Environment-Specific Configuration

```typescript
// lib/config.base.ts
export const baseConfig = {
  server: {
    port: 3000,
  },
  logging: {
    level: 'info' as const,
  },
  cache: {
    ttl: 3600,
  },
};

// lib/config.development.ts
export const devConfig = {
  ...baseConfig,
  logging: {
    level: 'debug' as const,
  },
  cache: {
    ttl: 0, // Disable cache in development
  },
  server: {
    ...baseConfig.server,
    trustProxy: false,
  },
};

// lib/config.production.ts
export const prodConfig = {
  ...baseConfig,
  logging: {
    level: 'warn' as const,
  },
  cache: {
    ttl: 3600 * 24, // 24 hours
  },
  server: {
    ...baseConfig.server,
    trustProxy: true,
    https: true,
  },
};

// lib/config.ts
import { baseConfig } from './config.base';
import { devConfig } from './config.development';
import { prodConfig } from './config.production';

const configs = {
  development: devConfig,
  staging: baseConfig,
  production: prodConfig,
};

export const config = configs[process.env.NODE_ENV || 'development'];
```

## Configuration with Defaults

```typescript
// lib/config-builder.ts
class ConfigBuilder {
  private values: Record<string, any> = {};

  set<T extends Record<string, any>>(key: string, value: T): this {
    this.values[key] = value;
    return this;
  }

  setIfUndefined<T extends Record<string, any>>(
    key: string,
    value: T,
  ): this {
    if (!this.values[key]) {
      this.values[key] = value;
    }
    return this;
  }

  build() {
    return this.values;
  }
}

// Usage
const config = new ConfigBuilder()
  .set('database', { url: process.env.DATABASE_URL })
  .setIfUndefined('cache', { type: 'memory', ttl: 3600 })
  .setIfUndefined('server', { port: 3000 })
  .build();
```

## Merging Configurations

```typescript
// lib/config-merge.ts
export function mergeConfigs<T extends Record<string, any>>(
  base: T,
  overrides: Partial<T>,
): T {
  const merged = { ...base };

  for (const key in overrides) {
    if (overrides[key] !== undefined) {
      if (
        typeof overrides[key] === 'object' &&
        !Array.isArray(overrides[key])
      ) {
        merged[key] = {
          ...base[key],
          ...overrides[key],
        };
      } else {
        merged[key] = overrides[key];
      }
    }
  }

  return merged;
}

// Usage
const baseConfig = { database: { url: 'localhost' }, port: 3000 };
const envConfig = { database: { url: process.env.DATABASE_URL } };

const finalConfig = mergeConfigs(baseConfig, envConfig);
```

## Testing with Different Configurations

```typescript
// tests/with-config.ts
import { beforeEach } from 'vitest';
import { config } from '@/lib/config';

export function withConfig(testConfig: Partial<AppConfig>) {
  beforeEach(() => {
    Object.assign(config, testConfig);
  });
}

// tests/auth.test.ts
describe('Auth', () => {
  withConfig({
    auth: {
      jwtSecret: 'test-secret',
      tokenExpiryHours: 1,
    },
  });

  it('uses test config', () => {
    expect(config.auth.tokenExpiryHours).toBe(1);
  });
});
```

## Configuration Validation at Startup

```typescript
// lib/config-validator.ts
export function validateConfig(config: AppConfig) {
  const errors: string[] = [];

  // Check critical settings
  if (!config.database.url) {
    errors.push('DATABASE_URL is required');
  }

  if (!config.auth.jwtSecret) {
    errors.push('JWT_SECRET is required and must be at least 32 characters');
  }

  if (
    config.server.nodeEnv === 'production' &&
    !config.external.stripe.apiKey
  ) {
    errors.push('STRIPE_API_KEY is required in production');
  }

  if (errors.length > 0) {
    console.error('Configuration validation failed:');
    errors.forEach(err => console.error(`  - ${err}`));
    process.exit(1);
  }

  console.log('✓ Configuration is valid');
}

// main.ts
import { config } from '@/lib/config';
import { validateConfig } from '@/lib/config-validator';

validateConfig(config);
// Server starts only after validation passes
```

## Hot-Reloading Configuration

```typescript
// lib/config-hot-reload.ts
import { watch } from 'fs';

let currentConfig = loadConfig();

export function watchConfig(onUpdate: (config: AppConfig) => void) {
  watch('.env.local', (eventType, filename) => {
    console.log(`Config file changed: ${filename}`);

    try {
      currentConfig = loadConfig();
      onUpdate(currentConfig);
    } catch (error) {
      console.error('Failed to reload config:', error);
    }
  });
}

export function getConfig() {
  return currentConfig;
}
```

## Best Practices

1. **Validate on startup**: Fail fast if config is invalid
2. **Type-safe**: Use Zod or TypeScript for type safety
3. **Default values**: Provide sensible defaults
4. **Environment-specific**: Different config per environment
5. **Single responsibility**: Each config module handles one area
6. **Document required vars**: List all required env vars
7. **Never hardcode secrets**: All secrets from environment
