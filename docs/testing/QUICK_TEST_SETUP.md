# Quick Test Setup for Moderation

## Add Quick Test to Your App

### Option 1: Add to Debug Menu (Recommended)

1. **Find your debug menu** (usually accessible through a debug button or developer options)

2. **Add this import**:
   ```dart
   import '../testing/quick_moderation_test.dart';
   ```

3. **Add this button** to your debug menu:
   ```dart
   ListTile(
     leading: Icon(Icons.bug_report, color: Colors.red),
     title: Text('Quick Moderation Test'),
     subtitle: Text('Test content moderation and verification'),
     onTap: () {
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (context) => const QuickModerationTest(),
         ),
       );
     },
   ),
   ```

### Option 2: Add to Settings Screen

1. **Find your settings screen**

2. **Add this import**:
   ```dart
   import '../testing/quick_moderation_test.dart';
   ```

3. **Add this button** (only in debug mode):
   ```dart
   if (kDebugMode) {
     ListTile(
       leading: Icon(Icons.science, color: Colors.red),
       title: Text('Quick Moderation Test'),
       subtitle: Text('Test moderation features'),
       onTap: () {
         Navigator.push(
           context,
           MaterialPageRoute(
             builder: (context) => const QuickModerationTest(),
           ),
         );
       },
     ),
   }
   ```

### Option 3: Add to Profile Screen (Temporary)

1. **Find your profile screen**

2. **Add this import**:
   ```dart
   import '../testing/quick_moderation_test.dart';
   ```

3. **Add this button** (temporarily):
   ```dart
   if (kDebugMode) {
     ElevatedButton(
       onPressed: () {
         Navigator.push(
           context,
           MaterialPageRoute(
             builder: (context) => const QuickModerationTest(),
           ),
         );
       },
       style: ElevatedButton.styleFrom(
         backgroundColor: Colors.red,
         foregroundColor: Colors.white,
       ),
       child: Text('Test Moderation'),
     ),
   }
   ```

## How to Use the Quick Test

1. **Open the test screen** from your app
2. **Enter test text** like:
   - `"This is spam content"`
   - `"Call me at 1234567890"`
   - `"Email me at test@example.com"`
3. **Click "Test Moderation"**
4. **Click "Test Verification"**
5. **View results** in the results section

## Expected Results

### Moderation Test Results:
```
MODERATION TEST RESULTS:
=======================
Text: "This is spam content"
Approved: false
Flagged: true
Error: false
Reason: Inappropriate content detected
Severity: medium
Details: Contains inappropriate word: spam

STATUS: ❌ BLOCKED
```

### Verification Test Results:
```
VERIFICATION TEST RESULTS:
=========================
Current Status: unverified
Badge: 
Status Text: Not Verified

EMAIL VERIFICATION:
Title: Email Verification
Description: Verify your email address
Requirements: [Valid email address]
Estimated Time: Instant

STATUS: ✅ VERIFICATION SERVICE WORKING
```

## What This Tests

### Content Moderation:
- ✅ Inappropriate word detection
- ✅ Suspicious pattern detection (phone, email, URL)
- ✅ Spam detection
- ✅ Short content detection
- ✅ Service integration

### Profile Verification:
- ✅ Service initialization
- ✅ Status checking
- ✅ Requirements retrieval
- ✅ Badge generation
- ✅ Service integration

## Troubleshooting

### If Test Doesn't Work:

1. **Check imports**:
   ```dart
   import '../../../services/content_moderation_service.dart';
   import '../../../services/profile_verification_service.dart';
   ```

2. **Check Firebase connection**:
   - Make sure Firebase is properly configured
   - Check if user is authenticated

3. **Check console logs**:
   - Look for error messages
   - Check if services are being called

### Common Errors:

1. **"Service not found"**:
   - Check import paths
   - Make sure services exist

2. **"Permission denied"**:
   - Check Firestore security rules
   - Ensure user is authenticated

3. **"Null check operator"**:
   - Check if user is logged in
   - Verify Firebase initialization

## After Testing

1. **If everything works**: The moderation is properly integrated
2. **If issues found**: Debug the specific problems
3. **Remove test screen**: Once testing is complete, remove the test button

## Next Steps

After confirming the quick test works:

1. **Test in actual app screens**:
   - Try creating profiles with inappropriate content
   - Try sending inappropriate messages
   - Try requesting verifications

2. **Check Firestore**:
   - Look for reports in `reports` collection
   - Look for verifications in `profile_verifications` collection

3. **Test user experience**:
   - Make sure error messages are user-friendly
   - Verify that blocked content doesn't save
   - Check that verification requests work

This quick test will help you verify that the moderation services are working correctly before testing the full integration!
