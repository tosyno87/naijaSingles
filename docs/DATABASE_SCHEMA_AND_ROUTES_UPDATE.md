# Database Schema and Routes Update

## Overview
This document outlines the comprehensive updates made to the Afropeep app's database schema, routes, and data validation to support the new cultural community features.

## 🗄️ Database Schema Updates

### New Cultural Fields Added to UserModel

```dart
// Cultural fields added to UserModel
final String? nationality;     // User's nationality (e.g., "Nigerian", "Ghanaian")
final String? tribe;           // User's tribe/ethnicity (e.g., "Yoruba", "Igbo")
final List<String>? languages; // Languages spoken by user
final String? religion;        // User's religion (optional)
final String? occupation;      // User's occupation (optional)
```

### Database Structure

The cultural fields are stored in the main user document with the following structure:

```json
{
  "users": {
    "userId": {
      "name": "John Doe",
      "age": 25,
      "gender": "Male",
      // ... existing fields ...
      
      // New cultural fields
      "nationality": "Nigerian",
      "tribe": "Yoruba", 
      "languages": ["English", "Yoruba"],
      "religion": "Christianity",
      "occupation": "Software Engineer",
      
      // Privacy structure (for future implementation)
      "public": {
        "profile": {
          "nationality": "Nigerian",
          "tribe": "Yoruba",
          "languages": ["English", "Yoruba"]
        }
      },
      "private": {
        "sensitive": {
          "religion": "Christianity",
          "occupation": "Software Engineer"
        }
      }
    }
  }
}
```

## 🛣️ Routes Cleanup and Organization

### Route Structure (Before vs After)

#### Before (Unorganized)
- Mixed route definitions
- Unused routes cluttering the codebase
- Inconsistent naming conventions
- Dead routes with no implementations

#### After (Organized)
```dart
class RouteName {
  // ===== CORE APP ROUTES =====
  static const String welcomeScreen = '/welcome';
  static const String mainNavigation = '/main_navigation';
  static const String onboarding = '/onboarding';

  // ===== AUTHENTICATION ROUTES =====
  static const String authMethodSelection = '/auth_method_selection';
  static const String signInMethodSelection = '/sign_in_method_selection';
  static const String emailSignup = '/email_signup';
  static const String emailLogin = '/email_login';
  static const String emailPasswordReset = '/email_password_reset';
  static const String phoneNumberScreen = '/phone_number';
  static const String otpScreen = '/otp';

  // ===== PROFILE & USER ROUTES =====
  static const String profileScreen = '/profile';
  static const String editProfileScreen = '/edit_profile';
  static const String culturalProfile = '/cultural_profile';
  static const String profilePicSetScreen = '/user_pic';
  static const String largeImageScreen = '/large_image';

  // ===== ONBOARDING ROUTES =====
  static const String genderScreen = '/gender';
  static const String sexualorientationScreen = '/sexual_details';
  static const String showGenderScreen = "/showgender";
  static const String userNameScreen = '/user_name';
  static const String userDobScreen = '/user_dob';
  static const String nationalityScreen = '/nationality';
  static const String universityScreen = '/user_university';
  static const String allowLocationScreen = '/allow_userLocation';
  static const String searchLocationpage = "/search";
  static const String updateLocationScreen = '/updatelocation';

  // ===== DISCOVERY & MATCHING ROUTES =====
  static const String exploreScreen = '/explore';
  static const String matchPage = '/match';
  static const String chatPageScreen = '/chat_page';

  // ===== SETTINGS ROUTES =====
  static const String settingPage = '/setting';
  static const String blockedUsers = '/blocked_users';
  static const String notificationSettings = '/notification_settings';
  static const String safetyCenter = '/safety_center';
  static const String helpCenter = '/help_center';
  static const String languageSettings = '/language_settings';
  static const String locationSettings = '/location_settings';
  static const String accountDeletion = '/account_deletion';
  static const String feedbackScreen = '/feedback';
  static const String updatePhoneScreen = '/update_number';

  // ===== EVENTS ROUTES =====
  static const String eventsScreen = '/events';
  static const String eventTemplateSelection = '/event-template-selection';
  static const String myEvents = '/my_events';
  static const String createEvent = '/create_event';
  static const String eventDetails = '/event_details';

  // ===== LEGACY ROUTES (for backward compatibility) =====
  static const String splashScreen = '/splash';
  static const String loginScreen = '/login';
  static const String tabScreen = '/tabbar';
  static const String datingHomePage = '/dating';
  static const String onboardingFlow = '/onboarding_flow';
  static const String mvpOnboarding = '/mvp_onboarding';
  static const String home = '/home';
  static const String discover = '/discover';
}
```

### Route Usage Analysis

**Active Routes (Used in Navigation):**
- ✅ `/welcome` - Welcome screen
- ✅ `/main_navigation` - Main app navigation
- ✅ `/onboarding` - User onboarding flow
- ✅ `/cultural_profile` - Cultural profile screen
- ✅ `/explore` - User discovery screen
- ✅ `/events` - Events screen
- ✅ `/create_event` - Event creation
- ✅ `/edit_profile` - Profile editing
- ✅ `/blocked_users` - Blocked users management
- ✅ `/feedback` - Feedback screen

**Legacy Routes (Kept for compatibility):**
- 🔄 `/splash` - Splash screen (replaced by native splash)
- 🔄 `/login` - Login screen (redirects to email login)
- 🔄 `/dating` - Dating screen (redirects to explore)

## 🔧 New Services Created

### 1. Cultural Fields Migration Service
**File:** `lib/services/cultural_fields_migration_service.dart`

**Purpose:** Migrate existing users to include new cultural fields

**Key Methods:**
- `migrateAllUsers()` - Migrate all users in the database
- `migrateCurrentUser()` - Migrate only the current user
- `isMigrationNeeded()` - Check if migration is required

**Features:**
- Intelligent field extraction from existing data
- Nationality derivation from location data
- Tribe derivation from name patterns
- Error handling and progress tracking

### 2. Cultural Data Validation Service
**File:** `lib/services/cultural_data_validation_service.dart`

**Purpose:** Validate cultural field data before saving

**Key Methods:**
- `validateNationality()` - Validate nationality field
- `validateTribe()` - Validate tribe field
- `validateLanguages()` - Validate languages list
- `validateReligion()` - Validate religion field
- `validateOccupation()` - Validate occupation field
- `validateAllCulturalFields()` - Validate all fields at once

**Validation Rules:**
- **Nationality:** Required, 2-50 characters, letters and spaces only
- **Tribe:** Required, 2-30 characters, letters and spaces only
- **Languages:** Required, 1-10 items, 2-20 characters each, no duplicates
- **Religion:** Optional, 2-30 characters, letters and spaces only
- **Occupation:** Optional, 2-50 characters, letters, spaces, and dots only

## 🔒 Security Updates

### Firebase Security Rules
**File:** `firestore_security_rules_update.txt`

**Key Updates:**
- Added support for cultural fields in user documents
- Implemented privacy controls for sensitive cultural data
- Added validation for cultural field access
- Maintained backward compatibility

**Privacy Considerations:**
- `nationality` and `tribe` are public for matching
- `languages` are public for compatibility
- `religion` and `occupation` are private by default
- All cultural fields are validated before saving

## 📊 Data Flow Updates

### Onboarding Flow
1. **Basic Info** → Collects name, age, gender
2. **Location** → Collects location and coordinates
3. **Tribe Selection** → Collects tribe/ethnicity
4. **Bio** → Collects user bio
5. **Interests** → Collects user interests
6. **Photos** → Collects profile photos
7. **Preferences** → Collects dating preferences
8. **Additional Info** → Collects cultural fields (nationality, languages, religion, occupation)

### Data Storage
- **Essential Data:** Saved immediately for app functionality
- **Cultural Data:** Saved with essential data for consistency
- **Photos:** Uploaded in background after essential data
- **Privacy Settings:** Applied during data saving

## 🚀 Migration Strategy

### Phase 1: Database Schema Update
- ✅ Updated UserModel with cultural fields
- ✅ Updated all serialization methods
- ✅ Added field validation

### Phase 2: Migration Service
- ✅ Created migration service for existing users
- ✅ Implemented intelligent field extraction
- ✅ Added error handling and progress tracking

### Phase 3: Route Cleanup
- ✅ Organized routes by category
- ✅ Identified and marked legacy routes
- ✅ Maintained backward compatibility

### Phase 4: Validation Service
- ✅ Created comprehensive validation service
- ✅ Added field-specific validation rules
- ✅ Implemented data sanitization

### Phase 5: Security Updates
- ✅ Updated Firebase security rules
- ✅ Added privacy controls for cultural data
- ✅ Maintained data access controls

## 🔍 Testing and Validation

### Migration Testing
```dart
// Test migration for current user
final migrationService = CulturalFieldsMigrationService();
final success = await migrationService.migrateCurrentUser();

// Test migration for all users
final result = await migrationService.migrateAllUsers();
print('Migrated ${result['migratedUsers']}/${result['totalUsers']} users');
```

### Validation Testing
```dart
// Test cultural field validation
final validation = CulturalDataValidationService.validateAllCulturalFields(
  nationality: 'Nigerian',
  tribe: 'Yoruba',
  languages: ['English', 'Yoruba'],
  religion: 'Christianity',
  occupation: 'Software Engineer',
);

if (validation.isValid) {
  print('All cultural fields are valid');
} else {
  print('Validation errors: ${validation.errors}');
}
```

## 📈 Performance Considerations

### Database Queries
- Cultural fields are indexed for efficient querying
- Privacy structure allows for selective data access
- Migration runs in batches to avoid timeouts

### Data Validation
- Client-side validation for immediate feedback
- Server-side validation for data integrity
- Cached validation results for performance

### Route Navigation
- Organized routes reduce navigation complexity
- Legacy routes maintained for backward compatibility
- Dead routes identified and marked for removal

## 🎯 Next Steps

1. **Deploy Migration Service** - Run migration for existing users
2. **Update UI Components** - Ensure all cultural fields are properly displayed
3. **Test Data Flow** - Verify data flows correctly through the app
4. **Monitor Performance** - Track migration and validation performance
5. **User Feedback** - Collect feedback on cultural field collection

## 🔧 Maintenance

### Regular Tasks
- Monitor migration success rates
- Update validation rules based on user feedback
- Clean up legacy routes as they become unused
- Update security rules as needed

### Monitoring
- Track cultural field completion rates
- Monitor validation error patterns
- Analyze user engagement with cultural features
- Measure impact on matching accuracy

---

**Last Updated:** December 2024  
**Version:** 1.0  
**Status:** Ready for Deployment
