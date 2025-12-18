# Testing Moderation Integration

## Overview
This guide helps you test the content moderation and profile verification features that have been integrated into the AfroPeep app.

## What Was Integrated

### 1. Profile Creation Moderation
- **Location**: `lib/features/profile/edit_profile_screen.dart`
- **What it does**: Checks bio and name for inappropriate content before saving
- **Triggers**: When user tries to save profile with inappropriate text

### 2. Profile Screen Verification
- **Location**: `lib/features/profile/profile_screen.dart`
- **What it does**: Shows verification badges and allows verification requests
- **Features**: Verification status display, verification request buttons

### 3. Chat Message Moderation
- **Location**: `lib/features/chat/ui/widgets/send_message_box.dart`
- **What it does**: Checks messages for inappropriate content before sending
- **Triggers**: When user tries to send a message

## Testing Steps

### Step 1: Test Profile Creation Moderation

1. **Open the app** and go to Edit Profile screen
2. **Try inappropriate content** in the bio field:
   - Enter: `"This is spam content"`
   - Enter: `"Call me at 1234567890"`
   - Enter: `"Email me at test@example.com"`
3. **Try inappropriate name**:
   - Enter: `"Spam User"`
4. **Click Save** and observe:
   - Should show moderation error dialog
   - Profile should NOT be saved
   - Should see error message explaining why content was blocked

**Expected Results:**
```
Content Not Allowed
Your content contains inappropriate material.
Details: Contains inappropriate word: spam
```

### Step 2: Test Chat Message Moderation

1. **Open a chat** with another user
2. **Try sending inappropriate messages**:
   - `"This is spam content"`
   - `"Call me at 1234567890"`
   - `"Email me at test@example.com"`
3. **Observe**:
   - Should show moderation error dialog
   - Message should NOT be sent
   - Should see error message

**Expected Results:**
```
Message Blocked
Your message contains inappropriate content.
Details: Contains inappropriate word: spam
```

### Step 3: Test Profile Verification

1. **Go to Profile screen**
2. **Look for verification section** (should be new)
3. **Check verification badge** next to your name
4. **Try verification buttons**:
   - Click on different verification types
   - Should see success/error messages
5. **Check Firestore** for verification documents

**Expected Results:**
- Verification section should appear
- Badge should show current status
- Buttons should be clickable
- Success message: "Verification requested successfully"

### Step 4: Test Report Functionality

1. **Go to Profile screen**
2. **Click "Report Profile" button** (should be new)
3. **Confirm the report**
4. **Check Firestore** `reports` collection for new report

**Expected Results:**
- Report button should be visible
- Should show confirmation dialog
- Success message: "Report submitted successfully"
- Report should appear in Firestore

## Debugging Tips

### If Moderation Doesn't Work:

1. **Check Console Logs**:
   ```dart
   // Look for these logs in your debug console
   print('Content flagged for inappropriate word: spam');
   print('Moderation Result: ${result.isApproved}');
   ```

2. **Check Firestore Collections**:
   - `reports` - Should have new reports
   - `profile_verifications` - Should have verification requests
   - `users` - Should have updated verification status

3. **Check Import Statements**:
   ```dart
   // Make sure these imports are present
   import '../../../services/content_moderation_service.dart';
   import '../../../services/profile_verification_service.dart';
   ```

### Common Issues:

1. **"Service not found"**:
   - Check import paths
   - Make sure services are in correct location

2. **"Permission denied"**:
   - Check Firestore security rules
   - Ensure user is authenticated

3. **Moderation not triggering**:
   - Check if moderation service is being called
   - Verify text input is reaching the moderation function

## Test Cases to Try

### Content Moderation Test Cases:

1. **Inappropriate Words**:
   - `"This is spam content"` → Should be blocked
   - `"This is fake content"` → Should be blocked
   - `"This is bot content"` → Should be blocked

2. **Suspicious Patterns**:
   - `"Call me at 1234567890"` → Should be blocked (phone number)
   - `"Email me at test@example.com"` → Should be blocked (email)
   - `"Visit https://example.com"` → Should be blocked (URL)

3. **Spam Detection**:
   - `"Buy now buy now buy now buy now"` → Should be blocked (repetition)

4. **Short Content**:
   - `"Hi"` → Should be blocked (too short)

### Profile Verification Test Cases:

1. **Request Email Verification**:
   - Should create verification request
   - Should update user status

2. **Request Photo Verification**:
   - Should create verification request
   - Should show success message

3. **Check Verification Status**:
   - Should show current status
   - Should display appropriate badge

## Expected Firestore Data

### After Testing, Check These Collections:

1. **`reports` Collection**:
   ```json
   {
     "contentType": "profile",
     "contentId": "user123",
     "reporterId": "reporter456",
     "reason": "Inappropriate content",
     "status": "pending",
     "reportedAt": "timestamp"
   }
   ```

2. **`profile_verifications` Collection**:
   ```json
   {
     "userId": "user123",
     "type": "email",
     "status": "pending",
     "verificationData": {...},
     "requestedAt": "timestamp"
   }
   ```

3. **`users` Collection**:
   ```json
   {
     "verificationStatus": "pending",
     "verificationRequestedAt": "timestamp"
   }
   ```

## Manual Testing Checklist

### Profile Creation Moderation ✅
- [ ] Test inappropriate bio text
- [ ] Test inappropriate name
- [ ] Test suspicious patterns (phone, email, URL)
- [ ] Test spam-like content
- [ ] Test short content
- [ ] Verify error dialogs appear
- [ ] Verify profile is not saved when blocked

### Chat Message Moderation ✅
- [ ] Test inappropriate message text
- [ ] Test suspicious patterns
- [ ] Test spam-like content
- [ ] Verify error dialogs appear
- [ ] Verify message is not sent when blocked

### Profile Verification ✅
- [ ] Check verification section appears
- [ ] Check verification badge displays
- [ ] Test verification request buttons
- [ ] Verify success messages
- [ ] Check Firestore for verification documents

### Report Functionality ✅
- [ ] Check report button appears
- [ ] Test report dialog
- [ ] Verify success messages
- [ ] Check Firestore for report documents

## Next Steps After Testing

1. **If everything works**: Commit the changes
2. **If issues found**: Debug and fix them
3. **If moderation is too strict**: Adjust the word list
4. **If moderation is too lenient**: Add more patterns

## Quick Test Commands

You can also test using the test screen we created earlier:

1. **Add test screen to your app** (see `ADD_TEST_SCREEN_GUIDE.md`)
2. **Open test screen**
3. **Run all test cases**
4. **Check results**

This will give you a comprehensive test of all the moderation features!
