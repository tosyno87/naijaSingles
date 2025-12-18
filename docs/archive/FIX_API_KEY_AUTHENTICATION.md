# Fix App Store Connect API Key Authentication (401 Unauthorized)

## 🔍 Problem Summary

The API key file format is **correct** (verified in CI logs), but we're getting a **401 Unauthorized** error. This means the API key itself has an issue with:

1. **Permissions** - Key doesn't have the right role
2. **Expiration** - Key has expired
3. **Team Mismatch** - Key is for a different Apple Developer team

## ✅ Step-by-Step Fix

### Step 1: Verify/Create a New API Key in App Store Connect

1. **Go to App Store Connect**: https://appstoreconnect.apple.com
2. **Navigate to**: Users and Access → Integrations → App Store Connect API → Keys
3. **Check your existing key** or **Create a new key**:
   - Click **"Generate API Key"** or **"+"**
   - Name: `GitHub CI/CD` (or any name you prefer)
   - **Access**: Select **"Admin"** or **"App Manager"** role
   - Click **Generate**

4. **Important**: 
   - Note down the **Key ID** (e.g., `ABC123XYZ`)
   - Note down the **Issuer ID** (shown at the top of the Keys page)
   - **Download the `.p8` file** immediately (you can only download it once!)

### Step 2: Update GitHub Secrets

Run these commands from your terminal:

```bash
# 1. Set the Key ID
gh secret set APPSTORE_API_KEY_ID

# 2. Set the Issuer ID
gh secret set APPSTORE_API_ISSUER_ID

# 3. Set the Private Key from the downloaded .p8 file
# Replace the path with your actual .p8 file path
cat ~/Downloads/AuthKey_XXXXXXXXXX.p8 | gh secret set APPSTORE_API_PRIVATE_KEY
```

**Alternative** (if you prefer the GitHub web interface):
1. Go to: https://github.com/tosyno87/naijaSingles/settings/secrets/actions
2. Update each secret:
   - `APPSTORE_API_KEY_ID` = Your Key ID
   - `APPSTORE_API_ISSUER_ID` = Your Issuer ID  
   - `APPSTORE_API_PRIVATE_KEY` = Paste the entire contents of the `.p8` file

### Step 3: Verify the .p8 File Format

The `.p8` file should look **exactly** like this:

```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXoAoGCCqGSM49AwEHoUQDQgAEXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
-----END PRIVATE KEY-----
```

**Critical**: 
- Must start with `-----BEGIN PRIVATE KEY-----`
- Must end with `-----END PRIVATE KEY-----`
- Usually 5-6 lines total
- No extra spaces, no quotes, no JSON escaping

### Step 4: Test Locally (Optional but Recommended)

```bash
# Set environment variables with your actual values
export APPSTORE_API_KEY_ID="your-key-id"
export APPSTORE_API_ISSUER_ID="your-issuer-id"
export APPSTORE_API_PRIVATE_KEY="$(cat path/to/AuthKey_XXXXXXXXXX.p8)"

# Run the test script
./test_api_key.sh
```

If this succeeds locally, it will work in CI.

### Step 5: Trigger a New Deployment

```bash
# Make a small change and push
git commit --allow-empty -m "test: verify API key authentication"
git push origin release/1.0.0
```

## 🎯 Common Issues and Solutions

### Issue 1: "Access" role is insufficient
**Solution**: Make sure your API key has **"Admin"** or **"App Manager"** role, not just "Developer" or "Finance".

### Issue 2: Wrong team/account
**Solution**: Make sure you're logged into the correct Apple Developer account when creating the key. The key must be for team ID: `M7HY7333KT`.

### Issue 3: Key expired
**Solution**: API keys can expire. Generate a new one if needed.

### Issue 4: Multiple .p8 files confusion
**Solution**: Make sure you're using the `.p8` file that corresponds to your `APPSTORE_API_KEY_ID`.

## 📋 Verification Checklist

- [ ] API key has "Admin" or "App Manager" role
- [ ] Key ID matches the downloaded .p8 file name
- [ ] Issuer ID is from the same Keys page
- [ ] .p8 file starts with `-----BEGIN PRIVATE KEY-----`
- [ ] .p8 file ends with `-----END PRIVATE KEY-----`
- [ ] All three GitHub secrets are updated
- [ ] Test script passes locally (optional)

## 🚀 Expected Result

After fixing the API key, you should see in the CI logs:

```
✅ File starts correctly
✅ File ends correctly
✅ AuthKey file format verified
📱 Found IPA file: ./ios/Runner.ipa
🚀 Starting upload to App Store Connect...
...
✅ Upload successful!
```

## 📞 Need Help?

If you're still getting 401 errors after following these steps:

1. Double-check the API key role in App Store Connect
2. Verify you're using the correct Apple Developer account
3. Try generating a completely new API key
4. Check that your Apple Developer Program membership is active


