import 'package:flutter/material.dart';

/// Controller for managing onboarding data across multiple screens.
/// 
/// This controller maintains state for all onboarding steps including
/// personal information, cultural preferences, and lifestyle choices.
class OnboardingController extends ChangeNotifier {
  // Singleton instance
  static final OnboardingController _instance = OnboardingController._internal();
  
  factory OnboardingController() {
    return _instance;
  }
  
  OnboardingController._internal();
  
  // Basic user information
  String? userName;
  DateTime? dateOfBirth;
  String? gender;
  
  // Cultural information
  String? tribe;
  List<String> languages = [];
  String? nationality;
  bool isDiaspora = false;
  
  // Intent and preferences
  String? intent; // Dating, Friendship, Community
  
  // Lifestyle preferences
  List<String> genres = []; // Music, movies, etc.
  String? fashionStyle;
  String? weekendVibe;
  
  // Values and dealbreakers
  List<String> values = [];
  List<String> dealbreakers = [];
  
  // Location information
  double? latitude;
  double? longitude;
  String? locationName;
  
  // Profile information
  List<String> photos = [];
  String? bio;
  String? occupation;
  String? education;
  
  // Validation methods for different steps
  
  /// Validates basic information (name, DOB, gender)
  bool isValidStepBasic() {
    return userName != null && 
           userName!.isNotEmpty && 
           dateOfBirth != null && 
           gender != null;
  }
  
  /// Validates cultural information
  bool isValidStepCultural() {
    return nationality != null && 
           nationality!.isNotEmpty;
  }
  
  /// Validates intent and preferences
  bool isValidStepIntent() {
    return intent != null && intent!.isNotEmpty;
  }
  
  /// Validates lifestyle preferences
  bool isValidStepLifestyle() {
    return genres.isNotEmpty || 
           fashionStyle != null || 
           weekendVibe != null;
  }
  
  /// Validates values and dealbreakers
  bool isValidStepValues() {
    return values.isNotEmpty;
  }
  
  /// Validates location information
  bool isValidStepLocation() {
    return latitude != null && 
           longitude != null && 
           locationName != null;
  }
  
  /// Validates profile information
  bool isValidStepProfile() {
    return photos.isNotEmpty;
  }
  
  /// Checks if all required steps are completed
  bool isOnboardingComplete() {
    return isValidStepBasic() && 
           isValidStepCultural() && 
           isValidStepIntent() && 
           isValidStepLocation();
  }
  
  /// Updates user name and notifies listeners
  void updateUserName(String name) {
    userName = name;
    notifyListeners();
  }
  
  /// Updates date of birth and notifies listeners
  void updateDateOfBirth(DateTime dob) {
    dateOfBirth = dob;
    notifyListeners();
  }
  
  /// Updates gender and notifies listeners
  void updateGender(String selectedGender) {
    gender = selectedGender;
    notifyListeners();
  }
  
  /// Updates tribe and notifies listeners
  void updateTribe(String selectedTribe) {
    tribe = selectedTribe;
    notifyListeners();
  }
  
  /// Updates nationality and notifies listeners
  void updateNationality(String selectedNationality, bool diaspora) {
    nationality = selectedNationality;
    isDiaspora = diaspora;
    notifyListeners();
  }
  
  /// Updates languages and notifies listeners
  void updateLanguages(List<String> selectedLanguages) {
    languages = selectedLanguages;
    notifyListeners();
  }
  
  /// Updates intent and notifies listeners
  void updateIntent(String selectedIntent) {
    intent = selectedIntent;
    notifyListeners();
  }
  
  /// Updates genres and notifies listeners
  void updateGenres(List<String> selectedGenres) {
    genres = selectedGenres;
    notifyListeners();
  }
  
  /// Updates fashion style and notifies listeners
  void updateFashionStyle(String style) {
    fashionStyle = style;
    notifyListeners();
  }
  
  /// Updates weekend vibe and notifies listeners
  void updateWeekendVibe(String vibe) {
    weekendVibe = vibe;
    notifyListeners();
  }
  
  /// Updates values and notifies listeners
  void updateValues(List<String> selectedValues) {
    values = selectedValues;
    notifyListeners();
  }
  
  /// Updates dealbreakers and notifies listeners
  void updateDealbreakers(List<String> selectedDealbreakers) {
    dealbreakers = selectedDealbreakers;
    notifyListeners();
  }
  
  /// Updates location and notifies listeners
  void updateLocation(double lat, double lng, String name) {
    latitude = lat;
    longitude = lng;
    locationName = name;
    notifyListeners();
  }
  
  /// Updates photos and notifies listeners
  void updatePhotos(List<String> photoUrls) {
    photos = photoUrls;
    notifyListeners();
  }
  
  /// Updates bio and notifies listeners
  void updateBio(String userBio) {
    bio = userBio;
    notifyListeners();
  }
  
  /// Updates occupation and notifies listeners
  void updateOccupation(String userOccupation) {
    occupation = userOccupation;
    notifyListeners();
  }
  
  /// Updates education and notifies listeners
  void updateEducation(String userEducation) {
    education = userEducation;
    notifyListeners();
  }
  
  /// Converts controller data to a Map for storage or API calls
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'tribe': tribe,
      'languages': languages,
      'nationality': nationality,
      'isDiaspora': isDiaspora,
      'intent': intent,
      'genres': genres,
      'fashionStyle': fashionStyle,
      'weekendVibe': weekendVibe,
      'values': values,
      'dealbreakers': dealbreakers,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'photos': photos,
      'bio': bio,
      'occupation': occupation,
      'education': education,
    };
  }
  
  /// Loads data from a Map into the controller
  void fromMap(Map<String, dynamic> data) {
    userName = data['userName'];
    dateOfBirth = data['dateOfBirth'] != null 
        ? DateTime.parse(data['dateOfBirth']) 
        : null;
    gender = data['gender'];
    tribe = data['tribe'];
    languages = List<String>.from(data['languages'] ?? []);
    nationality = data['nationality'];
    isDiaspora = data['isDiaspora'] ?? false;
    intent = data['intent'];
    genres = List<String>.from(data['genres'] ?? []);
    fashionStyle = data['fashionStyle'];
    weekendVibe = data['weekendVibe'];
    values = List<String>.from(data['values'] ?? []);
    dealbreakers = List<String>.from(data['dealbreakers'] ?? []);
    latitude = data['latitude'];
    longitude = data['longitude'];
    locationName = data['locationName'];
    photos = List<String>.from(data['photos'] ?? []);
    bio = data['bio'];
    occupation = data['occupation'];
    education = data['education'];
    notifyListeners();
  }
  
  /// Resets all controller data
  void reset() {
    userName = null;
    dateOfBirth = null;
    gender = null;
    tribe = null;
    languages = [];
    nationality = null;
    isDiaspora = false;
    intent = null;
    genres = [];
    fashionStyle = null;
    weekendVibe = null;
    values = [];
    dealbreakers = [];
    latitude = null;
    longitude = null;
    locationName = null;
    photos = [];
    bio = null;
    occupation = null;
    education = null;
    notifyListeners();
  }
}
