# Firestore Security Rules for Events Feature

## Current Issue
The Events feature is getting permission denied errors when trying to read/write to Firestore:
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Required Collections
The Events feature uses these Firestore collections:
- `events/` - Store event information
- `user_rsvps/` - Store user RSVP data
- `event_attendees/` - Store event attendee lists

## Security Rules to Add

Add these rules to your `firestore.rules` file in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Existing rules for users, matches, etc. should remain here...
    
    // Events collection - allow read for all authenticated users, write for authenticated users
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // User RSVPs - users can only read/write their own RSVPs
    match /user_rsvps/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to user's event RSVPs
      match /events/{eventId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Event attendees - allow read for all authenticated users, write for event management
    match /event_attendees/{eventId} {
      allow read: if request.auth != null;
      
      // Allow users to write their own attendee record
      match /attendees/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## How to Apply These Rules

### Option 1: Firebase Console (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your NaijaSingles project
3. Navigate to **Firestore Database** → **Rules**
4. Add the events-related rules above to your existing rules
5. Click **Publish**

### Option 2: Firebase CLI
If you're using Firebase CLI:
1. Update your `firestore.rules` file with the rules above
2. Run: `firebase deploy --only firestore:rules`

## Testing the Rules
After applying the rules, the Events feature should work without permission errors. You can test by:
1. Opening the Events tab in the app
2. Checking that events load properly
3. Testing RSVP functionality

## Temporary Workaround (Development Only)
If you want to test quickly during development, you can temporarily use these permissive rules (NOT for production):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // WARNING: These rules allow anyone to read/write. Use only for development!
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ Important:** Never use the permissive rules above in production as they allow unrestricted access to your database.

## Current Status
- ✅ **API Integration**: Fixed with real Eventbrite API key
- ✅ **Firestore Rules**: Successfully applied and deployed
- ✅ **Mock Data Fallback**: Available if API/Firestore fails
- ✅ **Error Handling**: Graceful fallbacks implemented

## ✅ Rules Applied Successfully

The Firestore security rules have been successfully deployed to your Firebase project. The Events feature should now work without permission errors.

**Deployment Details:**
- Rules deployed to project: `naijasingles-74a75`
- Deployment time: July 8, 2025
- Status: ✅ Successful

The Events feature is now fully functional with both real API data and proper Firestore caching.
