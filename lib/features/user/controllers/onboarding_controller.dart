import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer';

class OnboardingController extends ChangeNotifier {
  // Basic user data
  String _fullName = '';
  DateTime? _dateOfBirth;
  String _gender = '';
  String _tribe = '';
  String _bio = '';
  List<String> _interests = [];
  File? _profilePhoto;
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

  // Getters for basic data
  String get fullName => _fullName;
  DateTime? get dateOfBirth => _dateOfBirth;
  String get gender => _gender;
  String get tribe => _tribe;
  String get bio => _bio;
  List<String> get interests => _interests;
  File? get profilePhoto => _profilePhoto;
  bool get isLoading => _isLoading;
  
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

  void setProfilePhoto(File photo) {
    _profilePhoto = photo;
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
    return _profilePhoto != null;
  }

  // Photo selection
  Future<void> pickProfilePhoto(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (image != null) {
        _profilePhoto = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      log("Error picking image: $e");
    }
  }

  // Save all user data to Firestore
  Future<void> saveUserData() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }
      
      // Upload profile photo if available
      String? photoUrl;
      if (_profilePhoto != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users/${user.uid}/profile_photo.jpg');
            
        await storageRef.putFile(_profilePhoto!);
        photoUrl = await storageRef.getDownloadURL();
        
        // Update photos list for compatibility
        _photos = [photoUrl];
      }
      
      // Create user data map
      final userData = {
        'userId': user.uid,
        'name': _fullName,
        'userName': _fullName, // For compatibility
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'age': age,
        'gender': _gender,
        'tribe': _tribe,
        'bio': _bio,
        'interests': _interests,
        'genres': _interests, // For compatibility
        'lastActive': DateTime.now().toIso8601String(),
        'isProfileComplete': true,
        'isBlocked': false,
        'isPremium': false,
      };
      
      // Add photo URL if available
      if (photoUrl != null) {
        userData['profilePicture'] = photoUrl;
        userData['photos'] = [photoUrl];
      }
      
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
          
      // Update display name in Firebase Auth
      await user.updateDisplayName(_fullName);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      log("Error saving user data: $e");
      rethrow;
    }
  }
}
