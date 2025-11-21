#!/bin/bash
failures=0
for i in $(seq 1 200); do
  printf "Run %3d: " "$i"
  if swift test 2>&1 | grep -q "Test run.*passed"; then
    echo "✓"
  else
    echo "✗ FAILED"
    failures=$((failures+1))
  fi
done
echo ""
echo "================================"
echo "Total runs: 200"
echo "Failures: $failures"
echo "Success rate: $(( (200 - failures) * 100 / 200 ))%"
