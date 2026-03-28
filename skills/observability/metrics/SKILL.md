# Metrics and Monitoring

Exposing application metrics (requests, latency, errors) for monitoring and alerting.

## Prometheus Metrics

```bash
npm install prom-client
```

```typescript
// lib/metrics.ts
import { register, Counter, Histogram, Gauge } from 'prom-client';

export const httpRequestDuration = new Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [10, 50, 100, 500, 1000, 5000],
});

export const httpRequestTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

export const dbQueryDuration = new Histogram({
  name: 'db_query_duration_ms',
  help: 'Duration of database queries in ms',
  labelNames: ['model', 'action'],
  buckets: [1, 5, 10, 50, 100, 500],
});

export const activeConnections = new Gauge({
  name: 'active_connections',
  help: 'Number of active database connections',
});

export const appVersion = new Gauge({
  name: 'app_version_info',
  help: 'Application version',
  labelNames: ['version', 'build_date'],
});

// Initialize
appVersion.set(
  { version: '1.0.0', build_date: new Date().toISOString() },
  1,
);
```

## Middleware for HTTP Metrics

```typescript
// middleware/metrics.ts
import { FastifyRequest, FastifyReply } from 'fastify';
import {
  httpRequestDuration,
  httpRequestTotal,
} from '@/lib/metrics';

export async function metricsMiddleware(
  request: FastifyRequest,
  reply: FastifyReply,
) {
  const start = Date.now();

  reply.addHook('onResponse', async () => {
    const duration = Date.now() - start;

    httpRequestDuration
      .labels(
        request.method,
        request.url,
        reply.statusCode.toString(),
      )
      .observe(duration);

    httpRequestTotal
      .labels(
        request.method,
        request.url,
        reply.statusCode.toString(),
      )
      .inc();
  });
}

// app.ts
app.addHook('preHandler', metricsMiddleware);

// Expose metrics endpoint
app.get('/metrics', async (request, reply) => {
  reply.type('text/plain');
  return register.metrics();
});
```

## Database Query Metrics

```typescript
// lib/db.ts
import { PrismaClient } from '@prisma/client';
import { dbQueryDuration, activeConnections } from './metrics';

const db = new PrismaClient();

db.$use(async (params, next) => {
  const start = Date.now();

  try {
    const result = await next(params);
    const duration = Date.now() - start;

    dbQueryDuration
      .labels(params.model, params.action)
      .observe(duration);

    return result;
  } catch (error) {
    const duration = Date.now() - start;

    dbQueryDuration
      .labels(params.model, params.action)
      .observe(duration);

    throw error;
  }
});

// Track connection pool
setInterval(() => {
  const poolStatus = db.$metrics.pool;
  activeConnections.set(poolStatus.active);
}, 5000);

export { db };
```

## Error Tracking

```typescript
// lib/error-metrics.ts
import { Counter } from 'prom-client';

export const errors = new Counter({
  name: 'app_errors_total',
  help: 'Total number of errors',
  labelNames: ['error_type', 'route'],
});

// Middleware for error tracking
export async function errorMetricsMiddleware(error: Error, request: any) {
  errors.labels(error.constructor.name, request.url).inc();
}
```

## Custom Business Metrics

```typescript
// lib/business-metrics.ts
import { Counter, Gauge } from 'prom-client';

export const users = new Gauge({
  name: 'app_users_total',
  help: 'Total number of users',
});

export const posts = new Gauge({
  name: 'app_posts_total',
  help: 'Total number of posts',
  labelNames: ['status'],
});

export const paymentsProcessed = new Counter({
  name: 'payments_processed_total',
  help: 'Total number of payments processed',
  labelNames: ['status', 'currency'],
});

export async function updateMetrics() {
  const userCount = await db.user.count();
  users.set(userCount);

  const publishedCount = await db.post.count({
    where: { status: 'published' },
  });
  const draftCount = await db.post.count({
    where: { status: 'draft' },
  });

  posts.labels('published').set(publishedCount);
  posts.labels('draft').set(draftCount);
}

// Run metrics update every 5 minutes
setInterval(updateMetrics, 5 * 60 * 1000);
```

## Monitoring in Production

```typescript
// services/monitoring.ts
import fetch from 'node-fetch';

export async function sendMetricsToDatadog() {
  const metrics = await register.metrics();

  await fetch('https://api.datadoghq.com/api/v2/series', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'DD-API-KEY': process.env.DATADOG_API_KEY!,
    },
    body: JSON.stringify({
      series: parseMetrics(metrics),
    }),
  });
}

// Send metrics every minute
setInterval(sendMetricsToDatadog, 60000);
```

## Setting Up Alerts

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'nodejs-app'
    static_configs:
      - targets: ['localhost:3000']
    metrics_path: '/metrics'

rule_files:
  - 'alerts.yml'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']
```

```yaml
# alerts.yml
groups:
  - name: nodejs
    rules:
      - alert: HighErrorRate
        expr: rate(app_errors_total[5m]) > 0.05
        for: 5m
        annotations:
          summary: 'High error rate detected'

      - alert: SlowRequests
        expr: histogram_quantile(0.95, http_request_duration_ms) > 1000
        for: 5m
        annotations:
          summary: 'P95 request latency is high'

      - alert: DatabaseDown
        expr: up{job='postgres'} == 0
        for: 1m
        annotations:
          summary: 'Database is down'
```

## Key Metrics to Track

1. **Latency**: P50, P95, P99 response times
2. **Throughput**: Requests per second
3. **Error rate**: Errors per second
4. **Database connections**: Active/idle/max
5. **Memory**: Heap usage, GC pauses
6. **Custom**: Business-specific metrics
