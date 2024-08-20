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
  // ignore: prefer_typing_uninitialized_variables
  var distanceBW;
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
    return 'User: {id: $id,name:$name, isBlocked: $isBlocked, address: $address, coordinates: $coordinates,currentCoordinates :$currentCoordinates,  sexualOrientation: $sexualOrientation, gender: $userGender, showGender: $showGender, age: $age, phoneNumber: $phoneNumber, maxDistance: $maxDistance, lastmsg: $lastmsg, ageRange: $ageRange, editInfo: $editInfo, streetView: $streetView ,  distanceBW : $distanceBW, isBot:$isBot }';
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel(
      id: doc.get('userId'),
      name:
          doc.data().toString().contains('UserName') ? doc.get('UserName') : "",
      isBlocked: doc.get('isBlocked') ?? false,
      address: doc.data().toString().contains('location')
          ? doc.get('location')['address'] ?? ""
          : '',
      latitude: doc.data().toString().contains('location')
          ? doc.get('location')['latitude'] ?? 0
          : 0,
      longitude: doc.data().toString().contains('location')
          ? doc.get('location')['longitude'] ?? 0
          : 0,
      coordinates: doc.get('location') ?? {},
      currentCoordinates: doc.data().toString().contains('currentLocation')
          ? doc.get('currentLocation')
          : doc.data().toString().contains('location')
              ? doc.get('location') ?? {}
              : {},
      sexualOrientation: doc.data().toString().contains('sexualOrientation')
          ? doc.get('sexualOrientation')
          : {},

      userGender: doc.data().toString().contains('editInfo')
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
      imageUrl: doc.get('Pictures') != null
          ? List.generate(doc.get('Pictures').length, (index) {
              return doc.get('Pictures')[index];
            })
          : [],
      // distanceBW: doc.get('distanceBW') ?? 0,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        id: json['userId'] ?? "",
        name: json['UserName'] ?? "",
        isBlocked: json['isBlocked'] ?? false,
        address: json['location']['address'] ?? "",
        latitude: json['location']['latitude'] ?? 0,
        longitude: json['location']['longitude'] ?? 0,
        coordinates: json['coordinates'] ?? {},
        currentCoordinates: json['currentCoordinates'],
        sexualOrientation: json['sexualOrientation'],
        userGender: json['editInfo']['userGender'],
        living_in: json['living_in'],
        job_title: json['job_title'],
        company: json['company'],
        showMyAge: json['showMyAge'],
        showGender: json['showGender'],
        age: json['age'],
        phoneNumber: json['phoneNumber'],
        maxDistance: json['maximum_distance'] ?? 10,
        ageRange: json['age_range'],
        editInfo: json['editInfo'],
        streetView: json['streetView'],
        imageUrl: json['Pictures'],
        distanceBW: json['distanceBW'] ?? 0,
        isBot: json['isBot'] ?? false);
  }

  static UserModel convertStringToUserModel(String userString) {
    final userMap = jsonDecode(userString);
    return UserModel.fromJson(userMap);
  }
}
