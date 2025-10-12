# 🚀 How to Create Test Users in Firebase

## 📊 Current Status
- ❌ **No test users in Firebase yet**
- ✅ **Preview tools ready** - Can see what will be created
- ✅ **Service code ready** - Just needs to be connected
- ✅ **Documentation ready** - Full testing guide available

---

## 🎯 **3 Ways to Create Test Users**

### **Option 1: Quick Development Script (Easiest)**

Create a simple Dart script that connects to Firebase and generates users:

```bash
# 1. Create the script
cat > scripts/create_firebase_test_users.dart << 'EOF'
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../lib/services/test_data_generator_service.dart';

void main() async {
  print('🔥 Connecting to Firebase...');
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  print('✅ Connected to Firebase!');
  print('🚀 Generating test users...\n');
  
  // Generate test users
  await TestDataGeneratorService.generateAllTestUsers(
    usersPerCity: 20,
    dryRun: false,
  );
  
  print('\n🎉 Test users created successfully!');
  exit(0);
}
EOF

# 2. Run it
flutter run scripts/create_firebase_test_users.dart
```

---

### **Option 2: Add to Your Flutter App UI (Recommended for Production)**

Add a "Developer Tools" or "Admin" section to your profile screen:

#### **Step 1: Add Navigation**

In `lib/features/profile/profile_screen.dart`, add to the PopupMenuButton:

```dart
PopupMenuButton<String>(
  icon: Icon(Icons.more_vert, color: textPrimary),
  onSelected: (value) {
    switch (value) {
      case 'events':
        Navigator.pushNamed(context, RouteName.eventsScreen);
        break;
      // ... existing cases ...
      case 'test_data':  // ADD THIS
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestDataManagementScreen(),
          ),
        );
        break;
    }
  },
  itemBuilder: (context) => [
    // ... existing items ...
    if (kDebugMode)  // Only show in debug mode
      const PopupMenuItem(
        value: 'test_data',
        child: Row(
          children: [
            Icon(Icons.science, size: 20),
            SizedBox(width: 12),
            Text('Test Data'),
          ],
        ),
      ),
  ],
)
```

#### **Step 2: Import the Screen**

At the top of `profile_screen.dart`:

```dart
import 'package:flutter/foundation.dart';  // For kDebugMode
import '../admin/test_data_management_screen.dart';
```

#### **Step 3: Run Your App**

```bash
flutter run
```

Then:
1. Navigate to Profile tab
2. Tap the ⋮ menu
3. Select "Test Data"
4. Click "Generate All" to create 60 users

---

### **Option 3: Firebase Functions (Advanced)**

Create a Cloud Function that generates test users:

#### **Step 1: Create Function**

In `functions/src/index.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const generateTestUsers = functions.https.onCall(async (data, context) => {
  // Verify admin or development environment
  if (process.env.NODE_ENV === 'production') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Test users can only be created in development'
    );
  }
  
  const { count = 20, city = 'all' } = data;
  const usersCreated = [];
  
  // Generate users (implement based on TestDataGeneratorService logic)
  // ... your user generation code ...
  
  return { success: true, usersCreated: usersCreated.length };
});
```

#### **Step 2: Deploy Function**

```bash
firebase deploy --only functions
```

#### **Step 3: Call from App**

```dart
final callable = FirebaseFunctions.instance.httpsCallable('generateTestUsers');
final result = await callable.call({'count': 20, 'city': 'all'});
```

---

## 🏃 **Quick Start (Recommended Path)**

### **For Immediate Testing:**

**Step 1: Preview What Will Be Created**
```bash
dart scripts/generate_test_users.dart preview all 20
```

**Step 2: Add UI to Your App** (5 minutes)

Edit `lib/features/profile/profile_screen.dart`:

```dart
// Add import at top
import 'package:flutter/foundation.dart';
import '../admin/test_data_management_screen.dart';

// In PopupMenuButton's onSelected:
case 'test_data':
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const TestDataManagementScreen()),
  );
  break;

// In PopupMenuButton's itemBuilder:
if (kDebugMode)
  const PopupMenuItem(
    value: 'test_data',
    child: Row(
      children: [
        Icon(Icons.science, size: 20),
        SizedBox(width: 12),
        Text('Test Data Manager'),
      ],
    ),
  ),
```

**Step 3: Run App and Generate**
```bash
flutter run
```

1. Go to Profile → ⋮ Menu → Test Data Manager
2. Click "Generate All" (creates 60 users)
3. Wait ~5 minutes (Firebase rate limits apply)
4. Done! Test users are now in Firebase

---

## ⚠️ **Important Notes**

### **Firebase Authentication Limits:**
- Free tier: 50 sign-ups per second
- Creating 60 users will take **~2-5 minutes**
- Service includes built-in delays to respect rate limits

### **Test User Email Format:**
```
test_atlanta_male_1234@test.com
test_miami_female_5678@test.com
test_houston_male_9012@test.com
```

### **Test User Password:**
All test users use: `testpassword123`

### **Cleanup:**
When done testing:
```bash
# From app UI
Profile → Test Data Manager → Delete All Test Users

# Or programmatically
await TestDataGeneratorService.cleanupTestUsers();
```

---

## 🔍 **Verify Users Were Created**

### **In Firebase Console:**
1. Go to Firebase Console → Authentication
2. Look for emails starting with `test_`
3. Should see 60 users (30 male, 30 female)

### **In Firestore:**
1. Go to Firebase Console → Firestore
2. Open `users` collection
3. Filter: `isTestUser == true`
4. Should see 60 documents

### **In Your App:**
1. Log out of current account
2. Log in with: `test_atlanta_male_1234@test.com` / `testpassword123`
3. Should see complete profile with photos and interests

---

## 📊 **What Gets Created**

```
📍 Atlanta, GA (20 users)
   👨 10 males: ages 22-45, diverse interests
   👩 10 females: ages 22-45, diverse interests

📍 Miami, FL (20 users)
   👨 10 males: ages 22-45, diverse interests
   👩 10 females: ages 22-45, diverse interests

📍 Houston, TX (20 users)
   👨 10 males: ages 22-45, diverse interests
   👩 10 females: ages 22-45, diverse interests

Total: 60 realistic test users ready for testing
```

---

## 🎉 **You're All Set!**

Once you follow **Option 2** (add UI to app), you'll be able to:
- ✅ Generate test users with one click
- ✅ View statistics and distribution
- ✅ Clean up when done
- ✅ Test all dating features with realistic data

**Start with Option 2 - it's the fastest and most practical!** 🚀
