#!/bin/bash
# Type check before commit

echo "Running type check..."
npx tsc --noEmit

if [ $? -ne 0 ]; then
  echo "✗ Type errors found"
  exit 1
fi

echo "✓ Type check passed"
