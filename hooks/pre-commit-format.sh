#!/bin/bash
# Format staged files with prettier and ESLint

set -e

echo "Formatting staged files..."

# Get staged files
STAGED=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.(js|ts|jsx|tsx)$' || true)

if [ -z "$STAGED" ]; then
  echo "No TypeScript files to format"
  exit 0
fi

# Format with prettier
npx prettier --write $STAGED

# Fix with ESLint
npx eslint --fix $STAGED

# Re-stage formatted files
git add $STAGED

echo "✓ Formatting complete"
