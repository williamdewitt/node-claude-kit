# CLI Tool - Claude Code Configuration

## Project Overview

Standalone command-line application distributed as npm package.

### Tech Stack

- **CLI Framework**: Commander.js or Yargs
- **Language**: TypeScript with strict mode
- **Testing**: Vitest
- **Distribution**: npm package

### Structure

```
src/
├── cli.ts (entry point)
├── commands/
│   ├── create.ts
│   ├── deploy.ts
│   └── status.ts
├── lib/
│   ├── api-client.ts
│   └── config.ts
└── types/
    └── index.ts
```

## Development Practices

- Clear command names and descriptions
- Helpful error messages
- Progress indicators for long operations
- Structured output (JSON or formatted text)
- Configuration file support

## Distribution

- Publish to npm registry
- Users install with: `npm i -g your-cli`
- Support Node.js 20+

