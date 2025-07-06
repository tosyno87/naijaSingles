# Security Rules Testing Guide

## 🧪 **Critical Tests to Perform**

### Test 1: Match Verification for Chat Creation
**Expected Behavior**: Only matched users can create chat threads

#### Test Cases:
1. **✅ SHOULD WORK**: Matched users creating chat
   - User A and User B are matched
   - User A tries to create chat with User B
   - **Expected**: Chat creation succeeds

2. **❌ SHOULD FAIL**: Non-matched users creating chat
   - User A and User C are NOT matched
   - User A tries to create chat with User C
   - **Expected**: Permission denied error

#### How to Test:
```dart
// In your app, try creating a chat with someone you haven't matched
// This should now fail with permission denied
```

### Test 2: Block List Enforcement
**Expected Behavior**: Blocked users cannot send messages or create chats

#### Test Cases:
1. **❌ SHOULD FAIL**: Blocked user sending message
   - User A blocks User B
   - User B tries to send message to User A
   - **Expected**: Permission denied error

2. **❌ SHOULD FAIL**: Creating chat with blocked user
   - User A blocks User B
   - User A tries to create chat with User B
   - **Expected**: Permission denied error

### Test 3: Message Content Validation
**Expected Behavior**: Messages must meet validation criteria

#### Test Cases:
1. **❌ SHOULD FAIL**: Empty message
   - User tries to send empty message
   - **Expected**: Permission denied error

2. **❌ SHOULD FAIL**: Message too long
   - User tries to send message > 1000 characters
   - **Expected**: Permission denied error

3. **✅ SHOULD WORK**: Valid message
   - User sends message 1-1000 characters
   - **Expected**: Message sent successfully

### Test 4: Profile Update Protection
**Expected Behavior**: Users cannot modify critical fields

#### Test Cases:
1. **❌ SHOULD FAIL**: Changing email
   - User tries to update their email field
   - **Expected**: Permission denied error

2. **❌ SHOULD FAIL**: Changing createdAt
   - User tries to update their createdAt field
   - **Expected**: Permission denied error

3. **✅ SHOULD WORK**: Updating allowed fields
   - User updates name, bio, photos, etc.
   - **Expected**: Update succeeds

## 🔍 **How to Monitor**

### 1. Firebase Console Monitoring
- Go to Firebase Console > Firestore > Usage tab
- Monitor for permission denied errors
- Check error patterns and frequency

### 2. App Error Handling
```dart
// Add error handling in your chat service
try {
  await _chatService.createChatThread(otherUserId, otherUserName);
} catch (e) {
  if (e.toString().contains('permission-denied')) {
    // Handle permission denied - likely not matched or blocked
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cannot Start Chat'),
        content: Text('You can only chat with users you\'ve matched with.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### 3. Debug Logging
```dart
// Add logging to track rule enforcement
print('Attempting to create chat with user: $otherUserId');
print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');
```

## 📊 **Success Metrics**

After deployment, you should see:

### Immediate Indicators (First 24 hours)
- [ ] No permission denied errors for legitimate matched users
- [ ] Permission denied errors for non-matched users trying to chat
- [ ] Blocked users cannot send messages
- [ ] Message validation working (no empty/oversized messages)

### Long-term Indicators (First week)
- [ ] Reduced spam/harassment reports
- [ ] Improved user safety feedback
- [ ] No legitimate user complaints about chat functionality
- [ ] Stable app performance

## 🚨 **Troubleshooting Common Issues**

### Issue 1: Existing Chats Stop Working
**Cause**: Existing chat threads may not have proper match verification
**Solution**: 
```javascript
// Temporary compatibility rule (add if needed)
allow read: if request.auth != null &&
             request.auth.uid in resource.data.userIds &&
             (areUsersMatched(resource.data.userIds[0], resource.data.userIds[1]) ||
              resource.createTime < timestamp.date(2025, 7, 4)); // Before rule update
```

### Issue 2: Match Documents Not Found
**Cause**: Match document structure doesn't match helper function
**Solution**: Check your match document structure and update helper function:
```javascript
// Adjust based on your actual match document structure
function areUsersMatched(userId1, userId2) {
  // Check your actual match collection structure
  return exists(/databases/$(database)/documents/matches/$(userId1 + '_' + userId2)) ||
         exists(/databases/$(database)/documents/matches/$(userId2 + '_' + userId1));
}
```

### Issue 3: Performance Issues
**Cause**: Complex rule evaluation
**Solution**: Monitor rule evaluation time and simplify if needed

## 🔄 **Rollback Plan**

If critical issues occur:

### Immediate Rollback
```bash
# Use the backup we created
firebase deploy --only firestore:rules firestore_rules_backup_20250704_165340.txt
```

### Gradual Fix
1. Identify specific rule causing issues
2. Create minimal fix
3. Test locally
4. Deploy incremental update

## 📱 **User Communication**

If users experience issues:

### Error Messages to Show Users
```dart
// For non-matched users trying to chat
"You can only send messages to users you've matched with. Keep swiping to find more matches!"

// For blocked users
"This conversation is no longer available."

// For message validation errors
"Message is too long. Please keep messages under 1000 characters."
```

### Support Documentation
- Update your app's help section
- Add FAQ about chat restrictions
- Explain matching requirement for messaging

## ✅ **Deployment Checklist**

- [x] Rules deployed successfully
- [ ] Monitor error rates for 24 hours
- [ ] Test chat creation between matched users
- [ ] Test chat creation between non-matched users (should fail)
- [ ] Test message sending with blocked users (should fail)
- [ ] Test message validation (empty/long messages should fail)
- [ ] Monitor user feedback and support tickets
- [ ] Document any issues and solutions

The enhanced security rules are now active and protecting your users! 🛡️
