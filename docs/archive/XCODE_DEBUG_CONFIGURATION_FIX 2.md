# 🔧 Fix Debug Configuration in Xcode - Step by Step

## ⚠️ What You're Missing:

1. **You're viewing "Profile" configuration** - Need to switch to **"Debug"**
2. **You have physical device "Tosyno" selected** - Need to select a **Simulator**

## 📋 Step-by-Step Instructions:

### Step 1: Select Debug Configuration in Xcode

1. In Xcode, you're currently on the **"Signing & Capabilities"** tab ✅
2. **IMPORTANT**: Look at the filter buttons at the top: **"All"**, **"Debug"**, **"Release"**, **"Profile"**
3. **Click "Debug"** (you currently have "Profile" selected)
4. Verify these settings for **Debug**:
   - ✅ "Automatically manage signing" is **checked**
   - ✅ Team: **Adeola Babatunde** (or your team)
   - ✅ Bundle Identifier: `com.app.naijasingles`

### Step 2: Select iPhone Simulator (Not Physical Device)

1. Look at the top bar in Xcode - it shows **"Runner > Tosyno"**
2. **Click on "Tosyno"** (the device selector)
3. In the dropdown, scroll to **"iOS Simulators"** section
4. Select any iPhone Simulator (e.g., **"iPhone 16 Plus"** or **"iPhone 17"**)
5. The top bar should now show **"Runner > iPhone 16 Plus"** (or your chosen simulator)

### Step 3: Verify Debug Configuration

1. With **Debug** selected and a **Simulator** chosen:
2. Go back to **Signing & Capabilities** tab
3. Make sure **Debug** filter is still selected
4. Verify:
   - ✅ "Automatically manage signing" is checked
   - ✅ Team is selected
   - ✅ No errors shown

### Step 4: Test from Terminal

Now run the test script:
```bash
./scripts/test_ios.sh
```

Or directly:
```bash
flutter run -d FFE96523-E7C0-4DA2-AF8E-F5D3652B3066
```

## 🎯 Quick Visual Checklist:

- [ ] **Debug** configuration selected (not Profile)
- [ ] **iPhone Simulator** selected as device (not "Tosyno")
- [ ] "Automatically manage signing" checked for Debug
- [ ] Team selected for Debug
- [ ] No signing errors in Xcode

## 💡 Why This Matters:

- **Profile** configuration is for release builds (needs code signing)
- **Debug** configuration is for development (we disabled code signing for simulators)
- **Physical devices** require code signing
- **Simulators** don't need code signing (we configured it to skip)

Once you configure **Debug** with a **Simulator** selected, Flutter CLI should work! 🚀

