# Verify App Store Connect API Key Secret Format

## ⚠️ Critical: Check Your GitHub Secret

The API key authentication is failing with a 401 error. This is usually because the `APPSTORE_API_PRIVATE_KEY` secret has incorrect formatting.

## ✅ Correct Format

Your GitHub secret `APPSTORE_API_PRIVATE_KEY` should contain the **raw contents** of your `.p8` file, which looks like this:

```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
...more base64 encoded content...
...multiple lines...
...more base64 encoded content...
-----END PRIVATE KEY-----
```

## ❌ Common Mistakes

1. **Extra spaces or tabs** before or after lines
2. **Missing newline** at the end
3. **Windows line endings** (CRLF instead of LF)
4. **Quotes around the key**
5. **JSON escaped format** (with `\n` instead of actual newlines)

## 🔧 How to Fix

1. **Download your App Store Connect API Key** (.p8 file) from App Store Connect
2. **Open it in a text editor** (like VSCode, not Word)
3. **Copy the entire contents** exactly as is
4. **Update the GitHub secret**:
   ```bash
   # From your terminal, run:
   cat path/to/AuthKey_XXXXXXXXXX.p8 | gh secret set APPSTORE_API_PRIVATE_KEY
   ```

## 🧪 Test Locally

Before pushing changes, test the API key locally:

```bash
# Set environment variables
export APPSTORE_API_KEY_ID="your-key-id"
export APPSTORE_API_ISSUER_ID="your-issuer-id"
export APPSTORE_API_PRIVATE_KEY="$(cat path/to/AuthKey_XXXXXXXXXX.p8)"

# Run the test script
./test_api_key.sh
```

If the local test succeeds, the CI should work too.

## 📋 Checklist

- [ ] Verify the .p8 file exists and is readable
- [ ] Check the file starts with `-----BEGIN PRIVATE KEY-----`
- [ ] Check the file ends with `-----END PRIVATE KEY-----`
- [ ] Update GitHub secret with raw file contents
- [ ] Test locally with `test_api_key.sh`
- [ ] Push changes and check CI logs

## 🔍 Alternative: Check Secret in GitHub

Run this to verify the secret exists:
```bash
gh secret list
```

The secret should show as updated recently if you just set it.

