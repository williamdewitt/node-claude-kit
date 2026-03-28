# Contributing to node-claude-kit

## How to Contribute

### Adding a New Skill

1. Create folder: `skills/{category}/{skill-name}/`
2. Create `SKILL.md` (~350-400 lines)
3. Include:
   - When to use section
   - Code examples (BAD/GOOD)
   - Decision guides
   - Related skills

### Adding a New Rule

1. Create: `.claude/rules/{rule-name}.md` (~200-250 lines)
2. Include:
   - Enforcement statement
   - BAD/GOOD examples
   - Exceptions (if any)

### Adding a New Agent

1. Create: `agents/{agent-name}.md`
2. Define activation triggers
3. List skills it loads
4. Specify MCP tools
5. Register in `AGENTS.md`

### Adding a New Command

1. Create: `commands/{command-name}.md`
2. Example usage
3. Which agent/skills it invokes
4. Register in `AGENTS.md`

## Quality Standards

- Code examples must be real and runnable
- BAD/GOOD comparisons must teach effectively
- Pattern must be modern for Node.js 20+
- All dependencies documented
- No contradictions with existing rules

## Testing Your Changes

- Apply skills to a real Node.js project
- Verify patterns work correctly
- Check for rule contradictions
- Test agent activation triggers

## Before Submitting

- Run `npm test` if applicable
- Update README.md for major features
- Add ADR for architectural decisions
- Verify no duplicate content
