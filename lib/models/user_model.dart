// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel {
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

  List? imageUrl = [];
  int? distanceBW;
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

  });

  @override
  String toString() {
    return 'UserModel{id: \$id, name: \$name, age: \$age, phone: \$phoneNumber}';
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    try {
      // Get the document ID as the user ID
      final String userId = doc.id;
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
      
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
      T? safeGetNested<T>(String parentKey, String childKey, [T? defaultValue]) {
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
        latitude: locationData['latitude'] is num ? (locationData['latitude'] as num).toDouble() : 0.0,
        longitude: locationData['longitude'] is num ? (locationData['longitude'] as num).toDouble() : 0.0,
        coordinates: locationData.isNotEmpty ? locationData : {},
        currentCoordinates: data.containsKey('currentLocation') && data['currentLocation'] is Map
            ? data['currentLocation'] as Map
            : locationData.isNotEmpty ? locationData : {},
        sexualOrientation: data.containsKey('sexualOrientation') && data['sexualOrientation'] is Map
            ? data['sexualOrientation'] as Map
            : {},
        userGender: safeGet<String>('gender') ?? 
                   safeGetNested<String>('editInfo', 'userGender', ''),
        company: safeGetNested<String>('editInfo', 'company', ''),
        job_title: safeGetNested<String>('editInfo', 'job_title', ''),
        living_in: safeGetNested<String>('editInfo', 'living_in', ''),
        showMyAge: safeGetNested<bool>('editInfo', 'showMyAge', false),
        showGender: safeGet<String>('showGender', ''),
        age: safeGet<int>('age', 18),
        phoneNumber: safeGet<String>('phoneNumber', ''),
        maxDistance: safeGet<int>('maximum_distance', 10),
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
        latitude: 0.0,
        longitude: 0.0,
        address: '',
        imageUrl: [],
        editInfo: {},
      );
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        // Use the document ID as the user ID if available, otherwise fall back to 'userId'
        id: json['id'] ?? json['userId'] ?? "",
        name: json['name'] ?? json['UserName'] ?? "",
        isBlocked: json['isBlocked'] ?? false,
        address: json['location'] != null ? json['location']['address'] ?? "" : "",
        latitude: json['location'] != null ? json['location']['latitude'] ?? 0 : 0,
        longitude: json['location'] != null ? json['location']['longitude'] ?? 0 : 0,
        coordinates: json['coordinates'] ?? {},
        currentCoordinates: json['currentCoordinates'],
        sexualOrientation: json['sexualOrientation'],
        userGender: json['gender'] ?? (json['editInfo'] != null ? json['editInfo']['userGender'] : null),
        living_in: json['living_in'],
        job_title: json['job_title'],
        company: json['company'],
        showMyAge: json['showMyAge'],
        showGender: json['showGender'],
        age: json['age'],
        phoneNumber: json['phoneNumber'],
        maxDistance: json['maximum_distance'] ?? 10,
        ageRange: json['age_range'] ?? (json['preferences'] != null ? 
            {'min': json['preferences']['ageRange'][0], 'max': json['preferences']['ageRange'][1]} : null),
        editInfo: json['editInfo'],
        streetView: json['streetView'],
        imageUrl: json['photos'] ?? json['Pictures'],
        distanceBW: json['distanceBW'] != null
            ? (json['distanceBW'] as num).round()
            : null,
        isBot: json['isBot'] ?? false,
    );
  }

  static UserModel convertStringToUserModel(String userString) {
    final userMap = jsonDecode(userString);
    return UserModel.fromJson(userMap);
  }
}
