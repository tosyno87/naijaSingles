# User Profile Security Analysis - NaijaSingles

## 🔍 **Current Security Status**

### ✅ **What's Secure**

1. **Authentication Required**: All profile access requires valid Firebase authentication
2. **User Isolation**: Users can only modify their own profiles
3. **Critical Field Protection**: Email, createdAt, uid, signInMethod are protected
4. **Discovery Control**: Other users can read profiles for matching purposes

### ⚠️ **Security Vulnerabilities Identified**

#### 1. **Sensitive Data Exposure** (🔴 HIGH RISK)
**Issue**: All profile data is readable by any authenticated user for "discovery"
```javascript
// Current rule allows ANY authenticated user to read profiles
allow read: if request.auth != null;
```

**Exposed Data Includes**:
- Phone numbers (`phoneNumber`)
- Exact location coordinates (`latitude`, `longitude`)
- Home address (`address`, `living_in`)
- Company information (`company`, `job_title`)
- Personal preferences (`sexualOrientation`, `ageRange`)
- Detailed location data (`coordinates`, `currentCoordinates`)

**Risk**: Privacy violation, stalking, identity theft

#### 2. **Location Privacy** (🔴 HIGH RISK)
**Exposed Location Data**:
```dart
final double? latitude;
final double? longitude;
final Map? coordinates;
final Map? currentCoordinates;
String? address;
final String? living_in;
```

**Risk**: Users' exact locations are visible to all other users

#### 3. **Contact Information Exposure** (🟡 MEDIUM RISK)
```dart
final String? phoneNumber;
```
**Risk**: Phone numbers accessible to all authenticated users

#### 4. **No Data Classification** (🟡 MEDIUM RISK)
**Issue**: No distinction between public and private profile data

## 🛡️ **Recommended Security Improvements**

### 1. **Implement Data Classification**

Create separate collections for public and private data:

```javascript
// Enhanced Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Public profile data (for discovery)
    match /users/{userId}/public/{document=**} {
      // Anyone can read public profile data
      allow read: if request.auth != null;
      // Only owner can write
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Private profile data (sensitive info)
    match /users/{userId}/private/{document=**} {
      // Only owner can read/write private data
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Main user document (basic info only)
    match /users/{userId} {
      // Read access for discovery (limited fields)
      allow read: if request.auth != null;
      // Write access for owner only
      allow write: if request.auth != null && 
                    request.auth.uid == userId &&
                    // Validate only safe fields are being updated
                    request.resource.data.keys().hasOnly([
                      'name', 'age', 'bio', 'photos', 'interests', 
                      'lookingFor', 'relationshipIntent', 'tribe'
                    ]);
    }
  }
}
```

### 2. **Restructure User Data**

#### Public Profile (Visible to all users):
```dart
class PublicUserProfile {
  final String id;
  final String name;
  final int age;
  final String bio;
  final List<String> photos;
  final List<String> interests;
  final String lookingFor;
  final String relationshipIntent;
  final String tribe;
  final int approximateDistance; // Rounded to nearest 5km
  // NO exact coordinates, phone, address, etc.
}
```

#### Private Profile (Owner only):
```dart
class PrivateUserProfile {
  final String phoneNumber;
  final String email;
  final String address;
  final double latitude;
  final double longitude;
  final Map coordinates;
  final String company;
  final String jobTitle;
  final Map sexualOrientation;
  final Map ageRange;
  final Map preferences;
  // All sensitive data here
}
```

### 3. **Location Privacy Enhancement**

```dart
// Instead of exact coordinates, use:
class LocationData {
  final String city;
  final String state;
  final int approximateDistance; // Rounded distance
  final String neighborhood; // Optional, general area
  // NO exact lat/lng in public profile
}
```

### 4. **Enhanced Security Rules**

```javascript
// Improved user profile rules
match /users/{userId} {
  // Public profile - limited fields only
  allow read: if request.auth != null && 
               // Only allow reading safe fields
               resource.data.keys().hasOnly([
                 'name', 'age', 'bio', 'photos', 'interests',
                 'lookingFor', 'relationshipIntent', 'tribe',
                 'city', 'approximateDistance'
               ]);
  
  // Profile updates - validate data
  allow update: if request.auth != null && 
                 request.auth.uid == userId &&
                 // Prevent updating sensitive fields
                 !request.resource.data.diff(resource.data).affectedKeys()
                   .hasAny(['phoneNumber', 'email', 'latitude', 'longitude', 
                           'address', 'coordinates', 'createdAt', 'uid']);
}

// Sensitive data collection
match /users/{userId}/sensitive/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

## 🚀 **Enhanced Implementation Plan (Updated with User Suggestions)**

### Phase 1: Immediate Security Fixes (High Priority)
1. **Enhanced Location Privacy with GeoHash**
   - Implement GeoHash-based radius queries
   - Add location precision settings: 'high' | 'medium' | 'low'
   - Use City + Region format (e.g., "Lagos, NG")
   - Remove exact coordinates from public profiles

2. **Custom User Privacy Controls**
   - Toggle visibility for Age
   - Toggle visibility for Tribe  
   - Toggle visibility for Orientation
   - User-controlled privacy dashboard

3. **Logging & Alerts for Rule Violations**
   - Enable Firebase security logging for blocked field access attempts
   - Admin dashboard alerts for violation spikes
   - Monitoring for suspicious access patterns

4. **Subcollections Security Audit**
   - Verify Chats/Messages are properly scoped by match IDs
   - Ensure Unmatch/Blocked collections aren't readable by others
   - Validate all subcollection access patterns

### Phase 2: Privacy Controls (Medium Priority)
1. **Advanced Privacy Settings**
2. **Location approximation refinement**
3. **Enhanced blocking features**
4. **Profile visibility controls**

### Phase 3: Advanced Security (Future)
1. **Data encryption for sensitive fields**
2. **Audit logging for profile access**
3. **GDPR compliance features**
4. **Advanced threat detection**

## 📋 **Migration Script Example**

```dart
// Migration script to restructure user data
Future<void> migrateUserProfiles() async {
  final users = await FirebaseFirestore.instance.collection('users').get();
  
  for (var doc in users.docs) {
    final data = doc.data();
    final userId = doc.id;
    
    // Create public profile
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('public')
        .doc('profile')
        .set({
      'name': data['name'],
      'age': data['age'],
      'bio': data['bio'],
      'photos': data['photos'],
      'interests': data['interests'],
      'city': data['living_in'],
      // Only safe, public data
    });
    
    // Create private profile
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('private')
        .doc('sensitive')
        .set({
      'phoneNumber': data['phoneNumber'],
      'email': data['email'],
      'latitude': data['latitude'],
      'longitude': data['longitude'],
      'address': data['address'],
      'company': data['company'],
      // All sensitive data
    });
    
    // Update main document with only essential data
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      // Remove sensitive fields from main document
      'phoneNumber': FieldValue.delete(),
      'latitude': FieldValue.delete(),
      'longitude': FieldValue.delete(),
      'address': FieldValue.delete(),
      'company': FieldValue.delete(),
    });
  }
}
```

## 🎯 **Immediate Actions Required**

### Critical (Do Now):
1. **Audit current data exposure** - Check what sensitive data is currently visible
2. **Implement basic field restrictions** - Limit readable fields in discovery
3. **Remove exact location coordinates** from public profiles
4. **Hide phone numbers** from discovery queries

### Important (This Week):
1. **Plan data restructuring** - Design new collection structure
2. **Create migration strategy** - Plan how to move existing data
3. **Update security rules** - Implement field-level restrictions
4. **Test with sample data** - Verify security improvements

### Future (Next Sprint):
1. **Full data migration** - Move to new secure structure
2. **Privacy controls** - Let users control what's visible
3. **Location approximation** - Show general area instead of exact location
4. **Enhanced blocking** - More granular privacy controls

## 🔒 **Security Best Practices**

1. **Principle of Least Privilege**: Only expose data necessary for app functionality
2. **Data Classification**: Separate public and private data
3. **Location Privacy**: Never expose exact coordinates
4. **Contact Protection**: Keep phone/email private
5. **User Control**: Let users control their privacy settings
6. **Regular Audits**: Periodically review data exposure
7. **Compliance**: Consider GDPR, CCPA requirements

## 📊 **Current Risk Level: HIGH** 🔴

Your current setup exposes sensitive user data to all authenticated users. This poses significant privacy and safety risks for your Nigerian users, especially in a dating app context.

**Immediate action is recommended to protect user privacy and comply with data protection standards.**
