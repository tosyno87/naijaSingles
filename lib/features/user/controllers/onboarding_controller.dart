import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import '../../../common/widgets/loading_transition_screen.dart';
import '../../../common/providers/user_provider.dart';
import '../../../services/profile_image_cropper_service.dart';
import '../../../services/bulk_photo_picker_service.dart';
import '../../../common/utils/app_logger.dart';

class OnboardingController extends ChangeNotifier {
  // Basic user data
  String _fullName = '';
  DateTime? _dateOfBirth;
  String _gender = '';
  String _tribe = '';
  String _bio = '';
  List<String> _interests = [];
  List<File?> _profilePhotos = List.filled(5, null); // Support up to 5 photos
  bool _isLoading = false;

  // Additional user data (for compatibility with existing code)
  String? _userName;
  String? _locationName;
  String? _intent;
  String? _nationality;
  String? _education;
  String? _occupation;
  String? _fashionStyle;
  String? _weekendVibe;
  String _religion = ''; // Add religion field
  List<String> _languages = [];
  List<String> _genres = [];
  List<String> _values = [];
  List<String> _photos = [];
  List<String> _dealbreakers = []; // Add dealbreakers property

  // User preferences
  String _interestedIn = 'everyone'; // Default to everyone
  List<int> _ageRange = [18, 50]; // Default age range

  // Additional profile fields
  double _height = 170.0; // Default height in cm
  String _heightUnit = 'cm'; // 'cm' or 'ft'
  String _lookingFor = 'Dating'; // Dating, Friendship, Networking
  String _relationshipIntent =
      'Not sure yet'; // Short-term, Long-term, Casual, Not sure yet

  // Location coordinates - CRITICAL FOR DISCOVERY
  double? _latitude;
  double? _longitude;

  // Enhanced additional info fields (using existing declarations above)
  String _drinkingPreference = '';
  String _smokingPreference = '';

  // Getters for basic data
  String get fullName => _fullName;
  DateTime? get dateOfBirth => _dateOfBirth;
  String get gender => _gender;
  String get tribe => _tribe;
  String get bio => _bio;
  List<String> get interests => _interests;
  List<File?> get profilePhotos => _profilePhotos;

  // Location getters - CRITICAL FOR DISCOVERY
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isLoading => _isLoading;

  // Legacy getter for backward compatibility
  File? get profilePhoto =>
      _profilePhotos.firstWhere((photo) => photo != null, orElse: () => null);

  // Getters for additional data
  String? get userName => _userName;
  String? get locationName => _locationName;
  String? get intent => _intent;
  String? get nationality => _nationality;
  String? get education => _education;
  String? get fashionStyle => _fashionStyle;
  String? get weekendVibe => _weekendVibe;
  List<String> get languages => _languages;
  List<String> get genres => _genres;
  List<String> get values => _values;
  List<String> get photos => _photos;
  List<String> get dealbreakers => _dealbreakers; // Add dealbreakers getter

  // Preference getters
  String get interestedIn => _interestedIn;
  List<int> get ageRange => _ageRange;

  // Additional profile getters
  double get height => _height;
  String get heightUnit => _heightUnit;
  String get lookingFor => _lookingFor;
  String get relationshipIntent => _relationshipIntent;

  // Enhanced additional info getters
  String get educationLevel => _education ?? '';
  String get religion => _religion;
  List<String> get spokenLanguages => _languages;
  String get occupation => _occupation ?? '';
  String get drinkingPreference => _drinkingPreference;
  String get smokingPreference => _smokingPreference;

  // Height display helper
  String get heightDisplay {
    if (_heightUnit == 'cm') {
      return '${_height.round()} cm';
    } else {
      // Convert cm to feet and inches
      double totalInches = _height / 2.54;
      int feet = (totalInches / 12).floor();
      int inches = (totalInches % 12).round();
      return '$feet\'$inches"';
    }
  }

  // Age calculation
  int get age {
    if (_dateOfBirth == null) return 0;

    final today = DateTime.now();
    int age = today.year - _dateOfBirth!.year;

    if (today.month < _dateOfBirth!.month ||
        (today.month == _dateOfBirth!.month && today.day < _dateOfBirth!.day)) {
      age--;
    }

    return age;
  }

  // Basic setters
  void setFullName(String name) {
    _fullName = name;
    _userName = name; // For compatibility
    notifyListeners();
  }

  void setDateOfBirth(DateTime date) {
    _dateOfBirth = date;
    notifyListeners();
  }

  void setGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  void setLocationName(String locationName) {
    _locationName = locationName;
    notifyListeners();
    debugPrint('🔍 OnboardingController: Location set to "$locationName"');
  }

  void setTribe(String tribe) {
    _tribe = tribe;
    notifyListeners();
  }

  void setBio(String bio) {
    _bio = bio;
    notifyListeners();
  }

  void addInterest(String interest) {
    if (!_interests.contains(interest)) {
      _interests.add(interest);
      // For compatibility
      if (!_genres.contains(interest)) {
        _genres.add(interest);
      }
      notifyListeners();
    }
  }

  void removeInterest(String interest) {
    _interests.remove(interest);
    _genres.remove(interest); // For compatibility
    notifyListeners();
  }

  // Additional setters for compatibility
  void updateUserName(String name) {
    _userName = name;
    _fullName = name;
    notifyListeners();
  }

  void updateDateOfBirth(DateTime date) {
    _dateOfBirth = date;
    notifyListeners();
  }

  void updateLocation(double lat, double lng, String locationName) {
    _locationName = locationName;
    notifyListeners();
  }

  void updateBio(String bio) {
    _bio = bio;
    notifyListeners();
  }

  void updateTribe(String tribe) {
    _tribe = tribe;
    notifyListeners();
  }

  void updateIntent(String intent) {
    _intent = intent;
    notifyListeners();
  }

  void updateGenres(List<String> genres) {
    _genres = List.from(genres);
    _interests = List.from(genres); // For compatibility
    notifyListeners();
  }

  void updateLanguages(List<String> languages) {
    _languages = List.from(languages);
    notifyListeners();
  }

  void updateNationality(String nationality, bool isDiaspora) {
    _nationality = nationality;
    notifyListeners();
  }

  void updateFashionStyle(String style) {
    _fashionStyle = style;
    notifyListeners();
  }

  void updateWeekendVibe(String vibe) {
    _weekendVibe = vibe;
    notifyListeners();
  }

  void updateValues(List<String> values) {
    _values = List.from(values);
    notifyListeners();
  }

  void updateDealbreakers(List<String> dealbreakers) {
    _dealbreakers = List.from(dealbreakers);
    notifyListeners();
  }

  // Preference setters
  void setInterestedIn(String interestedIn) {
    _interestedIn = interestedIn;
    notifyListeners();
  }

  void setAgeRange(List<int> ageRange) {
    _ageRange = List.from(ageRange);
    notifyListeners();
  }

  // Additional profile setters
  void setHeight(double height, String unit) {
    _height = height;
    _heightUnit = unit;
    notifyListeners();
  }

  // New method for dropdown height format
  void setHeightFromDropdown(String heightFtIn, int heightCm) {
    _height = heightCm.toDouble();
    _heightUnit = 'cm';
    notifyListeners();
  }

  void setLookingFor(String lookingFor) {
    _lookingFor = lookingFor;
    notifyListeners();
  }

  void setRelationshipIntent(String intent) {
    _relationshipIntent = intent;
    notifyListeners();
  }

  // Enhanced additional info setters
  void setEducation(String education) {
    _education = education;
    notifyListeners();
  }

  void setReligion(String religion) {
    _religion = religion;
    notifyListeners();
  }

  void setSpokenLanguages(List<String> languages) {
    _languages = List.from(languages);
    notifyListeners();
  }

  void addLanguage(String language) {
    if (!_languages.contains(language)) {
      _languages.add(language);
      notifyListeners();
    }
  }

  void removeLanguage(String language) {
    _languages.remove(language);
    notifyListeners();
  }

  void setOccupation(String occupation) {
    _occupation = occupation;
    notifyListeners();
  }

  void setDrinkingPreference(String preference) {
    _drinkingPreference = preference;
    notifyListeners();
  }

  void setSmokingPreference(String preference) {
    _smokingPreference = preference;
    notifyListeners();
  }

  // Location setters - CRITICAL FOR DISCOVERY
  void setLocationCoordinates(double latitude, double longitude) {
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }

  void updatePhotos(List<String> photos) {
    _photos = List.from(photos);
    notifyListeners();
  }

  // Validation methods
  bool isBasicInfoComplete() {
    return _fullName.isNotEmpty &&
        _dateOfBirth != null &&
        _gender.isNotEmpty &&
        age >= 18; // Ensure user is at least 18
  }

  bool isTribeSelected() {
    return _tribe.isNotEmpty;
  }

  bool isBioComplete() {
    return _bio.length >= 50; // Updated minimum bio length for dating context
  }

  bool areInterestsSelected() {
    return _interests.length >=
        5; // Require at least 5 interests for better matching
  }

  bool isPhotoUploaded() {
    // Require at least 3 photos
    int photoCount = _profilePhotos.where((photo) => photo != null).length;
    return photoCount >= 3;
  }

  // Photo selection for a specific index with industry-standard cropping
  Future<void> pickProfilePhoto(ImageSource source, int index, BuildContext? context) async {
    try {
      log("📸 Starting photo pick for index $index with source: $source");
      
      // Determine crop type based on photo index
      CropType cropType;
      String title;

      switch (index) {
        case 0:
          cropType = CropType.square; // Main photo - square crop
          title = 'Crop Main Photo';
          break;
        case 1:
          cropType = CropType.portrait; // Full body - portrait crop
          title = 'Crop Full Body Photo';
          break;
        case 2:
          cropType = CropType.landscape; // Activity - landscape crop
          title = 'Crop Activity Photo';
          break;
        case 3:
          cropType = CropType.portrait; // Social - portrait crop
          title = 'Crop Social Photo';
          break;
        case 4:
          cropType = CropType.freeform; // Lifestyle - freeform crop
          title = 'Crop Lifestyle Photo';
          break;
        default:
          cropType = CropType.square;
          title = 'Crop Photo';
      }

      // Pick and crop image with industry-standard settings and permission handling
      final File? croppedImage =
          await ProfileImageCropperService.pickAndCropImage(
        source: source,
        cropType: cropType,
        title: title,
        context: context,
      );

      if (croppedImage != null) {
        _profilePhotos[index] = croppedImage;
        notifyListeners();
        log("✅ Photo $index cropped and saved successfully");
      } else {
        log("⚠️ Photo selection cancelled or failed for index $index");
      }
    } catch (e, stackTrace) {
      log("❌ Error picking and cropping image: $e");
      log("❌ Stack trace: $stackTrace");
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${source == ImageSource.camera ? 'take' : 'select'} photo. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hinge-style bulk photo selection
  Future<void> pickMultiplePhotos(BuildContext context) async {
    try {
      // Pick multiple photos at once
      final List<File> selectedPhotos =
          await BulkPhotoPickerService.pickMultiplePhotos(
        context: context,
        maxPhotos: 5,
      );

      if (selectedPhotos.isEmpty) return;

      // Crop each photo individually
      final List<File> croppedPhotos =
          await BulkPhotoPickerService.cropSelectedPhotos(
        selectedPhotos: selectedPhotos,
        context: context,
      );

      // Add cropped photos to profile photos
      for (int i = 0;
          i < croppedPhotos.length && i < _profilePhotos.length;
          i++) {
        _profilePhotos[i] = croppedPhotos[i];
      }

      notifyListeners();
      log("✅ Bulk photo selection completed: ${croppedPhotos.length} photos added");
    } catch (e) {
      log("❌ Error in bulk photo selection: $e");
    }
  }

  // Remove photo at specific index
  void removeProfilePhoto(int index) {
    if (index >= 0 && index < _profilePhotos.length) {
      _profilePhotos[index] = null;
      notifyListeners();
    }
  }

  // Save all user data to Firestore with optimized flow
  Future<void> saveUserData({BuildContext? context}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate onboarding data before saving
      debugPrint('🔍 Validating onboarding data before save...');
      bool isDataValid = validateOnboardingData();

      if (!isDataValid) {
        debugPrint(
            '❌ Onboarding data validation failed - some required fields are missing');
        // Still proceed with save but log the issues
      }

      // Print data summary for debugging
      final summary = getOnboardingDataSummary();
      debugPrint('📊 Onboarding Data Summary: $summary');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Show loading screen if context is provided
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LoadingTransitionScreen(),
          ),
        );
      }

      // Start a timer to ensure we don't wait too long
      bool timeoutReached = false;
      Future.delayed(const Duration(seconds: 5), () {
        timeoutReached = true;
        // If we're still on loading screen after 5 seconds, navigate anyway
        if (context != null && context.mounted) {
          try {
            _navigateToMainScreen(context);
          } catch (e) {
            debugPrint('❌ Error navigating after timeout: $e');
          }
        }
      });

      // First, save essential user data (fast operation)
      await _saveEssentialUserData(user.uid);

      // Upload photos BEFORE navigation to ensure they're saved
      // This ensures profile screen shows photos immediately
      try {
        await _uploadProfilePictures(user.uid);
        debugPrint('✅ Profile photos uploaded successfully');
      } catch (e) {
        debugPrint('⚠️ Photo upload failed (non-critical): $e');
        // Continue even if photos fail - user can add them later
      }

      // If we haven't timed out yet, navigate now that essential data and photos are saved
      if (!timeoutReached && context != null && context.mounted) {
        try {
          _navigateToMainScreen(context);
        } catch (e) {
          debugPrint('❌ Error navigating after save: $e');
        }
      }

      // Continue with non-essential operations in background (legacy cleanup)
      Future.delayed(const Duration(seconds: 1), () {
        // Update UI if needed when pictures are done uploading
        log('✅ Profile pictures uploaded successfully');
        notifyListeners(); // Notify listeners that photos are now uploaded
      }).catchError((error) {
        log('❌ Failed to upload profile pictures: $error', error: error);
        // Update error state for potential retry
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ User data saved successfully! Navigating to main app...');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      log("Error saving user data: $e");

      // If there's an error but context is provided, still navigate
      if (context != null && context.mounted) {
        try {
          _navigateToMainScreen(context);
        } catch (e) {
          debugPrint('❌ Error navigating after error: $e');
        }
      }

      rethrow;
    }
  }

  // Navigate to main screen
  void _navigateToMainScreen(BuildContext context) async {
    // Ensure UserProvider is updated before navigation
    // This prevents MainNavigationScreen from redirecting back to onboarding
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Force UserProvider to reload user data from Firestore
        // This ensures MainNavigationScreen sees the updated profile
        await userProvider.listenCurrentUserdetails();
        
        // Wait a bit for the listener to update
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Verify user data is loaded before navigating
        int retries = 0;
        while (retries < 5 && 
               (userProvider.currentUser == null || 
                userProvider.currentUser?.name == null ||
                userProvider.currentUser?.name?.isEmpty == true)) {
          await Future.delayed(const Duration(milliseconds: 200));
          retries++;
        }
        
        if (userProvider.currentUser?.name != null && 
            userProvider.currentUser!.name!.isNotEmpty) {
          log('✅ UserProvider updated with profile, navigating to main screen');
        } else {
          log('⚠️ UserProvider not updated after retries, navigating anyway');
        }
      }
    } catch (e) {
      log('⚠️ Error updating UserProvider before navigation: $e');
      // Navigate anyway - MainNavigationScreen will handle the check
    }
    
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/main_navigation',
        (route) => false,
      );
    }
  }

  // Save only essential user data needed for app functionality
  Future<void> _saveEssentialUserData(String userId) async {
    // Create minimal user data map with only essential fields
    final essentialData = {
      // Basic profile information
      'name': _fullName,
      'userName': _fullName,
      'dateOfBirth': _dateOfBirth?.toIso8601String(),
      'age': age,
      'gender': _gender,
      'tribe': _tribe,
      'bio': _bio,
      'interests': _interests,

      // Height information (multiple formats for compatibility)
      'height': _height,
      'height_ft_in': _getHeightFtIn(),
      'height_cm': _height.round(),
      'heightDisplay': _getHeightFtIn(),
      'heightUnit': _heightUnit,

      // Dating preferences
      'lookingFor': _lookingFor,
      'relationshipIntent': _relationshipIntent,
      'interestedIn': _interestedIn,

      // Additional profile fields (if available)
      'intent': _intent,
      'nationality': _nationality,
      'education': _education,
      'occupation': _occupation,
      'fashionStyle': _fashionStyle,
      'weekendVibe': _weekendVibe,
      'religion': _religion,
      'languages': _languages,
      'genres': _genres,
      'values': _values,
      'dealbreakers': _dealbreakers,
      'drinkingPreference': _drinkingPreference,
      'smokingPreference': _smokingPreference,

      // System fields
      'lastActive': DateTime.now().toIso8601String(),
      'isProfileComplete': true,
      'isBlocked': false,
      'isPremium': false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),

      // Legacy compatibility fields
      'editInfo': {
        'userGender': _gender,
        'userName': _fullName,
      },

      // Preferences structure - CRITICAL FOR DISCOVERY
      'preferences': {
        'interestedIn': _interestedIn,
        'ageRange': _ageRange,
        'lookingFor': _lookingFor,
        'relationshipIntent': _relationshipIntent,
        'maximumDistance': 100, // Increased for better discovery
      },

      // Legacy preference fields - CRITICAL FOR DISCOVERY
      'showGender': _interestedIn,
      'ageRange': {
        'min': _ageRange[0].toString(),
        'max': _ageRange[1].toString(),
      },

      // Additional discovery fields - CRITICAL FOR USER DISCOVERY
      'userGender': _gender, // Required for gender filtering
      'age_range': {
        'min': _ageRange[0].toString(),
        'max': _ageRange[1].toString(),
      },
      'maximum_distance': 62, // 100km = 62 miles for better discovery
      'maxDistance': 62, // Alternative field name for compatibility

      // Location information - CRITICAL FOR DISCOVERY
      'location': {
        'latitude': _latitude ?? 6.5244, // Use actual GPS or default to Lagos
        'longitude': _longitude ?? 3.3792,
        'address': _locationName ?? 'Location not set',
        'city': _locationName ?? 'Location not set',
      },
      'locationName': _locationName, // Direct field for easy access
      'latitude': _latitude ?? 6.5244, // Use actual GPS or default to Lagos
      'longitude': _longitude ?? 3.3792,

      // Profile completion status
      'onboardingCompleted': true,
      'profileSetupComplete': true,
    };

    // Debug logging to verify all data is being saved
    AppLogger.info('🔍 Saving comprehensive user data:');
    AppLogger.debug('   Name: $_fullName');
    AppLogger.debug('   Age: $age');
    AppLogger.debug('   Gender: $_gender');
    AppLogger.debug('   Location: ${_locationName ?? 'Not set'}');
    AppLogger.debug(
        '   Coordinates: ${_latitude ?? 'Not set'}, ${_longitude ?? 'Not set'}');
    AppLogger.debug('   Tribe: $_tribe');
    AppLogger.debug('   Bio: ${_bio.length} characters');
    AppLogger.debug('   Interests: ${_interests.length} items - $_interests');
    AppLogger.debug('   Height: $_height cm (${_getHeightFtIn()})');
    AppLogger.debug('   Looking for: $_lookingFor');
    AppLogger.debug('   Relationship intent: $_relationshipIntent');
    AppLogger.debug('   Interested in: $_interestedIn');
    AppLogger.debug('   Age range: $_ageRange');
    AppLogger.debug('   Show gender: $_interestedIn');
    AppLogger.debug('   Maximum distance: 62 miles');
    AppLogger.debug('   Additional fields:');
    AppLogger.debug('     Education: $_education');
    AppLogger.debug('     Occupation: $_occupation');
    AppLogger.debug('     Religion: $_religion');
    AppLogger.debug('     Languages: $_languages');
    AppLogger.debug('     Drinking: $_drinkingPreference');
    AppLogger.debug('     Smoking: $_smokingPreference');
    AppLogger.debug('     Nationality: $_nationality');
    AppLogger.debug(
        '   Profile photos: ${_profilePhotos.where((p) => p != null).length} photos');

    // Save essential data to Firestore
    AppLogger.info('🔍 Saving essential user data to Firestore...');
    
    // Use set with merge: true to preserve existing fields (like email from account creation)
    // and add/update onboarding data
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(essentialData, SetOptions(merge: true));
    
    // Ensure completion flags are explicitly set (merge might not override if field exists)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'onboardingCompleted': true,
      'profileSetupComplete': true,
      'isProfileComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Update display name in Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(_fullName);
    }

    AppLogger.info('✅ Essential user data saved successfully');
    AppLogger.info('✅ All onboarding data should now be available in profile');
  }

  // Upload profile pictures with proper error handling
  Future<void> _uploadProfilePictures(String userId) async {
    List<String> photoUrls = [];
    List<File> validPhotos = _profilePhotos.whereType<File>().toList();

    if (validPhotos.isEmpty) {
      log('⚠️ No photos to upload');
      return;
    }

    log('📸 Starting upload of ${validPhotos.length} profile pictures for user: $userId');

    try {
      for (int i = 0; i < validPhotos.length; i++) {
        final photo = validPhotos[i];

        // Validate file exists and is readable
        if (!photo.existsSync()) {
          log('❌ Photo $i does not exist at path: ${photo.path}');
          continue;
        }

        // Check file size (max 10MB)
        final fileSize = await photo.length();
        const maxSize = 10 * 1024 * 1024; // 10MB
        if (fileSize > maxSize) {
          log('❌ Photo $i is too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB (max 10MB)');
          continue;
        }

        log('📤 Uploading photo $i/${validPhotos.length} (${(fileSize / 1024).toStringAsFixed(2)}KB)...');

        bool uploadSuccess = false;
        
        try {
          // Create storage reference
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('users/$userId/profile_photo_$i.jpg');

          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedAt': DateTime.now().toIso8601String(),
              'photoIndex': i.toString(),
            },
          );

          // Use putData (foreground upload) directly to avoid background session errors on simulator
          // This works on both simulator and physical devices
          log('📦 Using putData (foreground upload) for photo $i to avoid simulator issues...');
          final bytes = await photo.readAsBytes();
          final uploadTask = storageRef.putData(bytes, metadata);

          // Wait for upload to complete with timeout
          final snapshot = await uploadTask.timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              throw TimeoutException('Photo upload timed out after 2 minutes');
            },
          );

          // Get download URL
          final url = await snapshot.ref.getDownloadURL();
          photoUrls.add(url);
          uploadSuccess = true;

          log('✅ Photo $i uploaded successfully: $url');
        } catch (uploadError) {
          log('❌ Error uploading photo $i: $uploadError', error: uploadError);
          
          // If putData failed, try putFile as fallback (shouldn't happen, but just in case)
          if (!uploadSuccess) {
            log('🔄 Retrying photo $i with putFile as fallback...');
            try {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('users/$userId/profile_photo_$i.jpg');
              
              final uploadTask = storageRef.putFile(
                photo,
                SettableMetadata(
                  contentType: 'image/jpeg',
                  customMetadata: {
                    'uploadedAt': DateTime.now().toIso8601String(),
                    'photoIndex': i.toString(),
                  },
                ),
              );
              
              final snapshot = await uploadTask.timeout(
                const Duration(minutes: 2),
                onTimeout: () {
                  throw TimeoutException('Photo upload timed out after 2 minutes');
                },
              );
              
              final url = await snapshot.ref.getDownloadURL();
              photoUrls.add(url);
              uploadSuccess = true;
              log('✅ Photo $i uploaded successfully (retry with putFile): $url');
            } catch (retryError) {
              log('❌ Retry also failed for photo $i: $retryError');
              // Continue with next photo instead of failing all
            }
          }
          
          if (!uploadSuccess) {
            log('⚠️ Photo $i could not be uploaded, continuing with remaining photos...');
          }
        }
      }

      // Update photos list for compatibility
      if (photoUrls.isNotEmpty) {
        _photos = photoUrls;

        // Update Firestore with photo URLs
        final photoData = {
          'profilePicture': photoUrls[0], // Main profile picture
          'photos': photoUrls, // Array of all photo URLs
          'Pictures': photoUrls, // Legacy field name
          'imageUrl': photoUrls, // Alternative field name
          'profilePhotoCount': photoUrls.length,
          'lastPhotoUpdate': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(photoData, SetOptions(merge: true));

        log('✅ Successfully updated Firestore with ${photoUrls.length} photo URLs');
      } else {
        log('⚠️ No photos were successfully uploaded');
        throw Exception('Failed to upload any profile photos');
      }
    } catch (e) {
      log('❌ Critical error in _uploadProfilePictures: $e', error: e);
      // Re-throw so calling code can handle it
      rethrow;
    }
  }

  // Navigation method for onboarding screens
  void nextPage() {
    // This method is called from onboarding screens to signal
    // that the current page is complete and we can move to the next one
    notifyListeners();
  }

  // Helper method to get ft/in format from height in cm
  String _getHeightFtIn() {
    double totalInches = _height / 2.54;
    int feet = (totalInches / 12).floor();
    int inches = (totalInches % 12).round();
    return '$feet\'$inches"';
  }

  // Validation method to ensure all required onboarding data is present
  bool validateOnboardingData() {
    AppLogger.debug('🔍 Validating onboarding data completeness:');

    bool isValid = true;
    List<String> missingFields = [];

    // Required fields validation
    if (_fullName.isEmpty) {
      missingFields.add('Full Name');
      isValid = false;
    }

    if (_dateOfBirth == null) {
      missingFields.add('Date of Birth');
      isValid = false;
    }

    if (_gender.isEmpty) {
      missingFields.add('Gender');
      isValid = false;
    }

    if (_tribe.isEmpty) {
      missingFields.add('Tribe');
      isValid = false;
    }

    if (_bio.isEmpty) {
      missingFields.add('Bio');
      isValid = false;
    }

    if (_interests.isEmpty) {
      missingFields.add('Interests');
      isValid = false;
    }

    if (_height <= 0) {
      missingFields.add('Height');
      isValid = false;
    }

    if (_lookingFor.isEmpty) {
      missingFields.add('Looking For');
      isValid = false;
    }

    if (_relationshipIntent.isEmpty) {
      missingFields.add('Relationship Intent');
      isValid = false;
    }

    if (_interestedIn.isEmpty) {
      missingFields.add('Interested In');
      isValid = false;
    }

    // Location validation - CRITICAL FOR DISCOVERY
    if (_locationName == null || _locationName!.trim().isEmpty) {
      missingFields.add('Location');
      isValid = false;
    }

    // Location coordinates validation - CRITICAL FOR DISCOVERY
    if (_latitude == null || _longitude == null) {
      missingFields.add('Location Coordinates');
      isValid = false;
    }

    // Check if at least one photo is uploaded
    bool hasPhotos = _profilePhotos.any((photo) => photo != null);
    if (!hasPhotos) {
      missingFields.add('Profile Photos');
      isValid = false;
    }

    if (isValid) {
      AppLogger.info('✅ All required onboarding data is present');
      AppLogger.debug('   Name: $_fullName');
      AppLogger.debug('   Age: $age years old');
      AppLogger.debug('   Gender: $_gender');
      AppLogger.debug('   Location: ${_locationName ?? 'Not set'}');
      AppLogger.debug('   Tribe: $_tribe');
      AppLogger.debug('   Bio: ${_bio.length} characters');
      AppLogger.debug('   Interests: ${_interests.length} selected');
      AppLogger.debug('   Height: $_height cm (${_getHeightFtIn()})');
      AppLogger.debug('   Looking for: $_lookingFor');
      AppLogger.debug('   Relationship intent: $_relationshipIntent');
      AppLogger.debug('   Interested in: $_interestedIn');
      AppLogger.debug('   Age range: ${_ageRange[0]}-${_ageRange[1]}');
      AppLogger.debug(
          '   Photos: ${_profilePhotos.where((p) => p != null).length} uploaded');
    } else {
      AppLogger.warning('❌ Missing required fields: ${missingFields.join(', ')}');
    }

    return isValid;
  }

  // Method to get a summary of all onboarding data for debugging
  Map<String, dynamic> getOnboardingDataSummary() {
    return {
      'fullName': _fullName,
      'age': age,
      'gender': _gender,
      'location': _locationName,
      'tribe': _tribe,
      'bioLength': _bio.length,
      'interestsCount': _interests.length,
      'interests': _interests,
      'height': _height,
      'heightDisplay': _getHeightFtIn(),
      'lookingFor': _lookingFor,
      'relationshipIntent': _relationshipIntent,
      'interestedIn': _interestedIn,
      'ageRange': _ageRange,
      'photosCount': _profilePhotos.where((p) => p != null).length,
      'hasAllRequiredData': validateOnboardingData(),
    };
  }
}
