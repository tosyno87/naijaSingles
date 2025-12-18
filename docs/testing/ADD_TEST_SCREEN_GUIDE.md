# How to Add Test Screen to Your App

## Quick Setup Guide

### Option 1: Add to Debug Menu (Recommended)

1. **Find your debug/development menu** in your app (usually accessible through a debug button or developer options)

2. **Add the test screen** to your debug menu:

```dart
// In your debug menu screen
import '../testing/test_new_features_screen.dart';

// Add this button to your debug menu
ListTile(
  leading: Icon(Icons.bug_report),
  title: Text('Test New Features'),
  subtitle: Text('Content Moderation & Profile Verification'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TestNewFeaturesScreen(),
      ),
    );
  },
),
```

### Option 2: Add to Settings Screen

1. **Find your settings screen** (usually in `lib/features/settings/`)

2. **Add a test section**:

```dart
// In your settings screen
import '../testing/test_new_features_screen.dart';

// Add this to your settings list
if (kDebugMode) { // Only show in debug mode
  ListTile(
    leading: Icon(Icons.science),
    title: Text('Test New Features'),
    subtitle: Text('Content Moderation & Profile Verification'),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TestNewFeaturesScreen(),
        ),
      );
    },
  ),
}
```

### Option 3: Add to Profile Screen (Temporary)

1. **Find your profile screen** (usually in `lib/features/profile/`)

2. **Add a temporary test button**:

```dart
// In your profile screen, add this button temporarily
if (kDebugMode) {
  ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TestNewFeaturesScreen(),
        ),
      );
    },
    child: Text('Test New Features'),
  ),
}
```

## What the Test Screen Does

The test screen provides:

### Content Moderation Testing:
- **Text Moderation**: Test inappropriate word detection
- **Profile Moderation**: Test profile content filtering
- **Report Content**: Test the reporting system
- **Get Reports**: View pending reports

### Profile Verification Testing:
- **Request Verification**: Test verification requests
- **Get Status**: Check verification status
- **Get Pending**: View pending verifications
- **Get History**: View verification history

## Testing Workflow

1. **Open the test screen** from your app
2. **Enter test text** in the text field (try "This is spam content")
3. **Click test buttons** to test different features
4. **View results** in the results section
5. **Check Firestore** to see data being saved

## Example Test Cases

### Test Content Moderation:
```
Text: "This is spam content"
Expected: Flagged for inappropriate word "spam"

Text: "Call me at 1234567890"
Expected: Flagged for phone number pattern

Text: "Email me at test@example.com"
Expected: Flagged for email pattern
```

### Test Profile Verification:
```
1. Select "email" verification type
2. Click "Request Verification"
3. Check "Get Status" to see status change
4. Check Firestore for verification document
```

## Firestore Collections to Monitor

### Content Moderation:
- `reports` - User reports
- `users` - User moderation flags

### Profile Verification:
- `profile_verifications` - Verification requests
- `users` - Verification status

## Troubleshooting

### If the test screen doesn't work:

1. **Check imports**: Make sure all imports are correct
2. **Check Firebase**: Ensure Firebase is properly configured
3. **Check authentication**: Make sure user is logged in
4. **Check Firestore rules**: Ensure read/write permissions

### Common errors:

1. **"Service not found"**: Check import paths
2. **"Permission denied"**: Check Firestore security rules
3. **"User not authenticated"**: Ensure user is logged in

## Removing the Test Screen

When you're done testing:

1. **Remove the test screen file**: `lib/features/testing/test_new_features_screen.dart`
2. **Remove the test button** from your app
3. **Clean up any test data** in Firestore if needed

## Next Steps

After testing:

1. **Integrate the services** into your actual app screens
2. **Add moderation checks** to profile creation
3. **Add verification badges** to user profiles
4. **Add report buttons** to profiles
5. **Set up admin screens** for reviewing reports and verifications
