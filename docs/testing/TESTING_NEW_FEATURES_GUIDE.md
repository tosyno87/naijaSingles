# Testing New Features Guide

## Overview
This guide explains how to test the new Content Moderation and Profile Verification services that were added to the AfroPeep app.

## New Features Added

### 1. Content Moderation Service
- Text content filtering
- Profile moderation
- Reporting system
- Admin moderation actions

### 2. Profile Verification Service
- Multiple verification types (email, phone, photo, identity, employment)
- Verification request management
- Admin review system
- Verification status tracking

## Testing Content Moderation Service

### Prerequisites
1. Make sure you have Firebase Firestore set up
2. Ensure you have admin access to Firestore console
3. Have test user accounts ready

### Test Cases

#### 1. Text Content Filtering

**Test Inappropriate Words:**
```dart
// Add this to any screen for testing
import 'package:naijasingles/services/content_moderation_service.dart';

// Test inappropriate content
final moderationService = ContentModerationService();
final result = await moderationService.moderateText("This is spam content");
print('Moderation Result: ${result.isApproved}'); // Should be false
print('Reason: ${result.reason}'); // Should show "Inappropriate content detected"
```

**Test Suspicious Patterns:**
```dart
// Test phone number detection
final result = await moderationService.moderateText("Call me at 1234567890");
print('Flagged: ${result.isFlagged}'); // Should be true

// Test email detection
final result2 = await moderationService.moderateText("Email me at test@example.com");
print('Flagged: ${result2.isFlagged}'); // Should be true
```

#### 2. Profile Moderation

**Test Profile Data:**
```dart
final profileData = {
  'bio': 'This is a spam profile',
  'name': 'Test User',
  'age': 25,
  'location': 'Lagos'
};

final result = await moderationService.moderateProfile(profileData);
print('Profile Approved: ${result.isApproved}');
```

#### 3. Reporting System

**Test Content Reporting:**
```dart
final success = await moderationService.reportContent(
  contentType: 'profile',
  contentId: 'user123',
  reporterId: 'reporter456',
  reason: 'Inappropriate content',
  details: 'User posted spam content'
);
print('Report submitted: $success'); // Should be true
```

**View Reports in Firestore:**
1. Go to Firebase Console → Firestore
2. Navigate to `reports` collection
3. Check for new report documents

#### 4. Admin Moderation Actions

**Test Getting Pending Reports:**
```dart
final reports = await moderationService.getPendingReports();
print('Pending reports: ${reports.length}');
```

**Test Reviewing Reports:**
```dart
final success = await moderationService.reviewReport(
  reportId: 'report123',
  reviewerId: 'admin456',
  action: ModerationAction.warn,
  notes: 'First warning for spam content'
);
print('Review completed: $success');
```

## Testing Profile Verification Service

### Prerequisites
1. Firebase Firestore set up
2. Test user accounts
3. Admin access to Firestore console

### Test Cases

#### 1. Request Verification

**Test Email Verification:**
```dart
import 'package:naijasingles/services/profile_verification_service.dart';

final verificationService = ProfileVerificationService();

final success = await verificationService.requestVerification(
  userId: 'user123',
  type: VerificationType.email,
  verificationData: {
    'email': 'test@example.com',
    'verificationCode': '123456'
  }
);
print('Email verification requested: $success');
```

**Test Photo Verification:**
```dart
final success = await verificationService.requestVerification(
  userId: 'user123',
  type: VerificationType.photo,
  verificationData: {
    'photos': ['photo1.jpg', 'photo2.jpg'],
    'selfie': 'selfie.jpg',
    'notes': 'Clear photos with face visible'
  }
);
print('Photo verification requested: $success');
```

#### 2. Check Verification Status

**Get User Verification Status:**
```dart
final status = await verificationService.getUserVerificationStatus('user123');
print('Verification Status: ${status.name}'); // unverified, pending, verified, rejected
```

**Check Verification Eligibility:**
```dart
final canRequest = await verificationService.canRequestVerification(
  'user123', 
  VerificationType.photo
);
print('Can request photo verification: $canRequest');
```

#### 3. Admin Review Process

**Get Pending Verifications:**
```dart
final verifications = await verificationService.getPendingVerifications();
print('Pending verifications: ${verifications.length}');
```

**Review Verification:**
```dart
final success = await verificationService.reviewVerification(
  verificationId: 'verification123',
  reviewerId: 'admin456',
  newStatus: VerificationStatus.verified,
  notes: 'Photos are clear and match profile'
);
print('Verification reviewed: $success');
```

#### 4. Verification History

**Get User Verification History:**
```dart
final history = await verificationService.getUserVerificationHistory('user123');
print('Verification history: ${history.length} entries');
for (final verification in history) {
  print('Type: ${verification.type.name}, Status: ${verification.status.name}');
}
```

## Integration Testing

### 1. Add to Profile Creation Screen

**Integrate Content Moderation:**
```dart
// In profile creation screen
final moderationService = ContentModerationService();

// Before saving profile
final bioResult = await moderationService.moderateText(bioText);
if (!bioResult.isApproved) {
  // Show error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Bio contains inappropriate content: ${bioResult.reason}'))
  );
  return;
}

// Continue with profile creation
```

### 2. Add Verification Badges to Profile

**Show Verification Status:**
```dart
// In profile screen
final verificationService = ProfileVerificationService();

Widget buildVerificationBadge(String userId) {
  return FutureBuilder<VerificationStatus>(
    future: verificationService.getUserVerificationStatus(userId),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final status = snapshot.data!;
        final badge = verificationService.getVerificationBadge(status);
        final text = verificationService.getVerificationStatusText(status);
        
        return Row(
          children: [
            Text(badge),
            Text(text),
          ],
        );
      }
      return CircularProgressIndicator();
    },
  );
}
```

### 3. Add Report Button to Profile

**Add Reporting Functionality:**
```dart
// In profile screen
IconButton(
  icon: Icon(Icons.flag),
  onPressed: () async {
    final success = await ContentModerationService().reportContent(
      contentType: 'profile',
      contentId: userId,
      reporterId: currentUserId,
      reason: 'Inappropriate content',
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report submitted successfully'))
      );
    }
  },
)
```

## Manual Testing Steps

### Content Moderation Testing

1. **Create Test Content:**
   - Create profiles with inappropriate words
   - Create profiles with suspicious patterns (phone numbers, emails)
   - Create profiles with spam-like content

2. **Test Reporting:**
   - Report inappropriate profiles
   - Check reports appear in Firestore
   - Test admin review process

3. **Test Moderation Actions:**
   - Review reports as admin
   - Test different moderation actions (warn, suspend, ban)
   - Verify actions are applied to users

### Profile Verification Testing

1. **Request Verifications:**
   - Request different types of verifications
   - Test with incomplete profiles
   - Test duplicate requests

2. **Admin Review:**
   - Review verification requests
   - Approve/reject verifications
   - Test verification status updates

3. **UI Integration:**
   - Add verification badges to profiles
   - Show verification status in user lists
   - Add verification request buttons

## Firestore Collections Created

### Content Moderation Collections:
- `reports` - User reports of inappropriate content
- `users` - Updated with moderation flags (warnings, suspensions, bans)

### Profile Verification Collections:
- `profile_verifications` - Verification requests and history
- `users` - Updated with verification status

## Testing Checklist

### Content Moderation ✅
- [ ] Test inappropriate word detection
- [ ] Test suspicious pattern detection
- [ ] Test profile moderation
- [ ] Test reporting system
- [ ] Test admin review process
- [ ] Test moderation actions (warn, suspend, ban)
- [ ] Test content removal

### Profile Verification ✅
- [ ] Test verification request creation
- [ ] Test verification eligibility checks
- [ ] Test admin review process
- [ ] Test verification status updates
- [ ] Test verification history
- [ ] Test verification badges
- [ ] Test different verification types

### Integration ✅
- [ ] Integrate content moderation into profile creation
- [ ] Add verification badges to profiles
- [ ] Add report buttons to profiles
- [ ] Test end-to-end user flows

## Troubleshooting

### Common Issues:

1. **Firestore Permission Errors:**
   - Check Firestore security rules
   - Ensure proper authentication

2. **Service Not Found:**
   - Make sure services are imported correctly
   - Check file paths

3. **Data Not Saving:**
   - Check Firestore connection
   - Verify user authentication
   - Check for validation errors

### Debug Tips:

1. **Enable Debug Logging:**
   ```dart
   import 'dart:developer';
   log('Debug message', name: 'ContentModeration');
   ```

2. **Check Firestore Console:**
   - Monitor collections in real-time
   - Check for error messages

3. **Test with Console Logs:**
   ```dart
   print('Testing moderation: $result');
   ```

## Next Steps

1. **Run Unit Tests:**
   - Create unit tests for the services
   - Test edge cases and error conditions

2. **Integration Testing:**
   - Test with real user data
   - Test with different user roles

3. **Performance Testing:**
   - Test with large datasets
   - Monitor Firestore usage

4. **User Acceptance Testing:**
   - Test with real users
   - Gather feedback on new features
