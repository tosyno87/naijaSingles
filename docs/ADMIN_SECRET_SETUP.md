# Admin Secret Configuration Guide

## Overview

The `createTestUsers` Cloud Function requires an admin secret token for authentication. This prevents unauthorized access to the function that can create test users.

## Current Configuration

✅ **Secure secret has been generated and configured**

- **Secret**: Stored in Firebase Functions config and `.env.local`
- **Status**: Active and deployed
- **Location**: `functions/config/admin.secret`

## Using the Admin Secret

### Option 1: Use Helper Script (Recommended)

The helper script automatically reads from `.env.local`:

```bash
# The script will use the secret from .env.local
./scripts/create_test_users.sh 60
```

### Option 2: Use Environment Variable

```bash
# Load from .env.local
source .env.local

# Or set manually
export ADMIN_SECRET="your-secret-here"

# Then use the script or curl
./scripts/create_test_users.sh 60
```

### Option 3: Direct curl Call

```bash
# Read secret from .env.local
source .env.local

curl -X POST \
  https://us-central1-naijasingles-74a75.cloudfunctions.net/createTestUsers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_SECRET" \
  -d '{"count": 60}'
```

### Option 4: From Flutter App

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> createTestUsers({int count = 60}) async {
  // Load .env file (should contain ADMIN_SECRET)
  await dotenv.load(fileName: '.env.local');
  final adminSecret = dotenv.env['ADMIN_SECRET'];
  
  if (adminSecret == null) {
    throw Exception('ADMIN_SECRET not found in .env.local');
  }
  
  const functionUrl = 'https://us-central1-naijasingles-74a75.cloudfunctions.net/createTestUsers';
  
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
  } else {
    print('❌ Error: ${response.statusCode} - ${response.body}');
  }
}
```

## Secret Storage Locations

The function checks for the secret in this order:

1. **Firebase Functions Config** (Production) - Set via `firebase functions:config:set`
2. **Environment Variable** (`ADMIN_SECRET`) - For local development
3. **Default Dev Secret** - Only for local testing (not secure)

## Security Best Practices

### ✅ DO:
- Keep `.env.local` in `.gitignore` (already done)
- Use different secrets for dev/staging/production
- Rotate secrets periodically
- Use strong, random secrets (64+ characters)
- Store production secrets in Firebase Functions config
- Store staging secrets in GitHub Secrets for CI/CD

### ❌ DON'T:
- Commit `.env.local` to git
- Share secrets in chat/messages
- Use weak or predictable secrets
- Use the same secret for all environments
- Hardcode secrets in code

## Updating the Secret

### Change Firebase Functions Config

```bash
# Generate new secret
openssl rand -hex 32

# Update Firebase config
firebase functions:config:set admin.secret="new-secret-here"

# Redeploy function
firebase deploy --only functions:createTestUsers

# Update .env.local
echo "ADMIN_SECRET=new-secret-here" > .env.local
```

### Update Local Development

```bash
# Edit .env.local
echo "ADMIN_SECRET=your-new-secret" > .env.local

# The helper script will automatically use it
./scripts/create_test_users.sh 60
```

## Troubleshooting

### "Unauthorized" Error

If you get `401 Unauthorized`:

1. **Check secret is correct:**
   ```bash
   # Verify .env.local has the secret
   cat .env.local | grep ADMIN_SECRET
   ```

2. **Verify Firebase Functions config:**
   ```bash
   firebase functions:config:get
   ```

3. **Check Authorization header format:**
   ```bash
   # Should be: Authorization: Bearer YOUR_SECRET
   # Not: Authorization: YOUR_SECRET
   ```

### Function Not Reading Config

After setting Firebase Functions config, you must:
1. Redeploy the function: `firebase deploy --only functions:createTestUsers`
2. Wait a few seconds for the function to update
3. Test again

### Secret Not Working After Deployment

The function code checks in this order:
1. `functions.config().admin.secret` (Firebase config)
2. `process.env.ADMIN_SECRET` (environment variable)
3. Default dev secret

Make sure you've redeployed after setting the config.

## Multiple Environments

When you set up separate Firebase projects:

### Development
```bash
firebase functions:config:set admin.secret="dev-secret" --project naijasingles-dev
```

### Staging
```bash
firebase functions:config:set admin.secret="staging-secret" --project naijasingles-staging
```

### Production
```bash
firebase functions:config:set admin.secret="production-secret" --project naijasingles-prod
```

## CI/CD Integration

For GitHub Actions, store secrets in GitHub Secrets:

```yaml
# .github/workflows/staging.yml
env:
  ADMIN_SECRET: ${{ secrets.ADMIN_SECRET_STAGING }}

steps:
  - name: Create test users
    run: |
      curl -X POST \
        https://us-central1-naijasingles-staging.cloudfunctions.net/createTestUsers \
        -H "Authorization: Bearer $ADMIN_SECRET" \
        -d '{"count": 60}'
```

## Verification

To verify your secret is working:

```bash
# Test with 1 user
curl -X POST \
  https://us-central1-naijasingles-74a75.cloudfunctions.net/createTestUsers \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_SECRET" \
  -d '{"count": 1}'

# Should return:
# {
#   "success": true,
#   "created": 1,
#   "failed": 0,
#   "userIds": ["..."],
#   "message": "Successfully created 1 test users"
# }
```

## Summary

- ✅ Secret is configured and active
- ✅ Stored in Firebase Functions config
- ✅ Backed up in `.env.local` (local development)
- ✅ Helper script automatically uses it
- ✅ Function is secured and requires authentication

Your function is now properly secured! 🔒
