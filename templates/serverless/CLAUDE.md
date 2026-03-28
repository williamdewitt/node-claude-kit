# Serverless Functions - Claude Code Configuration

## Project Overview

Event-driven application deployed as serverless functions (AWS Lambda, Vercel Functions).

### Tech Stack

- **Runtime**: Node.js 20+
- **Framework**: AWS SDK / Vercel SDK
- **Database**: PostgreSQL (managed RDS)
- **Cache**: ElastiCache or Upstash Redis
- **Events**: EventBridge / Pub/Sub

### Folder Structure

```
functions/
├── api/
│   ├── orders/
│   │   ├── create.ts
│   │   ├── get.ts
│   │   └── list.ts
│   └── products/
├── events/
│   ├── order-created.ts
│   └── payment-processed.ts
├── scheduled/
│   ├── cleanup.ts
│   └── reports.ts
└── shared/
    ├── db.ts
    └── middleware.ts
```

## Best Practices

- Minimize bundle size (tree-shake dependencies)
- Use connection pooling for databases
- Implement retry logic for transient failures
- Cache within function execution
- Optimize cold starts

