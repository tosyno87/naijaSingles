import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer';
import '../../../common/widgets/loading_transition_screen.dart';

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
  String _relationshipIntent = 'Not sure yet'; // Short-term, Long-term, Casual, Not sure yet

  // Getters for basic data
  String get fullName => _fullName;
  DateTime? get dateOfBirth => _dateOfBirth;
  String get gender => _gender;
  String get tribe => _tribe;
  String get bio => _bio;
  List<String> get interests => _interests;
  List<File?> get profilePhotos => _profilePhotos;
  bool get isLoading => _isLoading;
  
  // Legacy getter for backward compatibility
  File? get profilePhoto => _profilePhotos.firstWhere((photo) => photo != null, orElse: () => null);
  
  // Getters for additional data
  String? get userName => _userName;
  String? get locationName => _locationName;
  String? get intent => _intent;
  String? get nationality => _nationality;
  String? get education => _education;
  String? get occupation => _occupation;
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
    return _bio.length >= 20; // Minimum bio length
  }

  bool areInterestsSelected() {
    return _interests.isNotEmpty;
  }

  bool isPhotoUploaded() {
    // Require at least 3 photos
    int photoCount = _profilePhotos.where((photo) => photo != null).length;
    return photoCount >= 3;
  }

  // Photo selection for a specific index
  Future<void> pickProfilePhoto(ImageSource source, int index) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (image != null) {
        _profilePhotos[index] = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      log("Error picking image: $e");
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
      print('🔍 Validating onboarding data before save...');
      bool isDataValid = validateOnboardingData();
      
      if (!isDataValid) {
        print('❌ Onboarding data validation failed - some required fields are missing');
        // Still proceed with save but log the issues
      }
      
      // Print data summary for debugging
      final summary = getOnboardingDataSummary();
      print('📊 Onboarding Data Summary: $summary');
      
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
            print('❌ Error navigating after timeout: $e');
          }
        }
      });
      
      // First, save essential user data (fast operation)
      await _saveEssentialUserData(user.uid);
      
      // If we haven't timed out yet, navigate now that essential data is saved
      if (!timeoutReached && context != null && context.mounted) {
        try {
          _navigateToMainScreen(context);
        } catch (e) {
          print('❌ Error navigating after save: $e');
        }
      }
      
      // Continue with non-essential operations in background
      _uploadProfilePictures(user.uid).then((_) {
        // Update UI if needed when pictures are done uploading
        print('✅ Profile pictures uploaded successfully');
      });
      
      _isLoading = false;
      notifyListeners();
      
      print('✅ User data saved successfully! Navigating to main app...');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      log("Error saving user data: $e");
      
      // If there's an error but context is provided, still navigate
      if (context != null && context.mounted) {
        try {
          _navigateToMainScreen(context);
        } catch (e) {
          print('❌ Error navigating after error: $e');
        }
      }
      
      rethrow;
    }
  }
  
  // Navigate to main screen
  void _navigateToMainScreen(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      '/main_navigation', 
      (route) => false,
    );
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
      'userName': _userName ?? _fullName,
      'locationName': _locationName,
      'intent': _intent,
      'nationality': _nationality,
      'education': _education,
      'occupation': _occupation,
      'fashionStyle': _fashionStyle,
      'weekendVibe': _weekendVibe,
      'languages': _languages,
      'genres': _genres,
      'values': _values,
      'dealbreakers': _dealbreakers,
      
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
      
      // Preferences structure
      'preferences': {
        'interestedIn': _interestedIn,
        'ageRange': _ageRange,
        'lookingFor': _lookingFor,
        'relationshipIntent': _relationshipIntent,
        'maximumDistance': 50,
      },
      
      // Legacy preference fields
      'showGender': _interestedIn,
      'ageRange': {
        'min': _ageRange[0].toString(),
        'max': _ageRange[1].toString(),
      },
      
      // Location information
      'location': {
        'latitude': 6.5244,
        'longitude': 3.3792,
        'address': _locationName ?? 'Lagos, Nigeria',
      },
      'latitude': 6.5244,
      'longitude': 3.3792,
      'maximum_distance': 50,
      
      // Profile completion status
      'onboardingCompleted': true,
      'profileSetupComplete': true,
    };
    
    // Debug logging to verify all data is being saved
    print('🔍 Saving comprehensive user data:');
    print('   Name: $_fullName');
    print('   Age: $age');
    print('   Gender: $_gender');
    print('   Tribe: $_tribe');
    print('   Bio: ${_bio.length} characters');
    print('   Interests: ${_interests.length} items - $_interests');
    print('   Height: $_height cm (${_getHeightFtIn()})');
    print('   Looking for: $_lookingFor');
    print('   Relationship intent: $_relationshipIntent');
    print('   Interested in: $_interestedIn');
    print('   Age range: $_ageRange');
    print('   Additional fields:');
    print('     Education: $_education');
    print('     Occupation: $_occupation');
    print('     Languages: $_languages');
    print('     Nationality: $_nationality');
    print('   Profile photos: ${_profilePhotos.where((p) => p != null).length} photos');
    
    // Save essential data to Firestore
    print('🔍 Saving essential user data to Firestore...');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(essentialData, SetOptions(merge: true));
    
    // Update display name in Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(_fullName);
    }
    
    print('✅ Essential user data saved successfully');
    print('✅ All onboarding data should now be available in profile');
  }
  
  // Upload profile pictures in the background
  Future<void> _uploadProfilePictures(String userId) async {
    List<String> photoUrls = [];
    List<File> validPhotos = _profilePhotos.whereType<File>().toList();
    
    if (validPhotos.isEmpty) {
      return;
    }
    
    print('📸 Uploading ${validPhotos.length} profile pictures');
    
    try {
      for (int i = 0; i < validPhotos.length; i++) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users/$userId/profile_photo_$i.jpg');
            
        await storageRef.putFile(validPhotos[i]);
        String url = await storageRef.getDownloadURL();
        photoUrls.add(url);
      }
      
      // Update photos list for compatibility
      _photos = photoUrls;
      
      // Update Firestore with photo URLs
      if (photoUrls.isNotEmpty) {
        final photoData = {
          'profilePicture': photoUrls[0],
          'photos': photoUrls,
          'Pictures': photoUrls,
          'imageUrl': photoUrls,
        };
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update(photoData);
      }
    } catch (e) {
      log("Error uploading profile pictures: $e");
      // Don't rethrow - this is a background operation
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
    print('🔍 Validating onboarding data completeness:');
    
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
    
    // Check if at least one photo is uploaded
    bool hasPhotos = _profilePhotos.any((photo) => photo != null);
    if (!hasPhotos) {
      missingFields.add('Profile Photos');
      isValid = false;
    }
    
    if (isValid) {
      print('✅ All required onboarding data is present');
      print('   Name: $_fullName');
      print('   Age: $age years old');
      print('   Gender: $_gender');
      print('   Tribe: $_tribe');
      print('   Bio: ${_bio.length} characters');
      print('   Interests: ${_interests.length} selected');
      print('   Height: $_height cm (${_getHeightFtIn()})');
      print('   Looking for: $_lookingFor');
      print('   Relationship intent: $_relationshipIntent');
      print('   Interested in: $_interestedIn');
      print('   Age range: ${_ageRange[0]}-${_ageRange[1]}');
      print('   Photos: ${_profilePhotos.where((p) => p != null).length} uploaded');
    } else {
      print('❌ Missing required fields: ${missingFields.join(', ')}');
    }
    
    return isValid;
  }

  // Method to get a summary of all onboarding data for debugging
  Map<String, dynamic> getOnboardingDataSummary() {
    return {
      'fullName': _fullName,
      'age': age,
      'gender': _gender,
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
