# Circuit Breaker Pattern

Prevents cascading failures by monitoring external service calls and "breaking the circuit" (failing fast) when the service is degraded.

## When to Use It

- **External APIs**: Stripe, SendGrid, third-party services
- **Microservices**: Service-to-service calls
- **Database failover**: Detect and recover from database issues
- **Preventing cascades**: Stop retrying failing requests

## States

1. **Closed** (normal): Requests pass through
2. **Open** (broken): Requests fail immediately
3. **Half-Open** (testing): Allow one request to test recovery

```typescript
// lib/circuit-breaker.ts
import Polly, { ClassicHandler } from 'polly-js';

export class CircuitBreaker {
  private failureCount = 0;
  private successCount = 0;
  private lastFailureTime?: number;
  private state: 'closed' | 'open' | 'half-open' = 'closed';

  readonly failureThreshold = 5; // Open after 5 failures
  readonly successThreshold = 2; // Close after 2 successes
  readonly timeout = 60000; // 60 seconds

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (Date.now() - (this.lastFailureTime || 0) > this.timeout) {
        this.state = 'half-open';
        this.successCount = 0;
      } else {
        throw new Error('Circuit breaker is open');
      }
    }

    try {
      const result = await fn();

      if (this.state === 'half-open') {
        this.successCount++;
        if (this.successCount >= this.successThreshold) {
          this.state = 'closed';
          this.failureCount = 0;
        }
      } else {
        this.failureCount = 0;
      }

      return result;
    } catch (error) {
      this.failureCount++;
      this.lastFailureTime = Date.now();

      if (this.failureCount >= this.failureThreshold) {
        this.state = 'open';
      }

      throw error;
    }
  }

  getState() {
    return this.state;
  }
}
```

## Using with External Services

```typescript
// lib/stripe-client.ts
import Stripe from 'stripe';
import { CircuitBreaker } from './circuit-breaker';

const stripe = new Stripe(process.env.STRIPE_API_KEY!);
const circuitBreaker = new CircuitBreaker();

export async function createCharge(
  amount: number,
  source: string,
): Promise<Stripe.Charge> {
  return circuitBreaker.execute(async () => {
    return stripe.charges.create({
      amount,
      currency: 'usd',
      source,
    });
  });
}

// Usage with fallback
export async function processPayment(
  userId: string,
  amount: number,
): Promise<PaymentResult> {
  try {
    const charge = await createCharge(amount, userId);
    return { success: true, chargeId: charge.id };
  } catch (error) {
    if (error.message === 'Circuit breaker is open') {
      // Queue payment for retry later
      await db.paymentQueue.create({
        userId,
        amount,
        status: 'pending',
      });

      return {
        success: true,
        message: 'Payment queued for processing',
      };
    }

    throw error;
  }
}
```

## Using Polly (Advanced)

```typescript
// lib/resilience.ts
import * as Polly from 'polly-js';

const policyWrap = Polly.Wrap()
  .Retry()
  .CircuitBreaker(
    // Open after 5 failures
    Polly.CircuitBreaker.IsolatedCircuitBreakerPolicy(5),
  )
  .Timeout(5000) // 5 second timeout
  .Bulkhead(10); // Max 10 concurrent requests

export async function callStripe<T>(
  fn: () => Promise<T>,
): Promise<T> {
  return policyWrap.Execute(fn);
}

// Usage
const charge = await callStripe(() =>
  stripe.charges.create({ amount: 100, currency: 'usd', source: 'tok_visa' }),
);
```

## Graceful Degradation

```typescript
interface GetUserProfileOptions {
  includePremiumFeatures?: boolean;
}

export async function getUserProfile(
  userId: string,
  options?: GetUserProfileOptions,
) {
  const user = await db.user.findUnique({ where: { id: userId } });

  // Premium features depend on external service
  if (options?.includePremiumFeatures) {
    try {
      const subscription = await circuitBreaker.execute(() =>
        stripe.subscriptions.retrieve(user.stripeSubId),
      );

      return { ...user, subscription };
    } catch (error) {
      // Service down? Return basic profile
      console.error('Could not fetch subscription:', error);
      return user;
    }
  }

  return user;
}
```

## Testing Circuit Breaker

```typescript
it('opens circuit after failures', async () => {
  const breaker = new CircuitBreaker();

  let callCount = 0;
  const failingFn = async () => {
    callCount++;
    throw new Error('Service down');
  };

  // Fail 5 times
  for (let i = 0; i < 5; i++) {
    await expect(breaker.execute(failingFn)).rejects.toThrow();
  }

  // Circuit should be open now
  expect(breaker.getState()).toBe('open');

  // Next call fails immediately
  await expect(breaker.execute(failingFn)).rejects.toThrow('Circuit breaker is open');
  expect(callCount).toBe(5); // No new call attempted
});

it('closes circuit after recovery', async () => {
  const breaker = new CircuitBreaker();

  let callCount = 0;
  let shouldFail = true;

  const flakeyFn = async () => {
    callCount++;
    if (shouldFail) throw new Error('Service down');
    return 'success';
  };

  // Fail 5 times to open circuit
  for (let i = 0; i < 5; i++) {
    await expect(breaker.execute(flakeyFn)).rejects.toThrow();
  }

  expect(breaker.getState()).toBe('open');

  // Wait for timeout
  await new Promise(resolve => setTimeout(resolve, 61000));

  // Now service is up
  shouldFail = false;

  // First request tests recovery
  const result = await breaker.execute(flakeyFn);
  expect(result).toBe('success');

  // Second successful request closes circuit
  await breaker.execute(flakeyFn);
  expect(breaker.getState()).toBe('closed');
});
```

## Monitoring and Alerts

```typescript
export class MonitoredCircuitBreaker extends CircuitBreaker {
  private metrics = {
    totalRequests: 0,
    totalFailures: 0,
    stateChanges: 0,
  };

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    this.metrics.totalRequests++;

    try {
      return await super.execute(fn);
    } catch (error) {
      this.metrics.totalFailures++;

      if (this.getState() === 'open') {
        // Alert: Circuit breaker opened
        console.error(`Circuit breaker opened: ${this.constructor.name}`);
        sendAlert('circuit-breaker-opened', {
          service: this.constructor.name,
          failureRate:
            this.metrics.totalFailures / this.metrics.totalRequests,
        });
      }

      throw error;
    }
  }

  getMetrics() {
    return this.metrics;
  }
}
```

## Key Takeaways

1. **Fast fail is better than slow cascade**: Circuit breaker detects issues early
2. **Graceful degradation**: Provide fallback when service is down
3. **Queue for retry**: Don't lose work, retry when service recovers
4. **Monitor and alert**: Know when circuits open
5. **Set thresholds carefully**: Too sensitive = false positives, too loose = too slow to detect
