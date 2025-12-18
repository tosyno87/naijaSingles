#!/bin/bash
# Linter Fix Strategy Script

echo "=== Step 1: Fix Critical Errors ==="
flutter analyze lib/ 2>&1 | grep "error •" | head -10

echo -e "\n=== Step 2: Run Auto-Fixes ==="
echo "Running: dart fix --apply"
# dart fix --apply

echo -e "\n=== Step 3: Check Remaining Issues ==="
flutter analyze lib/ 2>&1 | tail -1

echo -e "\n=== Step 4: Get Top Issues ==="
flutter analyze lib/ 2>&1 | grep -oE " • [a-z_]+ • " | sort | uniq -c | sort -rn | head -10
