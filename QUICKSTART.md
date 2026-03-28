# node-claude-kit Quick Start Guide

## Installation

### Option 1: Local Development (Recommended for Testing)

```bash
# Start Claude Code with the plugin loaded from local disk
claude --plugin-dir /c/Dev/node-claude-kit
```

This loads the plugin immediately without needing marketplace installation.

### Option 2: As Claude Code Plugin

Once ready for wider use:

```bash
# In Claude Code
/plugin marketplace add claude-kit/node-claude-kit
/plugin install node-claude-kit
```

## First Steps

### 1. Initialize a New Project

```bash
/node-init
```

This will:
- Ask about your project type (API, full-stack, monolith, serverless, CLI)
- Detect existing projects and suggest architecture
- Generate a customized `CLAUDE.md` with all rules and agent routing

### 2. Check Codebase Health

```bash
/health-check
```

Get an A-F grade on your codebase covering:
- Code quality and anti-patterns
- TypeScript strictness
- Test coverage
- Security issues
- Performance concerns

### 3. Scaffold Your First Feature

```bash
/scaffold
```

Creates a complete feature with:
- Handler/service/types
- Zod validation
- OpenAPI metadata
- Integration tests
- Error handling

## Available Commands

| Command | Use Case |
|---------|----------|
| `/node-init` | Setup new project or detect existing |
| `/plan` | Architecture-aware task planning |
| `/verify` | 8-phase verification pipeline |
| `/scaffold` | Generate complete features |
| `/code-review` | AST-powered PR reviews |
| `/security-scan` | OWASP audit + secrets detection |
| `/health-check` | Codebase health assessment |
| `/build-fix` | Autonomous build error fixing |
| `/tdd` | Test-driven development workflow |
| `/checkpoint` | Save progress with git commit |

## What Makes This Powerful

### 1. **Rules** enforce best practices automatically
- No `any` types in TypeScript
- Async/await, never Promise chains
- Error classes, not generic exceptions
- Direct ORM usage, no abstractions

### 2. **Skills** teach production patterns
- 28 reference files with code examples
- BAD/GOOD comparisons for learning
- Decision guides for architecture
- Real-world scenarios

### 3. **Agents** route to specialists
- api-designer for endpoint design
- db-specialist for query optimization
- test-engineer for test strategy
- security-auditor for vulnerability audits

### 4. **MCP Tools** save 10x tokens
- TypeScript AST navigation (not file reads)
- Find symbols, references, implementations
- Detect anti-patterns, dead code, cycles

## Example Workflow

```bash
# 1. Initialize project
/node-init
# → Choose "web-api" template
# → CLAUDE.md generated

# 2. Plan first feature
/plan
# → "Add order creation API endpoint"
# → Get architecture-aware recommendations

# 3. Scaffold the feature
/scaffold
# → Complete handler + service + tests
# → OpenAPI docs generated
# → Validation and error handling included

# 4. Code review
/code-review
# → Multi-dimensional review
# → Anti-pattern detection
# → Convention enforcement

# 5. Checkpoint
/checkpoint
# → Automatic git commit
# → Handoff notes for team
```

## Customization

### Project-Specific CLAUDE.md

After `/node-init`, edit your `CLAUDE.md` to:
- Override architecture choice
- Add team-specific conventions
- Configure which rules to enforce
- Set up custom shortcuts

Example:

```markdown
## Project Specific Rules

### Naming
- All API routes use `/api/v1/` prefix
- Services end with `Service` suffix
- Use camelCase for variables

### Always Load These Skills
- fastify-patterns
- prisma-patterns
- vitest-patterns

### Never Use These Patterns
- Callback-based APIs
- Repository abstractions
- In-memory test databases
```

## Tips for Success

1. **Start with `/health-check`** to understand current state
2. **Use `/scaffold`** for consistency in new features
3. **Review `/code-review`** output to learn patterns
4. **Reference the skills** when you have questions
5. **Extend CLAUDE.md** as you discover team preferences

## Troubleshooting

### Plugin not loading?

```bash
# Verify the plugin directory
ls /c/Dev/node-claude-kit/.claude-plugin/plugin.json

# Restart Claude Code
claude --plugin-dir /c/Dev/node-claude-kit
```

### Commands not showing up?

1. Make sure CLAUDE.md exists in your project
2. Check that rules are in `.claude/rules/`
3. Verify skills match the architecture chosen

### MCP server errors?

The AST navigator requires TypeScript 5.3+ and Node.js 20+:

```bash
node --version  # Should be v20.0.0+
npm list typescript  # Should be 5.3+
```

## Next: Testing Real Projects

See the `templates/` folder for example project setups:
- **web-api** - REST backend with Fastify
- **full-stack-nextjs** - Next.js full-stack app
- **modular-monolith** - Multi-module system
- **serverless** - AWS Lambda functions
- **cli-tool** - CLI applications

