#!/bin/bash
set -e

cd /Users/davidhughes/dev/SpotifyKit

echo "Running tests 100 times to check for flakiness..."
echo ""

for i in {1..100}; do
    printf "Run %3d/100: " $i
    if swift test --quiet 2>&1 > /dev/null; then
        echo "✓"
    else
        echo "✗ FAILED"
        echo "Test failed on run $i"
        exit 1
    fi
done

echo ""
echo "✅ SUCCESS: All 100 test runs passed!"
