// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  UserModel({
    this.living_in,
    this.job_title,
    this.company,
    this.showMyAge,
    this.id,
    this.age,
    this.address,
    this.isBot,
    this.latitude,
    this.longitude,
    this.isBlocked,
    this.coordinates,
    this.currentCoordinates,
    this.name,
    this.imageUrl,
    this.phoneNumber,
    this.lastmsg,
    this.userGender,
    this.showGender,
    this.ageRange,
    this.maxDistance,
    this.editInfo,
    this.streetView,
    this.distanceBW,
    this.sexualOrientation,
    this.bio,
    this.profession,
    this.education,
    this.drinkingStatus,
    this.smokingStatus,
    this.lastSeen,
    this.lookingFor,
    // Cultural fields
    this.nationality,
    this.tribe,
    this.languages,
    this.religion,
    this.occupation,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    try {
      // Get the document ID as the user ID
      final String userId = doc.id;
      final Map<String, dynamic> data =
          doc.data() as Map<String, dynamic>? ?? {};

      // Helper function to safely get values
      T? safeGet<T>(String key, [T? defaultValue]) {
        try {
          if (data.containsKey(key)) {
            final value = data[key];
            if (value is T) return value;
            if (T == String && value != null) return value.toString() as T;
            if (T == int && value is String) return int.tryParse(value) as T?;
            if (T == double && value is num) return value.toDouble() as T;
          }
          return defaultValue;
        } catch (e) {
          debugPrint('Error getting $key: $e');
          return defaultValue;
        }
      }

      // Helper function to safely get nested values
      T? safeGetNested<T>(String parentKey, String childKey,
          [T? defaultValue,]) {
        try {
          if (data.containsKey(parentKey) && data[parentKey] is Map) {
            final parent = data[parentKey] as Map;
            if (parent.containsKey(childKey)) {
              final value = parent[childKey];
              if (value is T) return value;
              if (T == String && value != null) return value.toString() as T;
              if (T == int && value is String) return int.tryParse(value) as T?;
              if (T == double && value is num) return value.toDouble() as T;
            }
          }
          return defaultValue;
        } catch (e) {
          debugPrint('Error getting $parentKey.$childKey: $e');
          return defaultValue;
        }
      }

      // Handle age range with proper type conversion
      Map<String, String> getAgeRange() {
        try {
          if (data.containsKey('age_range') && data['age_range'] is Map) {
            final ageRange = data['age_range'] as Map;
            return {
              'min': (ageRange['min'] ?? 18).toString(),
              'max': (ageRange['max'] ?? 50).toString(),
            };
          } else if (data.containsKey('preferences') &&
              data['preferences'] is Map &&
              data['preferences']['ageRange'] is List) {
            final ageRangeList = data['preferences']['ageRange'] as List;
            if (ageRangeList.length >= 2) {
              return {
                'min': ageRangeList[0].toString(),
                'max': ageRangeList[1].toString(),
              };
            }
          }
          return {'min': '18', 'max': '50'};
        } catch (e) {
          debugPrint('Error parsing age range: $e');
          return {'min': '18', 'max': '50'};
        }
      }

      // Handle location data
      Map<String, dynamic> getLocationData() {
        try {
          if (data.containsKey('location') && data['location'] is Map) {
            return data['location'] as Map<String, dynamic>;
          }
          return {};
        } catch (e) {
          debugPrint('Error getting location: $e');
          return {};
        }
      }

      final locationData = getLocationData();

      return UserModel(
        id: userId,
        name: safeGet<String>('name', ''),
        isBlocked: safeGet<bool>('isBlocked', false),
        address: locationData['address']?.toString() ?? '',
        latitude: locationData['latitude'] is num
            ? (locationData['latitude'] as num).toDouble()
            : 0.0,
        longitude: locationData['longitude'] is num
            ? (locationData['longitude'] as num).toDouble()
            : 0.0,
        coordinates: locationData.isNotEmpty ? locationData : {},
        currentCoordinates: data.containsKey('currentLocation') &&
                data['currentLocation'] is Map
            ? data['currentLocation'] as Map
            : locationData.isNotEmpty
                ? locationData
                : {},
        sexualOrientation: data.containsKey('sexualOrientation') &&
                data['sexualOrientation'] is Map
            ? data['sexualOrientation'] as Map
            : {},
        userGender: safeGet<String>('gender') ??
            safeGet<String>('userGender') ??
            safeGetNested<String>('editInfo', 'userGender', ''),
        company: safeGetNested<String>('editInfo', 'company', ''),
        job_title: safeGetNested<String>('editInfo', 'job_title', ''),
        living_in: safeGetNested<String>('editInfo', 'living_in', ''),
        showMyAge: safeGetNested<bool>('editInfo', 'showMyAge', false),
        showGender: safeGet<String>('showGender', ''),
        age: safeGet<int>('age', 18),
        phoneNumber: safeGet<String>('phoneNumber', ''),
        maxDistance: safeGet<int>('maximum_distance', 10) ??
            safeGet<int>('maxDistance', 10),
        ageRange: getAgeRange(),
        editInfo: data.containsKey('editInfo') && data['editInfo'] is Map
            ? data['editInfo'] as Map
            : {},
        streetView: data.containsKey('streetView') && data['streetView'] is Map
            ? data['streetView'] as Map
            : {},
        isBot: safeGet<bool>('isBot', false),
        imageUrl: data.containsKey('photos') && data['photos'] is List
            ? List<String>.from(data['photos'])
            : data.containsKey('Pictures') && data['Pictures'] is List
                ? List<String>.from(data['Pictures'])
                : [],
        bio: safeGet<String>('bio') ??
            safeGetNested<String>('editInfo', 'bio', ''),
        profession: safeGet<String>('profession') ??
            safeGetNested<String>('editInfo', 'profession', '') ??
            safeGetNested<String>('editInfo', 'job_title', ''),
        education: safeGet<String>('education') ??
            safeGetNested<String>('editInfo', 'education', ''),
        drinkingStatus: safeGet<String>('drinkingStatus') ??
            safeGetNested<String>('editInfo', 'drinkingStatus', ''),
        smokingStatus: safeGet<String>('smokingStatus') ??
            safeGetNested<String>('editInfo', 'smokingStatus', ''),
        lastSeen: data.containsKey('lastSeen') && data['lastSeen'] is Timestamp
            ? (data['lastSeen'] as Timestamp).toDate()
            : data.containsKey('lastActive') && data['lastActive'] is Timestamp
                ? (data['lastActive'] as Timestamp).toDate()
                : null,
        lookingFor: safeGet<String>('lookingFor') ??
            safeGetNested<String>('editInfo', 'lookingFor', 'Dating'),
        // Cultural fields
        nationality: safeGet<String>('nationality') ??
            safeGetNested<String>('editInfo', 'nationality', ''),
        tribe: safeGet<String>('tribe') ??
            safeGetNested<String>('editInfo', 'tribe', ''),
        languages: data.containsKey('languages') && data['languages'] is List
            ? List<String>.from(data['languages'])
            : [],
        religion: safeGet<String>('religion') ??
            safeGetNested<String>('editInfo', 'religion', ''),
        occupation: safeGet<String>('occupation') ??
            safeGetNested<String>('editInfo', 'occupation', ''),
      );
    } catch (e) {
      debugPrint('Error creating UserModel from document ${doc.id}: $e');
      // Return a minimal user model to prevent crashes
      return UserModel(
        id: doc.id,
        name: 'Unknown User',
        age: 18,
        isBlocked: false,
        showGender: 'everyone',
        ageRange: {'min': '18', 'max': '50'},
        maxDistance: 10,
        latitude: 0,
        longitude: 0,
        address: '',
        imageUrl: [],
        editInfo: {},
        bio: '',
        profession: '',
        education: '',
        drinkingStatus: '',
        smokingStatus: '',
        lookingFor: 'Dating',
        // Cultural fields
        nationality: '',
        tribe: '',
        languages: [],
        religion: '',
        occupation: '',
      );
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
      // Use the document ID as the user ID if available, otherwise fall back to 'userId'
      id: json['id'] ?? json['userId'] ?? '',
      name: json['name'] ?? json['UserName'] ?? '',
      isBlocked: json['isBlocked'] ?? false,
      address:
          json['location'] != null ? json['location']['address'] ?? '' : '',
      latitude:
          json['location'] != null ? json['location']['latitude'] ?? 0 : 0,
      longitude:
          json['location'] != null ? json['location']['longitude'] ?? 0 : 0,
      coordinates: json['coordinates'] ?? {},
      currentCoordinates: json['currentCoordinates'],
      sexualOrientation: json['sexualOrientation'],
      userGender: json['gender'] ??
          (json['editInfo'] != null ? json['editInfo']['userGender'] : null),
      living_in: json['living_in'],
      job_title: json['job_title'],
      company: json['company'],
      showMyAge: json['showMyAge'],
      showGender: json['showGender'],
      age: json['age'],
      phoneNumber: json['phoneNumber'],
      maxDistance: json['maximum_distance'] ?? 10,
      ageRange: json['age_range'] ??
          (json['preferences'] != null
              ? {
                  'min': json['preferences']['ageRange'][0],
                  'max': json['preferences']['ageRange'][1],
                }
              : null),
      editInfo: json['editInfo'],
      streetView: json['streetView'],
      imageUrl: json['photos'] is List
          ? List<String>.from(json['photos'].map((e) => e?.toString() ?? '').where((url) => url.isNotEmpty))
          : json['Pictures'] is List
              ? List<String>.from(json['Pictures'].map((e) => e?.toString() ?? '').where((url) => url.isNotEmpty))
              : [],
      distanceBW: json['distanceBW'] != null
          ? (json['distanceBW'] as num).round()
          : null,
      isBot: json['isBot'] ?? false,
      bio: json['bio'] ??
          (json['editInfo'] != null ? json['editInfo']['bio'] : null),
      profession: json['profession'] ??
          (json['editInfo'] != null ? json['editInfo']['profession'] : null),
      education: json['education'] ??
          (json['editInfo'] != null ? json['editInfo']['education'] : null),
      drinkingStatus: json['drinkingStatus'] ??
          (json['editInfo'] != null
              ? json['editInfo']['drinkingStatus']
              : null),
      smokingStatus: json['smokingStatus'] ??
          (json['editInfo'] != null ? json['editInfo']['smokingStatus'] : null),
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : json['lastActive'] != null
              ? DateTime.tryParse(json['lastActive'].toString())
              : null,
      lookingFor: json['lookingFor'] ??
          (json['editInfo'] != null
              ? json['editInfo']['lookingFor']
              : 'Dating'),
      // Cultural fields
      nationality: json['nationality'] ??
          (json['editInfo'] != null ? json['editInfo']['nationality'] : null),
      tribe: json['tribe'] ??
          (json['editInfo'] != null ? json['editInfo']['tribe'] : null),
      languages: json['languages'] != null && json['languages'] is List
          ? List<String>.from(json['languages'])
          : [],
      religion: json['religion'] ??
          (json['editInfo'] != null ? json['editInfo']['religion'] : null),
      occupation: json['occupation'] ??
          (json['editInfo'] != null ? json['editInfo']['occupation'] : null),
    );

  /// Create UserModel from Map (for caching)
  factory UserModel.fromMap(Map<String, dynamic> map, String userId) => UserModel(
      id: userId,
      name: map['name']?.toString(),
      isBlocked: map['isBlocked'] as bool? ?? false,
      address: map['address']?.toString(),
      latitude:
          map['latitude'] is num ? (map['latitude'] as num).toDouble() : null,
      longitude:
          map['longitude'] is num ? (map['longitude'] as num).toDouble() : null,
      coordinates: map['coordinates'] as Map?,
      currentCoordinates: map['currentCoordinates'] as Map?,
      sexualOrientation: map['sexualOrientation'] as Map?,
      userGender: map['gender']?.toString(),
      living_in: map['living_in']?.toString(),
      job_title: map['job_title']?.toString(),
      company: map['company']?.toString(),
      showMyAge: map['showMyAge'] as bool?,
      showGender: map['showGender']?.toString(),
      age: map['age'] is num ? (map['age'] as num).toInt() : null,
      phoneNumber: map['phoneNumber']?.toString(),
      maxDistance: map['maximum_distance'] is num
          ? (map['maximum_distance'] as num).toInt()
          : null,
      ageRange: map['age_range'] as Map?,
      editInfo: map['editInfo'] as Map?,
      streetView: map['streetView'] as Map?,
      isBot: map['isBot'] as bool? ?? false,
      imageUrl: map['photos'] is List
          ? List<String>.from((map['photos'] as List).map((e) => e?.toString() ?? '').where((url) => url.isNotEmpty))
          : null,
      distanceBW:
          map['distanceBW'] is num ? (map['distanceBW'] as num).toInt() : null,
      bio: map['bio']?.toString(),
      profession: map['profession']?.toString(),
      education: map['education']?.toString(),
      drinkingStatus: map['drinkingStatus']?.toString(),
      smokingStatus: map['smokingStatus']?.toString(),
      lastSeen: map['lastSeen'] != null
          ? DateTime.tryParse(map['lastSeen'].toString())
          : null,
      lookingFor: map['lookingFor']?.toString() ?? 'Dating',
      // Cultural fields
      nationality: map['nationality']?.toString(),
      tribe: map['tribe']?.toString(),
      languages:
          map['languages'] is List ? List<String>.from(map['languages']) : [],
      religion: map['religion']?.toString(),
      occupation: map['occupation']?.toString(),
    );
  final String? id;
  final String? name;
  final bool? isBlocked;
  String? address;
  final double? latitude;
  final double? longitude;
  final Map? coordinates;
  final Map? currentCoordinates;
  final Map? sexualOrientation;
  final String? userGender;
  final String? living_in;
  final String? job_title;
  final String? company;
  final bool? showMyAge;
  String? showGender;
  final int? age;
  final String? phoneNumber;
  int? maxDistance;
  Timestamp? lastmsg;
  Map? ageRange;
  final Map? editInfo;
  final Map? streetView;
  final bool? isBot;
  final String? bio;
  final String? profession;
  final String? education;
  final String? drinkingStatus;
  final String? smokingStatus;
  final DateTime? lastSeen;
  final String?
      lookingFor; // What the user is looking for: Dating, Friendship, Networking

  // Cultural fields
  final String? nationality;
  final String? tribe;
  final List<String>? languages;
  final String? religion;
  final String? occupation;

  List? imageUrl = [];
  int? distanceBW;

  @override
  String toString() => 'UserModel{id: $id, name: $name, age: $age, phone: $phoneNumber}';

  static UserModel convertStringToUserModel(String userString) {
    final userMap = jsonDecode(userString);
    return UserModel.fromJson(userMap);
  }

  // Add missing methods for compatibility with new services

  /// Convert UserModel to Map for caching and storage
  Map<String, dynamic> toMap() => {
      'id': id,
      'name': name,
      'isBlocked': isBlocked,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'coordinates': coordinates,
      'currentCoordinates': currentCoordinates,
      'sexualOrientation': sexualOrientation,
      'gender': userGender,
      'living_in': living_in,
      'job_title': job_title,
      'company': company,
      'showMyAge': showMyAge,
      'showGender': showGender,
      'age': age,
      'phoneNumber': phoneNumber,
      'maximum_distance': maxDistance,
      'age_range': ageRange,
      'editInfo': editInfo,
      'streetView': streetView,
      'isBot': isBot,
      'photos': imageUrl,
      'distanceBW': distanceBW,
      'bio': bio,
      'profession': profession,
      'education': education,
      'drinkingStatus': drinkingStatus,
      'smokingStatus': smokingStatus,
      'lastSeen': lastSeen?.toIso8601String(),
      'lookingFor': lookingFor,
      // Cultural fields
      'nationality': nationality,
      'tribe': tribe,
      'languages': languages,
      'religion': religion,
      'occupation': occupation,
    };

  // Add missing getters for compatibility with new services

  /// Get user's gender
  String? get gender => userGender;

  /// Get minimum age preference
  int? get ageRangeMin {
    if (ageRange != null && ageRange!['min'] != null) {
      if (ageRange!['min'] is int) return ageRange!['min'] as int;
      if (ageRange!['min'] is String) {
        return int.tryParse(ageRange!['min'] as String);
      }
    }
    return 18; // Default minimum age
  }

  /// Get maximum age preference
  int? get ageRangeMax {
    if (ageRange != null && ageRange!['max'] != null) {
      if (ageRange!['max'] is int) return ageRange!['max'] as int;
      if (ageRange!['max'] is String) {
        return int.tryParse(ageRange!['max'] as String);
      }
    }
    return 50; // Default maximum age
  }

  /// Get distance range preference
  int? get distanceRange => maxDistance;
}
