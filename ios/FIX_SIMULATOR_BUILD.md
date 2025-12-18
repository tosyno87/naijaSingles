# 🔧 Fix: Force Simulator Build (Alternative Solution)

The build is targeting `iphoneos` (device) instead of `iphonesimulator`. 

## Try This First:
```bash
flutter run -d FFE96523-E7C0-4DA2-AF8E-F5D3652B3066 --debug --simulator
```

## If That Doesn't Work:
The issue is that Xcode project settings have `SDKROOT = iphoneos` which forces device builds.

### Option 1: Build directly with xcodebuild for simulator
```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=FFE96523-E7C0-4DA2-AF8E-F5D3652B3066' \
  build
```

### Option 2: In Xcode, manually set:
1. Product → Scheme → Edit Scheme
2. Select "Run" → "Info" tab
3. Build Configuration: **Debug**
4. Executable: **Runner.app**
5. Build for: **Any iOS Simulator**

Then try building from Xcode first, then Flutter CLI should pick up the right settings.

