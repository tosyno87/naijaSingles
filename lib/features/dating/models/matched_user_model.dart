import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/utils/firestore_helpers.dart';
import '../../../models/user_model.dart';

/// Model representing a potential match for dating/friendship/networking
class MatchedUser {
  MatchedUser({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.profileImage,
    required this.personality,
    required this.bio,
    required this.interests,
    this.tribe,
    this.profession,
    this.religion,
    this.education,
    this.lookingFor,
    this.lastSeen,
    this.latitude,
    this.longitude,
    this.isOnline,
  });

  /// Create MatchedUser from Firestore document
  factory MatchedUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MatchedUser(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      age: data['age'] ?? 0,
      location: data['living_in'] ?? data['location'] ?? 'Unknown',
      profileImage: (data['imageUrl'] as List?)?.isNotEmpty ?? false
          ? data['imageUrl'][0]
          : 'assets/images/placeholder_profile.jpg',
      tribe: data['tribe'],
      profession: data['profession'] ?? data['job_title'],
      personality: List<String>.from(data['personality'] ?? []),
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      religion: data['religion'],
      education: data['education'],
      lookingFor: data['lookingFor'],
      lastSeen: parseDateTimeOrNull(data['lastSeen']),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isOnline: data['isOnline'],
    );
  }

  /// Create MatchedUser from UserModel
  factory MatchedUser.fromUserModel(UserModel user) => MatchedUser(
        id: user.id ?? '',
        name: user.name ?? 'Unknown',
        age: user.age ?? 0,
        location: user.living_in ?? 'Unknown',
        profileImage: (user.imageUrl?.isNotEmpty ?? false)
            ? user.imageUrl![0]
            : 'assets/images/placeholder_profile.jpg',
        tribe: user.tribe,
        profession: user.profession ?? user.job_title,
        personality: [], // Would need to be added to UserModel
        bio: user.bio ?? '',
        interests: [], // Would need to be added to UserModel
        religion: user.religion,
        education: user.education,
        lookingFor: user.lookingFor,
        lastSeen: user.lastSeen,
        latitude: user.latitude,
        longitude: user.longitude,
        isOnline: false, // Would need to be calculated
      );
  final String id;
  final String name;
  final int age;
  final String location;
  final String profileImage;
  final String? tribe;
  final String? profession;
  final List<String> personality;
  final String bio;
  final List<String> interests;
  final String? religion;
  final String? education;
  final String? lookingFor;
  final DateTime? lastSeen;
  final double? latitude;
  final double? longitude;
  final bool? isOnline;

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'age': age,
        'living_in': location,
        'imageUrl': [profileImage],
        'tribe': tribe,
        'profession': profession,
        'personality': personality,
        'bio': bio,
        'interests': interests,
        'religion': religion,
        'education': education,
        'lookingFor': lookingFor,
        'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
        'latitude': latitude,
        'longitude': longitude,
        'isOnline': isOnline,
      };

  /// Create a copy with updated fields
  MatchedUser copyWith({
    String? id,
    String? name,
    int? age,
    String? location,
    String? profileImage,
    String? tribe,
    String? profession,
    List<String>? personality,
    String? bio,
    List<String>? interests,
    String? religion,
    String? education,
    String? lookingFor,
    DateTime? lastSeen,
    double? latitude,
    double? longitude,
    bool? isOnline,
  }) =>
      MatchedUser(
        id: id ?? this.id,
        name: name ?? this.name,
        age: age ?? this.age,
        location: location ?? this.location,
        profileImage: profileImage ?? this.profileImage,
        tribe: tribe ?? this.tribe,
        profession: profession ?? this.profession,
        personality: personality ?? this.personality,
        bio: bio ?? this.bio,
        interests: interests ?? this.interests,
        religion: religion ?? this.religion,
        education: education ?? this.education,
        lookingFor: lookingFor ?? this.lookingFor,
        lastSeen: lastSeen ?? this.lastSeen,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isOnline: isOnline ?? this.isOnline,
      );

  @override
  String toString() =>
      'MatchedUser(id: $id, name: $name, age: $age, location: $location, tribe: $tribe, profession: $profession)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchedUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
