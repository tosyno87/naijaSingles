#!/bin/bash

# Script to replace print() statements with AppLogger calls
# This is a helper script - review changes carefully before committing

echo "🔍 Finding all print() statements in lib/..."
echo ""

# Find all files with print() statements (excluding test files and this script)
files=$(grep -r "print(" lib/ --include="*.dart" | grep -v ".test.dart" | cut -d: -f1 | sort -u)

echo "Found print() statements in the following files:"
echo "$files"
echo ""
echo "📝 To replace manually, use this pattern:"
echo ""
echo "1. Add import at top of file:"
echo "   import '../utils/app_logger.dart';  (or appropriate relative path)"
echo ""
echo "2. Replace based on context:"
echo "   print('message')           -> AppLogger.info('message')"
echo "   print('Error: \$e')        -> AppLogger.error('Error', error: e)"
echo "   print('Warning: \$w')      -> AppLogger.warning('Warning', error: w)"
echo "   print('Debug: \$d')        -> AppLogger.debug('Debug', error: d)"
echo ""
echo "💡 For automated replacement (use with caution):"
echo "   sed -i '' \"s/print(\([^)]*\))/AppLogger.info(\1)/g\" <file>"
echo ""
echo "⚠️  Always review changes before committing!"

