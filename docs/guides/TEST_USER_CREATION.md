# Test User Creation Guide

## Overview

Test users can be created using the Cloud Function `createTestUsers`. This is the recommended approach as it:
- Runs server-side with full admin privileges
- Doesn't require Flutter dependencies
- Is secure and scalable
- Follows best practices

## Authentication Required

⚠️ **Security**: The function requires an admin secret token for authentication.

Set the admin secret as an environment variable:
```bash
# Set in Firebase Functions config
firebase functions:config:set admin.secret="your-secret-token-here"

# Or set directly when calling (development)
export ADMIN_SECRET="your-secret-token-here"
```

For production, use Firebase Functions config or environment variables.

## Using the Cloud Function

### Option 1: Call via HTTP (Recommended)

```bash
# Get admin secret from environment or Firebase config
ADMIN_SECRET="${ADMIN_SECRET:-dev-secret-change-in-production}"

curl -X POST \
  https://us-central1-naijasingles-74a75.cloudfunctions.net/createTestUsers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ADMIN_SECRET}" \
  -d '{"count": 60}'
```

### Option 2: Use Helper Script

```bash
# The helper script handles authentication
./scripts/create_test_users.sh 60
```

### Option 3: Call from Flutter App

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> createTestUsers({int count = 60}) async {
  const adminSecret = 'your-admin-secret'; // Store securely
  const functionUrl = 'https://us-central1-naijasingles-74a75.cloudfunctions.net/createTestUsers';
  
  try {
    final response = await http.post(
      Uri.parse(functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $adminSecret',
      },
      body: jsonEncode({'count': count}),
    );
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      print('✅ Created ${result['created']} users');
      print('❌ Failed: ${result['failed']}');
    } else {
      print('❌ Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

### Option 4: Test Locally with Emulator

```bash
# Start emulators
firebase emulators:start

# In another terminal, call the function
curl -X POST \
  http://localhost:5001/naijasingles-74a75/us-central1/createTestUsers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dev-secret-change-in-production" \
  -d '{"count": 60}'
```

## Parameters

The function accepts an optional request object:

```typescript
{
  count?: number;  // Total users to create (default: 60, min: 1, max: 500)
  cities?: Array<{
    name: string;
    lat: number;
    lng: number;
    key: string;
  }>;  // Custom cities (default: Atlanta, Miami, Houston)
}
```

**Validation**:
- `count` is automatically clamped between 1 and 500
- At least one city is required if provided

## Response

```typescript
{
  success: boolean;
  created: number;      // Number of users successfully created
  failed: number;       // Number of failures
  userIds?: string[];   // Array of created user IDs (omitted for batches > 100)
  message: string;      // Summary message
}
```

**Note**: For large batches (>100 users), `userIds` is omitted to keep response size manageable.

## What Gets Created

Each test user includes:
- **Firebase Auth account** with email/password (`testpassword123`)
- **Firestore document** with complete profile:
  - Name, age, gender
  - Location (randomized within city)
  - Interests (3-9 random interests)
  - Occupation and education
  - Bio (generated from interests)
  - Photos (placeholder URLs)
  - Dating preferences
  - Marked as `isTestUser: true`

## Default Behavior

- **Total users**: 60 (20 per city by default)
- **Cities**: Atlanta, Miami, Houston
- **Distribution**: 50% male, 50% female
- **Age range**: 22-45
- **Password**: `testpassword123` (for all test users)
- **Processing**: Users created in parallel batches of 10 for better performance
- **Error handling**: Orphaned Auth users are automatically cleaned up on Firestore failures

## Improvements & Features

✅ **Security**:
- Requires admin secret token authentication
- Input validation with reasonable limits (1-500 users)
- Proper error logging to Firestore

✅ **Performance**:
- Parallel batch processing (10 users at a time)
- Optimized rate limiting (200ms between batches)
- Efficient random data generation

✅ **Reliability**:
- Automatic cleanup of orphaned Auth users on failures
- Comprehensive error handling and logging
- Graceful handling of partial failures

## Deployment

```bash
# Build and deploy
cd functions
npm run build
cd ..
firebase deploy --only functions:createTestUsers
```

## Verification

After creation, verify in Firebase Console:
1. **Authentication → Users**: Should see new users with `test_*@test.com` emails
2. **Firestore → users collection**: Filter by `isTestUser == true`

## Troubleshooting

### Function not found
- Ensure functions are deployed: `firebase deploy --only functions`
- Check function name matches exactly

### Permission denied
- Ensure Firebase project is correct
- Check authentication if auth is enabled

### Rate limiting errors
- The function includes built-in delays
- If errors persist, reduce `count` parameter

## Old Script Files

The old Flutter-based scripts have been removed:
- ❌ `lib/scripts/create_test_users.dart` (deleted)
- ❌ `scripts/create_test_users_now.dart` (deleted)
- ❌ `scripts/run_create_test_users.sh` (deleted)

Use the Cloud Function instead.
