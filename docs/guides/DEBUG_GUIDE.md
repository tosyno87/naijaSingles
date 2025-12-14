# Debug Tools Guide for NaijaSingles

## Overview
This guide explains how to use the debugging tools integrated into your NaijaSingles dating app to troubleshoot user discovery, matching, and database connectivity issues.

## Accessing Debug Tools

### Method 1: Debug Button (Recommended)
1. Run the app in **debug mode** (`flutter run`)
2. Look for a small red bug icon in the top-right corner of the main navigation screen
3. Tap the bug icon to open the debug menu
4. Select the debug function you want to run

### Method 2: Direct Code Usage
Import the debug class in any Dart file:
```dart
import 'package:naijasingles/debug/simple_debug.dart';

// Then call any function
await SimpleDebug.testDatabaseConnection();
```

## Available Debug Functions

### 1. Test Database Connection
**Purpose**: Verify Firebase connectivity and user authentication
**What it does**:
- Checks if user is logged in
- Queries the users collection
- Lists first 5 users with their names
- Shows connection status

**Console Output**:
```
🔍 Testing database connection...
✅ Current user: abc123xyz
📊 Found 3 users in database
👤 User: user1 - John Doe
👤 User: user2 - Jane Smith
```

### 2. Clear My Swipe History
**Purpose**: Reset swiped users to see them again during testing
**What it does**:
- Removes all entries from your `CheckedUser` subcollection
- Allows you to swipe on the same users multiple times
- Essential for testing the discovery algorithm

**When to use**:
- When you've swiped through all available users
- Testing different swipe scenarios
- Debugging user filtering logic

### 3. Show My Excluded Users
**Purpose**: Understand why certain users aren't appearing
**What it does**:
- Lists all users you've already swiped on
- Shows blocked users
- Helps identify filtering issues

**Console Output**:
```
🚫 Checking excluded users for: abc123xyz
👀 Already checked users: 5
   - user1
   - user2
   - user3
🚫 Blocked users: 1
   - blocked_user1
```

## Troubleshooting Common Issues

### Issue: No Users Appearing in Discovery
**Debug Steps**:
1. Run "Test Database Connection" to verify users exist
2. Run "Show My Excluded Users" to see who's filtered out
3. Run "Clear My Swipe History" to reset your swipes
4. Check console for any error messages

### Issue: Matches Not Working
**Debug Steps**:
1. Use the `testLikeCreation` function directly in code
2. Check Firestore console for like documents
3. Verify both users exist and are active

### Issue: Database Connection Problems
**Debug Steps**:
1. Run "Test Database Connection"
2. Check Firebase project configuration
3. Verify internet connectivity
4. Check Firestore security rules

## Advanced Debugging

### Using the Full Database Debug
For comprehensive testing, use the advanced debug script:
```dart
import 'package:naijasingles/debug/database_debug.dart';

// Run full database analysis
await DatabaseDebug.runFullDatabaseDebug();

// Test user discovery for specific user
await DatabaseDebug.testUserDiscovery('user_id_here');
```

### Console Output Meanings
- ✅ = Success/Completed
- ❌ = Error/Failed
- 🔍 = Testing/Checking
- 📊 = Data/Statistics
- 👤 = User Information
- 🚫 = Blocked/Excluded
- 💝 = Like/Match Related
- 🧹 = Cleanup/Reset

## Best Practices

1. **Always test in debug mode** - Debug tools only appear in debug builds
2. **Check console output** - All debug information is logged to the Flutter console
3. **Clear swipe history regularly** - When testing user discovery
4. **Use real test data** - Create multiple test users for comprehensive testing
5. **Monitor Firestore usage** - Debug operations count toward your Firebase quota

## Security Notes

- Debug tools are automatically disabled in release builds
- Never include debug tools in production apps
- Debug functions use the same security rules as your main app
- All operations are logged for transparency

## Need Help?

If you encounter issues with the debug tools:
1. Check the Flutter console for error messages
2. Verify your Firebase configuration
3. Ensure you're running in debug mode
4. Check that all required permissions are granted

Remember: These tools are designed to help you understand and fix user discovery issues in your dating app. Use them regularly during development to ensure a smooth user experience.
