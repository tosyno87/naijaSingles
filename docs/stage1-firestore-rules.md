# Stage 1: Firestore Security Rules for User-Generated Events

## Updated Security Rules

Add these rules to your `firestore.rules` file to support user-generated events:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Existing rules...
    
    // Events collection - enhanced for user-generated events
    match /events/{eventId} {
      // Allow read access to all published events
      allow read: if resource.data.status == 'published' || 
                     resource.data.status == 'completed';
      
      // Allow creators to read their own events regardless of status
      allow read: if request.auth != null && 
                     request.auth.uid == resource.data.createdByUserId;
      
      // Allow authenticated users to create events
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.createdByUserId &&
                       isValidEventData(request.resource.data);
      
      // Allow creators to update their own events (with restrictions)
      allow update: if request.auth != null && 
                       request.auth.uid == resource.data.createdByUserId &&
                       canUpdateEvent(resource.data, request.resource.data);
      
      // Allow creators to delete (soft delete) their own events
      allow delete: if request.auth != null && 
                       request.auth.uid == resource.data.createdByUserId;
    }
    
    // User events collection - tracks user's relationship with events
    match /user_events/{userId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
    }
    
    // Event moderation collection - admin only
    match /event_moderation/{eventId} {
      allow read: if request.auth != null && 
                     request.auth.uid in get(/databases/$(database)/documents/admin_users/list).data.userIds;
      allow write: if request.auth != null && 
                      request.auth.uid in get(/databases/$(database)/documents/admin_users/list).data.userIds;
    }
    
    // Event promotions collection
    match /event_promotions/{promotionId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == resource.data.userId;
    }
    
    // Helper functions
    function isValidEventData(data) {
      return data.keys().hasAll(['name', 'description', 'startDate', 'endDate', 
                                'location', 'category', 'isUserGenerated', 
                                'createdByUserId', 'status']) &&
             data.name is string && data.name.size() > 0 && data.name.size() <= 100 &&
             data.description is string && data.description.size() > 0 && data.description.size() <= 2000 &&
             data.startDate is timestamp &&
             data.endDate is timestamp &&
             data.startDate < data.endDate &&
             data.category is string && data.category.size() > 0 &&
             data.isUserGenerated is bool &&
             data.createdByUserId is string &&
             data.status in ['draft', 'underReview', 'published', 'cancelled', 'completed'] &&
             data.maxAttendees is int && data.maxAttendees > 0 && data.maxAttendees <= 10000 &&
             (data.isFree == true || (data.ticketPrice is number && data.ticketPrice > 0));
    }
    
    function canUpdateEvent(oldData, newData) {
      // Users can only update their own events
      return oldData.createdByUserId == newData.createdByUserId &&
             // Cannot change core identification fields
             oldData.createdByUserId == newData.createdByUserId &&
             oldData.isUserGenerated == newData.isUserGenerated &&
             // Can only edit if event is in draft or under review
             (oldData.status == 'draft' || oldData.status == 'underReview') &&
             // Status can only change from draft to underReview or stay the same
             (newData.status == oldData.status || 
              (oldData.status == 'draft' && newData.status == 'underReview')) &&
             // Validate the updated data
             isValidEventData(newData);
    }
  }
}
```

## Database Indexes Required

Add these composite indexes to your Firestore:

```json
{
  "indexes": [
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "isUserGenerated", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "startDate", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "createdByUserId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "startDate", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "category", "order": "ASCENDING"},
        {"fieldPath": "startDate", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "location.city", "order": "ASCENDING"},
        {"fieldPath": "startDate", "order": "ASCENDING"}
      ]
    }
  ]
}
```

## Implementation Steps

1. **Update firestore.rules file**:
   ```bash
   # Copy the rules above to your firestore.rules file
   firebase deploy --only firestore:rules
   ```

2. **Add composite indexes**:
   ```bash
   # Add the indexes to your firestore.indexes.json file
   firebase deploy --only firestore:indexes
   ```

3. **Create admin users collection** (for moderation):
   ```javascript
   // In Firebase Console or via admin SDK
   db.collection('admin_users').doc('list').set({
     userIds: ['admin-user-id-1', 'admin-user-id-2']
   });
   ```

## Security Considerations

1. **User Authentication**: All write operations require authentication
2. **Data Validation**: Comprehensive validation of event data structure
3. **Permission Checks**: Users can only modify their own events
4. **Status Restrictions**: Events can only be updated in certain statuses
5. **Admin Controls**: Moderation collection is admin-only
6. **Read Permissions**: Public can only read published events

## Testing the Rules

Use the Firebase Rules Playground to test these scenarios:

1. **Authenticated user creates event**: Should succeed
2. **Unauthenticated user creates event**: Should fail
3. **User updates another user's event**: Should fail
4. **User updates published event**: Should fail
5. **Public reads published event**: Should succeed
6. **Public reads draft event**: Should fail

## Migration Notes

- Existing events from external APIs will continue to work
- New `isUserGenerated` field distinguishes user events from API events
- Backward compatibility maintained for existing event structure
