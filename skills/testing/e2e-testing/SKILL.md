# End-to-End Testing with Playwright

Testing complete user journeys: login, create data, navigate, verify results.

## Setup

```bash
npm install -D @playwright/test
npx playwright install
```

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  testMatch: '**/*.e2e.ts',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',

  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
  ],
});
```

## Basic Test Structure

```typescript
// e2e/auth.e2e.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('user can sign up', async ({ page }) => {
    // Navigate to signup page
    await page.goto('/signup');

    // Fill form
    await page.fill('input[name="name"]', 'Alice Smith');
    await page.fill('input[name="email"]', 'alice@example.com');
    await page.fill('input[name="password"]', 'SecurePassword123!');

    // Submit form
    await page.click('button[type="submit"]');

    // Verify redirect to dashboard
    await expect(page).toHaveURL('/dashboard');

    // Verify welcome message
    await expect(page.locator('h1')).toContainText('Welcome, Alice');
  });

  test('user can log in', async ({ page }) => {
    await page.goto('/login');

    await page.fill('input[name="email"]', 'alice@example.com');
    await page.fill('input[name="password"]', 'SecurePassword123!');

    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/dashboard');
  });

  test('shows error for invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.fill('input[name="email"]', 'alice@example.com');
    await page.fill('input[name="password"]', 'WrongPassword');

    await page.click('button[type="submit"]');

    // Error message appears
    await expect(page.locator('[role="alert"]')).toContainText(
      'Invalid email or password',
    );

    // Stays on login page
    await expect(page).toHaveURL('/login');
  });
});
```

## Testing User Journeys

```typescript
// e2e/create-post-flow.e2e.ts
test('user can create and publish a post', async ({ page, context }) => {
  // 1. Login
  await page.goto('/login');
  await page.fill('input[name="email"]', 'alice@example.com');
  await page.fill('input[name="password"]', 'password123');
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL('/dashboard');

  // 2. Navigate to create post
  await page.click('a[href="/posts/create"]');
  await expect(page).toHaveURL('/posts/create');

  // 3. Fill form
  await page.fill('input[name="title"]', 'My First Post');
  await page.fill('textarea[name="content"]', 'This is my first post');
  await page.click('button:has-text("Save as Draft")');

  // 4. Verify draft was created
  await expect(page.locator('text=Draft saved')).toBeVisible();

  // 5. Publish post
  await page.click('button:has-text("Publish")');
  await expect(page.locator('text=Post published')).toBeVisible();

  // 6. Verify it appears in feed
  await page.goto('/feed');
  await expect(page.locator('text=My First Post')).toBeVisible();
});
```

## Testing Interactions

```typescript
// e2e/interactive-features.e2e.ts
test('user can like posts', async ({ page }) => {
  await page.goto('/feed');

  // Get initial like count
  const likeButton = page.locator('[data-testid="like-button"]').first();
  const initialCount = await page.locator('[data-testid="like-count"]').first().textContent();

  // Click like
  await likeButton.click();

  // Wait for update
  await page.waitForLoadState('networkidle');

  // Verify count increased
  const newCount = await page.locator('[data-testid="like-count"]').first().textContent();
  expect(Number(newCount)).toBe(Number(initialCount) + 1);

  // Button shows liked state
  await expect(likeButton).toHaveClass(/liked/);
});

test('user can filter posts by date', async ({ page }) => {
  await page.goto('/posts');

  // Select date range
  await page.selectOption('select[name="date-from"]', '2024-01-01');
  await page.selectOption('select[name="date-to"]', '2024-01-31');

  // Submit filter
  await page.click('button:has-text("Filter")');

  // Verify URL updated
  await expect(page).toHaveURL(/date-from=2024-01-01/);

  // Verify only January posts shown
  const posts = await page.locator('[data-testid="post-card"]').all();
  for (const post of posts) {
    const date = await post.getAttribute('data-date');
    expect(date).toMatch(/^2024-01-/);
  }
});
```

## Database Setup/Cleanup

```typescript
// e2e/fixtures.ts
import { test as base } from '@playwright/test';
import { db } from '@/lib/db';

export const test = base.extend({
  async db({ }, use) {
    // Create fresh database state
    await db.user.deleteMany();
    await db.post.deleteMany();

    // Create test data
    const user = await db.user.create({
      data: {
        email: 'test@example.com',
        name: 'Test User',
        passwordHash: await hashPassword('password123'),
      },
    });

    await use({ user });

    // Cleanup after test
    await db.user.deleteMany();
  },
});

// e2e/auth.e2e.ts
import { test } from './fixtures';

test('user can update profile', async ({ page, db }) => {
  // User already created by fixture
  await page.goto('/login');
  await page.fill('input[name="email"]', 'test@example.com');
  await page.fill('input[name="password"]', 'password123');
  await page.click('button[type="submit"]');

  // Update profile
  await page.goto('/settings');
  await page.fill('input[name="name"]', 'Updated Name');
  await page.click('button:has-text("Save")');

  // Verify in database
  const updated = await db.user.findUnique({
    where: { email: 'test@example.com' },
  });
  expect(updated.name).toBe('Updated Name');
});
```

## Mobile Testing

```typescript
// playwright.config.ts
projects: [
  { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  { name: 'iphone', use: { ...devices['iPhone 12'] } },
  { name: 'android', use: { ...devices['Pixel 5'] } },
];

// e2e/mobile-responsive.e2e.ts
test('works on mobile', async ({ page }) => {
  await page.goto('/');

  // Mobile menu works
  await page.click('[data-testid="mobile-menu-toggle"]');
  await expect(page.locator('nav')).toBeVisible();

  // Form is usable on small screen
  await page.goto('/contact');
  await page.fill('input[name="name"]', 'Alice');
  await expect(page.locator('input[name="name"]')).toHaveValue('Alice');
});
```

## Performance Testing

```typescript
test('homepage loads in under 3 seconds', async ({ page }) => {
  const startTime = Date.now();

  await page.goto('/');
  await page.waitForLoadState('networkidle');

  const duration = Date.now() - startTime;
  expect(duration).toBeLessThan(3000);
});
```

## Debugging Failed Tests

```bash
# Run test with debug UI
npx playwright test --debug

# Run single test file
npx playwright test e2e/auth.e2e.ts

# Run with headed browser (see what happens)
npx playwright test --headed

# View test report
npx playwright show-report
```

## Best Practices

1. **Use data-testid**: Explicit test selectors
2. **Test user flows**: Not individual components
3. **Avoid waits**: Use automatic waiting
4. **Keep tests isolated**: Each test should be independent
5. **Clean up after tests**: Reset database state
6. **Test critical paths**: Signup, checkout, payments
7. **Run in CI**: Catch regressions early
