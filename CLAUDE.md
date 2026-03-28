# node-claude-kit Development Instructions

This document configures Claude Code for developing the node-claude-kit plugin itself.

## Project Overview

node-claude-kit is a comprehensive expert layer for full-stack Node.js development with Claude Code. It provides 40 skills, 8 specialist agents, 10 rules, 5 project templates, design documentation for 12 MCP tools, and 6 Git hooks.

### Architecture

The kit is organized into:
- **Skills**: 40 reusable reference files teaching Node.js best practices
- **Agents**: 8 specialist agents that activate for specific queries
- **Rules**: 10 always-loaded conventions enforced globally
- **Templates**: 5 starter CLAUDE.md files for different project types
- **MCP Reference**: Design documentation for 12 token-efficient navigation tools
- **Knowledge Base**: Living ADRs and architectural decision records

## Development Patterns

### Adding a New Skill

1. Create file: `skills/{category}/{skill-name}/SKILL.md`
2. Structure: ~350-400 lines max
3. Format:
   - Introduction (2-3 paragraphs)
   - When to use it (specific scenarios)
   - Core patterns with code examples
   - BAD/GOOD comparisons
   - Decision guides (if applicable)
   - Key packages/tools
4. Link from appropriate agent's skill list

### Adding a New Rule

1. Create file: `.claude/rules/{rule-name}.md`
2. ~200-250 lines
3. Start with enforcement statement
4. Provide BAD/GOOD examples
5. Add exceptions if any
6. Link from main README

### Adding a New Agent

1. Create file: `agents/{agent-name}.md`
2. Define activation triggers
3. List which skills it loads
4. Specify MCP tools it uses
5. Define boundaries (what it won't do)
6. Register in AGENTS.md

### How Agents Are Invoked

Rather than using slash commands, users invoke agents through natural language queries. The kit routes queries to the appropriate agent based on keywords:

- "Set up" / "init" → **node-architect**
- "Create endpoint" / "API" → **api-designer**
- "Database" / "migration" → **db-specialist**
- "Test" / "coverage" → **test-engineer**
- "Security" / "auth" → **security-auditor**
- "Performance" / "slow" → **performance-analyst**
- "Review" / "health check" → **code-reviewer**
- "Build failed" / "error" → **build-error-resolver**

See AGENTS.md for complete activation triggers.

## Tech Stack & Conventions

- **Language**: TypeScript 5.3+ with strict mode, ESM
- **Framework**: Fastify or Express for API examples
- **Database**: Prisma (primary), Sequelize (alternative)
- **Testing**: Vitest + Testcontainers
- **Validation**: Zod for schemas
- **Logging**: Pino for structured logging
- **Error Handling**: Custom Error subclasses + Result pattern

## Key Design Decisions

1. **Ask before architecture**: Never assume monolith vs serverless vs microservices
2. **Direct ORM usage**: No repository abstractions, use Prisma/Sequelize directly
3. **Integration-first testing**: Real databases via Testcontainers, not mocks
4. **Type-safe by default**: Strict TypeScript, no `any` in examples
5. **Async/await everywhere**: Proper error propagation, cancellation tokens
6. **Result pattern for errors**: Type-safe error handling, not exceptions for control flow
7. **ESM mandatory**: No CommonJS in examples or templates
8. **Token efficiency**: Use MCP tools instead of file reads whenever possible

## Code Review Checklist

When adding skills/rules/agents:
- [ ] Does it contradict existing rules?
- [ ] Are code examples real and runnable?
- [ ] Do BAD/GOOD comparisons teach effectively?
- [ ] Is the pattern truly modern for Node.js 20+?
- [ ] Are all dependencies documented?
- [ ] Could this skill be split into multiple focused skills?
- [ ] Are TypeScript examples strict mode?

## Testing Your Changes

1. **Skills**: Apply to a real Node.js project and verify patterns work
2. **Rules**: Check for contradictions with other rules
3. **Agents**: Verify activation triggers are specific enough
4. **Commands**: Trace through agent routing and skill loading

## Documentation

- Update README.md when adding major features
- Add ADRs for significant decisions (in knowledge/decisions/)
- Keep package-recommendations.md current with every Node.js LTS release
- Update nodejs-whats-new.md for breaking changes

## Conventions

- Use feature-driven (vertical slice) architecture in examples when architecture-agnostic
- Show pagination and async iteration patterns
- Always include error handling in code examples
- Use realistic domain examples (orders, products, users)
- Avoid overly simplified examples that miss edge cases

## Common Questions

**Q: Should we recommend a specific ORM?**
A: Primary is Prisma (modern DX, type safety). Sequelize as alternative for existing projects.

**Q: What about Deno/Bun?**
A: Focus on Node.js 20+. Bun compatibility for specific skills where it differs.

**Q: How do we handle monorepo vs single-repo?**
A: Separate architecture skill for modular monoliths. pnpm workspaces in examples.

**Q: What's the position on OOP vs functional?**
A: Both valid. Show functional for utilities/services, OOP for entities/aggregates (DDD context).

