# Node.js Claude Kit Agents

Eight specialist agents that automatically route queries to the right skills and tools.

## Agent Routing Rules

Agents are invoked based on query keywords and context:

| Agent | Activates When | Primary Skills | MCP Tools |
|-------|----------------|----------------|-----------|
| **node-architect** | "set up", "init", "architecture", "scaffold", "feature" | architecture-advisor, feature-driven, hexagonal | find_symbol, get_project_graph |
| **api-designer** | "endpoint", "API", "route", "versioning" | fastify-patterns, rest-api-design, api-versioning, authentication | detect_antipatterns, find_references |
| **db-specialist** | "database", "migration", "query", "Prisma" | prisma-patterns, database-transactions, migrations | find_references, detect_circular_dependencies |
| **test-engineer** | "test", "coverage", "integration test" | vitest-patterns, integration-testing, database-testing | find_dead_code, find_references |
| **security-auditor** | "security", "auth", "secrets", "OWASP" | security, authentication, error-handling | detect_antipatterns, get_diagnostics |
| **performance-analyst** | "performance", "optimization", "caching", "slow" | caching, performance rule, retry-strategies | get_dependency_graph, find_references |
| **code-reviewer** | "review", "PR", "health check", "conventions" | All architectural skills | detect_antipatterns, find_dead_code |
| **build-error-resolver** | "build fail", "type error", "lint error" | Type safety, coding-style rules | get_diagnostics, detect_antipatterns |

## Agent Specifications

### node-architect

**When activated**: "How should I structure this?", "Let's set up the project", "Scaffold a feature"

**What it does**:
1. Runs architecture questionnaire (domain complexity, team size, deployment)
2. Recommends appropriate architecture with reasoning
3. Scaffolds project structure or feature
4. Generates or updates CLAUDE.md

**Skills loaded**:
- architecture-advisor
- feature-driven
- hexagonal
- modular-monolith
- serverless-first
- project-structure

**Will NOT**: Make implementation decisions for complex features without asking

### api-designer

**When activated**: "Create an endpoint", "Design this API", "Add versioning"

**What it does**:
1. Designs endpoint contracts with OpenAPI metadata
2. Suggests appropriate HTTP status codes
3. Implements proper versioning
4. Sets up authentication if needed

**Skills loaded**:
- fastify-patterns
- rest-api-design
- api-versioning
- authentication

### db-specialist

**When activated**: "Write a migration", "Optimize this query", "Database design"

**What it does**:
1. Designs database schemas without unnecessary abstractions
2. Creates safe migrations with rollback paths
3. Optimizes queries (N+1 prevention, indexing)
4. Writes transaction flows

**Skills loaded**:
- prisma-patterns
- database-transactions
- migrations
- performance rule

### test-engineer

**When activated**: "Write tests", "Coverage is low", "Integration test this"

**What it does**:
1. Creates integration tests with real databases
2. Sets up test fixtures and factories
3. Implements Testcontainers setup
4. Generates realistic test data

**Skills loaded**:
- vitest-patterns
- integration-testing
- database-testing
- testing rule

### security-auditor

**When activated**: "Review security", "Add authentication", "OWASP"

**What it does**:
1. Audits code for security issues
2. Implements JWT authentication flow
3. Sets up secret management
4. Reviews OWASP top 10 compliance

**Skills loaded**:
- security rule
- authentication
- error-handling
- structued-logging

### performance-analyst

**When activated**: "This is slow", "Optimize caching", "Database bottleneck"

**What it does**:
1. Identifies performance bottlenecks
2. Recommends caching strategies
3. Optimizes database queries
4. Sets up monitoring

**Skills loaded**:
- caching
- performance rule
- retry-strategies
- docker-nodejs (for profiling)

### code-reviewer

**When activated**: "Review this PR", "Health check", "Code quality"

**What it does**:
1. Multi-dimensional code review
2. Detects conventions and enforces consistency
3. Runs codebase health assessment
4. Identifies dead code and anti-patterns

**Skills loaded**:
- All 10 rules
- All architecture skills
- Code quality patterns

**MCP Tools**:
- detect_antipatterns
- find_dead_code
- get_diagnostics
- find_references

### build-error-resolver

**When activated**: "Build failed", "Type errors", "Lint errors"

**What it does**:
1. Parses error messages
2. Categorizes errors (type, lint, missing import)
3. Fixes errors autonomously
4. Re-runs build to verify

**Skills loaded**:
- type-safety rule
- coding-style rule
- async-patterns rule
- modern-javascript

**MCP Tools**:
- get_diagnostics
- find_symbol
- find_references

