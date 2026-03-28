# Database Transactions Skill

## When to Use

Multi-step operations that must succeed or fail atomically. Transfers between accounts, order creation with inventory updates, etc.

## Prisma Transactions

```typescript
// Atomic operation: transfer funds
const transferFunds = async (
  fromUserId: string,
  toUserId: string,
  amount: number,
) => {
  return await prisma.$transaction(async (tx) => {
    // Deduct from sender
    await tx.account.update({
      where: { userId: fromUserId },
      data: { balance: { decrement: amount } },
    });
    
    // Add to recipient
    await tx.account.update({
      where: { userId: toUserId },
      data: { balance: { increment: amount } },
    });
    
    // Create audit log
    await tx.transaction.create({
      data: {
        fromUserId,
        toUserId,
        amount,
        type: 'TRANSFER',
      },
    });
  });
};
```

## Error Handling in Transactions

```typescript
const createOrder = async (input: CreateOrderInput) => {
  try {
    return await prisma.$transaction(async (tx) => {
      // Create order
      const order = await tx.order.create({
        data: { customerId: input.customerId, total: input.total },
      });
      
      // Deduct inventory
      for (const item of input.items) {
        await tx.product.update({
          where: { id: item.productId },
          data: { stock: { decrement: item.qty } },
        });
      }
      
      return order;
    });
  } catch (error) {
    // Entire transaction rolled back on error
    throw new DatabaseError('Order creation failed', { cause: error });
  }
};
```

## Nested Transactions

```typescript
// Prisma flattens nested $transaction calls
const complexOperation = async () => {
  return await prisma.$transaction(async (tx) => {
    const user = await createUserInTransaction(tx);
    const account = await createAccountInTransaction(tx);
    return { user, account };
  });
};

// Helper functions receive transaction client
const createUserInTransaction = async (tx: PrismaClient) => {
  return await tx.user.create({ data: { email: '...' } });
};
```

