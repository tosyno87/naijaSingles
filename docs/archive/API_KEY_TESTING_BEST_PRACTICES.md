# App Store Connect API Key Testing Best Practices

## 🎯 **Why Test API Keys Locally?**

Testing API keys locally before CI/CD deployment is a **critical best practice** because:

1. **Early Detection**: Catch authentication issues before they block CI/CD
2. **Faster Debugging**: Local testing is much faster than CI/CD cycles
3. **Cost Efficiency**: Avoid wasting CI/CD minutes on authentication failures
4. **Developer Confidence**: Know your credentials work before pushing

## 🧪 **Testing Methods (Ranked by Best Practice)**

### 1. **xcrun altool --list-apps** ⭐⭐⭐⭐⭐ (BEST)
```bash
xcrun altool --list-apps \
  --apiKey "$APPSTORE_API_KEY_ID" \
  --apiIssuer "$APPSTORE_API_ISSUER_ID" \
  --verbose
```

**Why this is best:**
- ✅ Tests authentication without uploading anything
- ✅ Shows exactly what apps the key has access to
- ✅ Fast and lightweight
- ✅ Same authentication mechanism as uploads

### 2. **Test with a small IPA upload** ⭐⭐⭐⭐ (GOOD)
```bash
xcrun altool --upload-app \
  --type ios \
  --file "test.ipa" \
  --apiKey "$APPSTORE_API_KEY_ID" \
  --apiIssuer "$APPSTORE_API_ISSUER_ID" \
  --bundle-id "com.app.naijasingles" \
  --apple-id "bbtnd_tosin@yahoo.com" \
  --bundle-version "1.0.0" \
  --bundle-short-version-string "1.0.0" \
  --verbose
```

**Why this is good:**
- ✅ Tests the complete upload flow
- ✅ Validates all parameters
- ⚠️ Requires an actual IPA file
- ⚠️ Creates a build in App Store Connect

### 3. **Test with curl/HTTP requests** ⭐⭐⭐ (OKAY)
```bash
curl -X GET \
  "https://api.appstoreconnect.apple.com/v1/apps" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json"
```

**Why this is okay:**
- ✅ Direct API testing
- ⚠️ Requires JWT token generation
- ⚠️ More complex setup

## 🛠️ **Complete Testing Workflow**

### Step 1: Environment Setup
```bash
# Set your API credentials
export APPSTORE_API_KEY_ID="5LNR4FKU7U"
export APPSTORE_API_ISSUER_ID="5b6da02b-8d81-4edf-be91-49e218d3d4ba"
export APPSTORE_API_PRIVATE_KEY="$(cat path/to/AuthKey_5LNR4FKU7U.p8)"
```

### Step 2: Run the Test Script
```bash
./test_appstore_connection.sh
```

### Step 3: Interpret Results
- ✅ **Success**: API key works, proceed with CI/CD
- ❌ **Failure**: Fix authentication issues first

## 🔍 **Common Issues & Solutions**

### Issue 1: "Unable to authenticate. (-19209)"
**Causes:**
- Wrong Key ID or Issuer ID
- Incorrect .p8 file format
- API key doesn't have proper permissions

**Solutions:**
1. Verify Key ID and Issuer ID in App Store Connect
2. Check .p8 file starts with `-----BEGIN PRIVATE KEY-----`
3. Ensure API key has "Admin" or "App Manager" role

### Issue 2: "No apps found"
**Causes:**
- API key doesn't have access to any apps
- App doesn't exist in App Store Connect yet

**Solutions:**
1. Check API key permissions in App Store Connect
2. Verify the app exists and you have access
3. Create the app in App Store Connect if needed

### Issue 3: "App not accessible"
**Causes:**
- API key doesn't have access to specific app
- Wrong bundle ID or Apple ID

**Solutions:**
1. Verify bundle ID matches exactly
2. Check Apple ID is correct (email format)
3. Ensure API key has access to the specific app

## 📋 **Pre-Deployment Checklist**

Before every CI/CD deployment:

- [ ] Test API key locally with `./test_appstore_connection.sh`
- [ ] Verify the app exists in App Store Connect
- [ ] Check bundle ID and Apple ID are correct
- [ ] Ensure API key hasn't expired
- [ ] Verify GitHub secrets are up to date

## 🚀 **Integration with CI/CD**

### Add to CI/CD Pipeline (Optional)
```yaml
- name: Test API Key Authentication
  env:
    APPSTORE_API_KEY_ID: ${{ secrets.APPSTORE_API_KEY_ID }}
    APPSTORE_API_ISSUER_ID: ${{ secrets.APPSTORE_API_ISSUER_ID }}
    APPSTORE_API_PRIVATE_KEY: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
  run: |
    mkdir -p ~/.appstoreconnect/private_keys
    printf "%s\n" "$APPSTORE_API_PRIVATE_KEY" > ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8
    chmod 600 ~/.appstoreconnect/private_keys/AuthKey_$APPSTORE_API_KEY_ID.p8
    
    # Test authentication
    xcrun altool --list-apps \
      --apiKey "$APPSTORE_API_KEY_ID" \
      --apiIssuer "$APPSTORE_API_ISSUER_ID" \
      --verbose
```

## 🎓 **Key Takeaways**

1. **Always test locally first** - It's faster and cheaper than CI/CD failures
2. **Use `--list-apps` for basic testing** - No side effects, just authentication
3. **Test after every secret update** - Ensure changes work before deployment
4. **Keep test scripts in your repo** - Makes testing repeatable and shareable
5. **Document your testing process** - Helps team members debug issues

## 🔧 **Quick Commands**

```bash
# Test current GitHub secrets
gh secret get APPSTORE_API_KEY_ID | xargs -I {} bash -c '
  export APPSTORE_API_KEY_ID={} &&
  gh secret get APPSTORE_API_ISSUER_ID | xargs -I {} bash -c "
    export APPSTORE_API_ISSUER_ID={} &&
    gh secret get APPSTORE_API_PRIVATE_KEY | xargs -I {} bash -c \"
      export APPSTORE_API_PRIVATE_KEY=\\\"{}\\\" &&
      ./test_appstore_connection.sh
    \"
  "
'

# Test with manual values
export APPSTORE_API_KEY_ID="your-key-id"
export APPSTORE_API_ISSUER_ID="your-issuer-id"
export APPSTORE_API_PRIVATE_KEY="$(cat path/to/AuthKey.p8)"
./test_appstore_connection.sh
```

This approach follows DevOps best practices by testing early, testing often, and failing fast with clear error messages.

