# Node.js Navigator MCP Server

TypeScript AST-powered tools for token-efficient codebase navigation.

## Tools (12 total)

### Navigation Tools
- `find_symbol(name, kind?)` - Find type/function definitions
- `find_references(symbol)` - Find all usages
- `find_implementations(interface)` - Find interface implementations
- `find_callers(function)` - Find all callers of a function

### Analysis Tools
- `get_symbol_detail(symbol)` - Full signature, params, JSDoc
- `get_type_hierarchy(type)` - Inheritance chain
- `get_public_api(type)` - Public members only
- `get_dependency_graph(symbol, depth)` - Call dependency tree

### Diagnostic Tools
- `get_diagnostics(path?, scope)` - TypeScript/ESLint errors
- `detect_antipatterns()` - 15+ Node.js anti-patterns
- `find_dead_code()` - Unused exports
- `detect_circular_dependencies()` - Dependency cycles

## Implementation

Uses `ts-morph` for TypeScript AST analysis. Respects tsconfig.json and ESLint config.

## Performance

Each query returns 30-150 tokens vs 500-2000 for file reads. Estimated 10x token savings on codebase exploration.

