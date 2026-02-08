# Fixing iOS Code Signing for Simulator

## Quick Fix

If you see this error when running `./scripts/test_ios.sh`:
```
Failed to build iOS app
Uncategorized (Xcode): Command CodeSign failed with a nonzero exit code
```

## Solution

1. **Open Xcode Workspace:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   
2. **Configure Signing:**
   - In Xcode, select the **Runner** project in the left sidebar
   - Select the **Runner** target
   - Go to **Signing & Capabilities** tab
   - ✅ Enable **"Automatically manage signing"**
   - Select your **Team**: `M7HY7333KT` (or your Apple Developer team)
   - Xcode will automatically generate provisioning profiles

3. **Verify Settings:**
   - Bundle Identifier: `com.app.naijasingles`
   - Development Team: `M7HY7333KT`
   - Code Signing Style: `Automatic`

4. **Try Again:**
   ```bash
   ./scripts/test_ios.sh
   ```

## Alternative: Manual Build (if above doesn't work)

```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Plus' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

## Why This Happens

iOS Simulator builds don't require full code signing, but Xcode still needs the signing configuration validated at least once. After opening Xcode and configuring automatic signing, the simulator builds will work without issues.

## Note

This only needs to be done once. After Xcode is configured, you can use `./scripts/test_ios.sh` normally.

