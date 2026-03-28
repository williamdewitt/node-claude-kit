<p align="center">
  <h1 align="center">node-claude-kit</h1>
  <p align="center">
    <strong>Make Claude Code an expert full-stack Node.js developer.</strong>
    <br />
    40 skills • 8 specialist agents • 16 slash commands • 10 rules • 5 project templates • 12 MCP tools • 6 hooks
    <br />
    Built for Node.js 20+ / TypeScript 5.3+. Architecture-aware. Token-efficient.
  </p>
</p>

<p align="center">
  <a href="#installation">Installation</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#10x-features">10x Features</a> •
  <a href="#slash-commands">Commands</a> •
  <a href="#skills">Skills</a> •
  <a href="#agents">Agents</a> •
  <a href="#rules">Rules</a> •
  <a href="#templates">Templates</a> •
  <a href="#ast-mcp-server">MCP Server</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## The Problem

Claude Code is powerful, but out of the box it doesn't know **your** Node.js conventions. It generates `new Date()` instead of `Date.now()`. It wraps ORMs in repository abstractions. It picks architecture without understanding your domain. It reads entire source files when AST queries would cost 10x fewer tokens.

**node-claude-kit fixes all of that.**

## What This Is

A curated knowledge and action layer that sits between Claude Code and your Node.js project. Drop a single `CLAUDE.md` into your repo and Claude instantly knows:

- Which architecture fits your project (feature-driven, hexagonal, modular monolith, serverless, microservices)
- How to write modern JavaScript/TypeScript with proper async/await, destructuring, and ESM patterns
- How to build REST APIs and GraphQL with proper OpenAPI metadata and versioning
- How to use Prisma/Sequelize directly without wrapper abstractions, with query optimization and transactions
- How to test with integration tests + real databases via Testcontainers instead of mocked everything
- How to navigate your codebase via TypeScript AST instead of expensive file reads
- **How to scaffold complete features, run health checks, review PRs, and enforce conventions**

**No configuration. No setup wizards. Just copy one file and go.**

## Installation

### Plugin Install (Recommended)

```bash
# Install the AST MCP server (requires Node.js 20+)
npm install -g @node-claude-kit/ast-mcp
```

Then inside a Claude Code session:

```
/plugin marketplace add claude-kit/node-claude-kit
/plugin install node-claude-kit
```

### Per-Project Setup

```bash
/node-init
```

This detects your existing project or scaffolds a new one, then generates a customized `CLAUDE.md`.

## Slash Commands (16)

| Command | Purpose |
|---------|---------|
| `/node-init` | Project setup and CLAUDE.md generation |
| `/plan` | Architecture-aware planning |
| `/verify` | 8-phase verification pipeline |
| `/tdd` | Test-driven development workflow |
| `/scaffold` | Feature scaffolding (API, page, service) |
| `/code-review` | AST-powered code review |
| `/build-fix` | Autonomous error fixing loop |
| `/checkpoint` | Save progress with git commit |
| `/security-scan` | OWASP + dependencies audit |
| `/migrate` | Safe database migration workflow |
| `/health-check` | Codebase health assessment |
| `/de-sloppify` | Systematic cleanup |
| `/wrap-up` | Session ending ritual |
| `/instinct-status` | Show learned patterns |
| `/instinct-export` | Export patterns to file |
| `/instinct-import` | Import patterns from file |

## Rules (10)

| Rule | Enforces |
|------|----------|
| [coding-style](.claude/rules/coding-style.md) | ESM, const-first, destructuring |
| [architecture](.claude/rules/architecture.md) | Feature-driven, direct ORM, proper dependencies |
| [async-patterns](.claude/rules/async-patterns.md) | Async/await, error propagation, cancellation |
| [type-safety](.claude/rules/type-safety.md) | Strict TypeScript, no `any`, exhaustive checks |
| [security](.claude/rules/security.md) | No secrets, parameterized queries, auth |
| [testing](.claude/rules/testing.md) | Integration-first, real databases |
| [error-handling](.claude/rules/error-handling.md) | Error subclasses, Result pattern |
| [performance](.claude/rules/performance.md) | Connection pooling, caching, N+1 prevention |
| [api-design](.claude/rules/api-design.md) | OpenAPI metadata, proper HTTP semantics |
| [git-workflow](.claude/rules/git-workflow.md) | Conventional commits, atomic, no force-push |

## Agents (8)

- **node-architect**: Project setup, architecture decisions, feature scaffolding
- **api-designer**: REST/GraphQL endpoint design, versioning, auth
- **db-specialist**: Query optimization, migrations, transactions
- **test-engineer**: Integration testing, test strategy
- **security-auditor**: Security audit, auth, OWASP
- **performance-analyst**: Optimization, caching, profiling
- **code-reviewer**: PR review, conventions, health checks
- **build-error-resolver**: Autonomous build/type/lint fixing

## Templates (5)

1. **web-api** - REST backend with Fastify, Prisma, Zod
2. **full-stack-nextjs** - Next.js app with server components
3. **modular-monolith** - Multi-module Node.js system
4. **serverless** - AWS Lambda / Vercel Functions
5. **cli-tool** - Standalone CLI applications

## Skills by Category (40 total)

- **Architecture** (6): architecture-advisor, feature-driven, hexagonal, modular-monolith, serverless-first, microservices
- **Language** (4): modern-javascript, typescript-patterns, destructuring, async-await
- **Web/APIs** (5): fastify-patterns, rest-api-design, graphql-patterns, api-versioning, authentication
- **Data** (4): prisma-patterns, database-transactions, query-optimization, migrations
- **Full-Stack** (3): next-js-patterns, react-best-practices, state-management
- **Resilience** (4): error-handling, retry-strategies, circuit-breaker, caching
- **Observability** (3): structured-logging, distributed-tracing, metrics
- **Testing** (4): vitest-patterns, integration-testing, database-testing, e2e-testing
- **DevOps** (3): docker-nodejs, ci-cd, environment-config
- **Cross-cutting** (3): dependency-injection, configuration-patterns, validation
- **Workflow** (2): workflow-mastery, parallel-dev

## AST MCP Server

12 TypeScript AST-powered tools for token-efficient codebase navigation:

- `find_symbol` - Locate definitions
- `find_references` - Find all usages
- `find_implementations` - Find interface implementations
- `find_callers` - Find all callers
- `get_type_hierarchy` - Inheritance chains
- `get_project_graph` - Dependency tree
- `get_public_api` - Public exports
- `get_symbol_detail` - Full signatures
- `get_diagnostics` - Type/lint errors
- `detect_antipatterns` - 15+ Node.js anti-patterns
- `find_dead_code` - Unused symbols
- `detect_circular_dependencies` - Dependency cycles

## Hooks (6)

- `pre-bash-guard.sh` - Block destructive operations
- `pre-commit-format.sh` - Prettier + ESLint
- `pre-commit-typecheck.sh` - TypeScript checking
- `post-edit-format.sh` - Auto-format on edit
- `post-test-analyze.sh` - Test result analysis
- `pre-build-validate.sh` - Project structure validation

---

Built for full-stack Node.js development with Claude Code
