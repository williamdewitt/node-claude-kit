# GraphQL Patterns for Node.js

Building efficient, type-safe GraphQL APIs with Apollo Server, schema-first design, and resolver optimization.

## When to Use GraphQL vs REST

| Scenario | GraphQL | REST |
|----------|---------|------|
| **Multiple clients with different data needs** | Excellent | Over/under fetching |
| **Complex nested data** | Perfect | Requires multiple requests |
| **Real-time subscriptions** | Built-in | Requires WebSockets |
| **Simple CRUD operations** | Overkill | Perfect fit |
| **Public read-only APIs** | Good | Excellent |

## Schema-First Approach

```typescript
// schema.graphql
type User {
  id: ID!
  name: String!
  email: String!
  posts(limit: Int = 10): [Post!]!
  createdAt: DateTime!
}

type Post {
  id: ID!
  title: String!
  content: String!
  author: User!
  createdAt: DateTime!
}

type Query {
  user(id: ID!): User
  users(limit: Int = 10): [User!]!
  post(id: ID!): Post
}

type Mutation {
  createUser(input: CreateUserInput!): User!
  updatePost(id: ID!, input: UpdatePostInput!): Post!
  deletePost(id: ID!): Boolean!
}

input CreateUserInput {
  name: String!
  email: String!
  password: String!
}

input UpdatePostInput {
  title: String
  content: String
}
```

## Resolvers with Type Safety

```typescript
// resolvers.ts
import { GraphQLResolveInfo } from 'graphql';

interface ResolverContext {
  db: PrismaClient;
  userId: string | null;
  loaders: DataLoaders;
}

export const resolvers = {
  Query: {
    user: async (
      _parent: unknown,
      args: { id: string },
      context: ResolverContext,
      _info: GraphQLResolveInfo,
    ) => {
      return context.db.user.findUnique({
        where: { id: args.id },
      });
    },

    users: async (
      _parent: unknown,
      args: { limit: number },
      context: ResolverContext,
    ) => {
      return context.db.user.findMany({
        take: Math.min(args.limit, 100), // Prevent abuse
      });
    },
  },

  Mutation: {
    createUser: async (
      _parent: unknown,
      args: { input: CreateUserInput },
      context: ResolverContext,
    ) => {
      if (!context.userId) {
        throw new Error('Unauthorized');
      }

      const { name, email, password } = args.input;
      const hashedPassword = await bcrypt.hash(password, 10);

      return context.db.user.create({
        data: { name, email, passwordHash: hashedPassword },
      });
    },
  },

  User: {
    posts: async (
      parent: User,
      args: { limit: number },
      context: ResolverContext,
    ) => {
      return context.db.post.findMany({
        where: { authorId: parent.id },
        take: args.limit,
      });
    },
  },

  Post: {
    author: async (parent: Post, _args: unknown, context: ResolverContext) => {
      // Use dataloader to batch queries
      return context.loaders.userLoader.load(parent.authorId);
    },
  },
};
```

## DataLoader for Batch Optimization

Prevents N+1 query problem:

```typescript
// dataloaders.ts
import DataLoader from 'dataloader';

export interface DataLoaders {
  userLoader: DataLoader<string, User>;
  postLoader: DataLoader<string, Post>;
}

export function createDataLoaders(db: PrismaClient): DataLoaders {
  return {
    userLoader: new DataLoader(async (userIds) => {
      const users = await db.user.findMany({
        where: { id: { in: userIds as string[] } },
      });

      // Return in same order as requested
      const userMap = new Map(users.map((u) => [u.id, u]));
      return userIds.map((id) => userMap.get(id as string));
    }),

    postLoader: new DataLoader(async (postIds) => {
      const posts = await db.post.findMany({
        where: { id: { in: postIds as string[] } },
      });

      const postMap = new Map(posts.map((p) => [p.id, p]));
      return postIds.map((id) => postMap.get(id as string));
    }),
  };
}
```

## Apollo Server Setup

```typescript
// main.ts
import { ApolloServer } from '@apollo/server';
import { startStandaloneServer } from '@apollo/server/standalone';
import { readFileSync } from 'fs';

const typeDefs = readFileSync('./schema.graphql', 'utf-8');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  plugins: {
    didResolveOperation: async (context) => {
      // Log all operations
      console.log('Operation:', context.operationName);
    },

    willSendResponse: async (context) => {
      // Cleanup after request
      context.contextValue.dataloaders.clearAll?.();
    },
  },
});

const { url } = await startStandaloneServer(server, {
  listen: { port: 4000 },
  context: async () => ({
    db: prisma,
    userId: null, // Set from auth middleware
    loaders: createDataLoaders(prisma),
  }),
});

console.log(`GraphQL server running at ${url}`);
```

## Error Handling

```typescript
// error-handling.ts
import { GraphQLError } from 'graphql';

export class NotFoundError extends GraphQLError {
  constructor(resource: string) {
    super(`${resource} not found`, {
      extensions: { code: 'NOT_FOUND', status: 404 },
    });
  }
}

export class UnauthorizedError extends GraphQLError {
  constructor() {
    super('Unauthorized', {
      extensions: { code: 'UNAUTHORIZED', status: 401 },
    });
  }
}

// In resolver:
user: async (
  _parent: unknown,
  args: { id: string },
  context: ResolverContext,
) => {
  const user = await context.db.user.findUnique({
    where: { id: args.id },
  });

  if (!user) {
    throw new NotFoundError('User');
  }

  return user;
};
```

## Subscriptions (Real-Time)

```typescript
// schema.graphql
type Subscription {
  postCreated: Post!
  userOnline(userId: ID!): Boolean!
}

// resolvers.ts
Subscription: {
  postCreated: {
    subscribe: async function* () {
      for await (const post of postEventStream) {
        yield { postCreated: post };
      }
    },
  },
}
```

## BAD vs GOOD

```typescript
// ❌ BAD: N+1 query problem
User: {
  posts: async (parent: User) => {
    return db.post.findMany({ where: { authorId: parent.id } });
  },
}
// If you fetch 100 users, you run 100 queries!

// ✅ GOOD: Batch with DataLoader
User: {
  posts: async (parent: User, _args, context) => {
    return context.loaders.postLoader.load(parent.id);
  },
}
// Batches all 100 requests into 1 query
```

```typescript
// ❌ BAD: No depth limiting
Query: {
  user: (_, args) => db.user.findUnique({ where: { id: args.id } }),
}
// User can query: user { posts { author { posts { ... } } } } forever

// ✅ GOOD: Limit query depth
new ApolloServer({
  // ...
  plugins: {
    didResolveOperation: (context) => {
      const depth = getQueryDepth(context.document);
      if (depth > 5) {
        throw new Error('Query too deep');
      }
    },
  },
});
```

## Caching Strategy

```typescript
// Enable HTTP caching headers
const server = new ApolloServer({
  plugins: {
    willSendResponse: (context) => {
      context.response.http.headers.set('Cache-Control', 'public, max-age=300');
    },
  },
});
```

## Client Query Examples

```graphql
# Fetch user with only name and email
query GetUser($id: ID!) {
  user(id: $id) {
    name
    email
  }
}

# Fetch user with recent posts
query GetUserWithPosts($userId: ID!, $postLimit: Int!) {
  user(id: $userId) {
    name
    email
    posts(limit: $postLimit) {
      id
      title
      createdAt
    }
  }
}

# Subscribe to new posts
subscription OnPostCreated {
  postCreated {
    id
    title
    author {
      name
    }
  }
}
```

## Testing GraphQL

```typescript
// __tests__/queries.test.ts
it('fetches user with posts', async () => {
  const response = await server.executeOperation({
    query: gql`
      query GetUser($id: ID!) {
        user(id: $id) {
          name
          posts {
            title
          }
        }
      }
    `,
    variables: { id: 'user-123' },
  });

  expect(response.body.kind).toBe('single');
  expect(response.body.singleResult.data.user.name).toBe('Alice');
});
```
