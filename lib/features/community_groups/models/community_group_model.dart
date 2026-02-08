import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityGroup {
  // ['Technology', 'Music', 'Food', 'Language']

  const CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.country,
    required this.city,
    required this.creatorId,
    required this.memberIds,
    required this.adminIds,
    required this.imageUrl,
    required this.isPublic,
    required this.isVerified,
    required this.rules,
    required this.createdAt,
    required this.updatedAt,
    required this.memberCount,
    required this.tags,
  });

  factory CommunityGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityGroup(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Interest',
      country: data['country'] ?? '',
      city: data['city'] ?? '',
      creatorId: data['creatorId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      adminIds: List<String>.from(data['adminIds'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      isPublic: data['isPublic'] ?? true,
      isVerified: data['isVerified'] ?? false,
      rules: Map<String, dynamic>.from(data['rules'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      memberCount: data['memberCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }
  final String id;
  final String name;
  final String description;
  final String category; // 'Cultural', 'Professional', 'Interest', 'Location'
  final String country; // 'Nigeria', 'Ghana', 'Kenya', etc.
  final String city;
  final String creatorId;
  final List<String> memberIds;
  final List<String> adminIds;
  final String imageUrl;
  final bool isPublic;
  final bool isVerified; // Community-verified groups
  final Map<String, dynamic> rules;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;
  final List<String> tags;

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'category': category,
        'country': country,
        'city': city,
        'creatorId': creatorId,
        'memberIds': memberIds,
        'adminIds': adminIds,
        'imageUrl': imageUrl,
        'isPublic': isPublic,
        'isVerified': isVerified,
        'rules': rules,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'memberCount': memberCount,
        'tags': tags,
      };

  CommunityGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? country,
    String? city,
    String? creatorId,
    List<String>? memberIds,
    List<String>? adminIds,
    String? imageUrl,
    bool? isPublic,
    bool? isVerified,
    Map<String, dynamic>? rules,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
    List<String>? tags,
  }) =>
      CommunityGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        country: country ?? this.country,
        city: city ?? this.city,
        creatorId: creatorId ?? this.creatorId,
        memberIds: memberIds ?? this.memberIds,
        adminIds: adminIds ?? this.adminIds,
        imageUrl: imageUrl ?? this.imageUrl,
        isPublic: isPublic ?? this.isPublic,
        isVerified: isVerified ?? this.isVerified,
        rules: rules ?? this.rules,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        memberCount: memberCount ?? this.memberCount,
        tags: tags ?? this.tags,
      );
}
