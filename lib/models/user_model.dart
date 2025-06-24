// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Get the document ID as the user ID
    final String userId = doc.id;
    
    return UserModel(
      id: userId,
      name: doc.data().toString().contains('name') ? doc.get('name') : "",
      isBlocked: doc.get('isBlocked') ?? false,
      address: doc.data().toString().contains('location')
          ? doc.get('location')['address'] ?? ""
          : '',
      latitude: doc.data().toString().contains('location') && doc.get('location') != null
          ? (doc.get('location')['latitude'] ?? 0.0)
          : 0.0,
      longitude: doc.data().toString().contains('location') && doc.get('location') != null
          ? (doc.get('location')['longitude'] ?? 0.0)
          : 0.0,
      coordinates: doc.data().toString().contains('location') 
          ? (doc.get('location') ?? {})
          : {},
      currentCoordinates: doc.data().toString().contains('currentLocation')
          ? (doc.get('currentLocation') ?? {})
          : doc.data().toString().contains('location') && doc.get('location') != null
              ? (doc.get('location') ?? {})
              : {},
      sexualOrientation: doc.data().toString().contains('sexualOrientation')
          ? doc.get('sexualOrientation')
          : {},

      userGender: doc.data().toString().contains('gender')
          ? doc.get('gender') ?? ''
          : doc.data().toString().contains('editInfo')
              ? doc.get('editInfo')['userGender'] ?? ''
              : "",
      company: doc.data().toString().contains('editInfo')
          ? doc.get('editInfo')['company'] ?? ''
          : "",
      job_title: doc.data().toString().contains('editInfo')
          ? doc.get('editInfo')['job_title'] ?? ''
          : "",
      living_in: doc.data().toString().contains('editInfo')
          ? doc.get('editInfo')['living_in'] ?? ''
          : "",
      showMyAge: doc.data().toString().contains('editInfo')
          ? doc.get('editInfo')['showMyAge'] ?? false
          : false,

      showGender: doc.data().toString().contains('showGender')
          ? doc.get('showGender') ?? ''
          : "",
      age: doc.data().toString().contains('age') ? doc.get('age') ?? 18 : 18,
      phoneNumber: doc.data().toString().contains('phoneNumber')
          ? doc.get('phoneNumber') ?? ''
          : "",
      maxDistance: doc.data().toString().contains('maximum_distance')
          ? doc.get('maximum_distance') ?? 10
          : 10,
      ageRange: doc.data().toString().contains('age_range')
          ? doc.get('age_range')
          : doc.data().toString().contains('preferences') && 
            doc.get('preferences') is Map && 
            doc.get('preferences').containsKey('ageRange')
              ? {'min': doc.get('preferences')['ageRange'][0], 'max': doc.get('preferences')['ageRange'][1]}
              : {},
      editInfo: doc.data().toString().contains('editInfo')
          ? doc.get('editInfo') ?? {}
          : {},
      streetView: doc.data().toString().contains('streetView')
          ? doc.get('streetView')
          : {},
      isBot: doc.data().toString().contains('isBot')
          ? doc.get('isBot') ?? false
          : false,

      // Check for both 'photos' (new field) and 'Pictures' (old field)
      imageUrl: doc.data().toString().contains('photos')
          ? doc.get('photos')
          : doc.data().toString().contains('Pictures')
              ? List.generate(doc.get('Pictures').length, (index) {
                  return doc.get('Pictures')[index];
                })
              : [],
    );
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
