# Setting Up UI Tests for Screenshot Automation

## 📱 Manual Steps Required in Xcode:

### 1. Add UI Test Target
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner project in the navigator
3. Click the "+" button at the bottom of the targets list
4. Choose "UI Testing Bundle"
5. Name it "RunnerUITests"
6. Make sure "Runner" is selected as the target to be tested

### 2. Add Files to UI Test Target
1. Right-click on the RunnerUITests folder
2. Choose "Add Files to RunnerUITests"
3. Add these files:
   - `RunnerUITests.swift`
   - `SnapshotHelper.swift`
   - `Info.plist`

### 3. Configure Scheme
1. Go to Product → Scheme → Edit Scheme
2. Select "RunnerUITests" scheme
3. Check the "Shared" box
4. Make sure the scheme is set to "Runner" target

### 4. Update Build Settings
1. Select RunnerUITests target
2. Go to Build Settings
3. Set "Product Bundle Identifier" to: `com.app.naijasingles.RunnerUITests`

## 🚀 After Setup, Run:

```bash
# Generate screenshots
fastlane ios screenshots

# Deploy with screenshots
fastlane ios deploy_with_screenshots
```

## 📸 Screenshots Will Capture:
- Welcome/Splash Screen
- Onboarding Flow
- Home Screen
- Communities Hub
- Connect/Explore
- Events
- Profile
- Groups
- Cultural Profile
- Settings
- Create Event Flow
- Create Group Flow

## ⚠️ Notes:
- Make sure your app is in a testable state
- UI tests will automatically navigate through your app
- Screenshots will be saved to `./fastlane/screenshots/`
- Each device will have its own folder

