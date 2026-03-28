#!/bin/bash
# Analyze test results

if [ -f "coverage/coverage-summary.json" ]; then
  echo "Coverage Summary:"
  npx c8 report --reporter=text-summary
fi
