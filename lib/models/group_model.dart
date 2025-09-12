import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Model representing a cultural group in the app
class GroupModel {
  final String? id;
  final String name;
  final String description;
  final String category;
  final String? imageUrl;
  final String creatorId;
  final List<String> memberIds;
  final List<String> adminIds;
  final Map<String, dynamic>? culturalInfo;
  final bool isPublic;
  final int maxMembers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? location;
  final List<String> tags;
  final Map<String, dynamic>? settings;

  GroupModel({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.creatorId,
    required this.memberIds,
    required this.adminIds,
    this.culturalInfo,
    required this.isPublic,
    required this.maxMembers,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    required this.tags,
    this.settings,
  });

  /// Create GroupModel from Firestore document
  factory GroupModel.fromDocument(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      return GroupModel(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        category: data['category'] ?? 'General',
        imageUrl: data['imageUrl'],
        creatorId: data['creatorId'] ?? '',
        memberIds: List<String>.from(data['memberIds'] ?? []),
        adminIds: List<String>.from(data['adminIds'] ?? []),
        culturalInfo: data['culturalInfo'] as Map<String, dynamic>?,
        isPublic: data['isPublic'] ?? true,
        maxMembers: data['maxMembers'] ?? 100,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        location: data['location'],
        tags: List<String>.from(data['tags'] ?? []),
        settings: data['settings'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('Error creating GroupModel from document: $e');
      throw Exception('Failed to create GroupModel from document');
    }
  }

  /// Create GroupModel from JSON
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      imageUrl: json['imageUrl'],
      creatorId: json['creatorId'] ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      adminIds: List<String>.from(json['adminIds'] ?? []),
      culturalInfo: json['culturalInfo'] as Map<String, dynamic>?,
      isPublic: json['isPublic'] ?? true,
      maxMembers: json['maxMembers'] ?? 100,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      location: json['location'],
      tags: List<String>.from(json['tags'] ?? []),
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  /// Convert GroupModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'culturalInfo': culturalInfo,
      'isPublic': isPublic,
      'maxMembers': maxMembers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'tags': tags,
      'settings': settings,
    };
  }

  /// Convert GroupModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'culturalInfo': culturalInfo,
      'isPublic': isPublic,
      'maxMembers': maxMembers,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'location': location,
      'tags': tags,
      'settings': settings,
    };
  }

  /// Create a copy of GroupModel with updated fields
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? imageUrl,
    String? creatorId,
    List<String>? memberIds,
    List<String>? adminIds,
    Map<String, dynamic>? culturalInfo,
    bool? isPublic,
    int? maxMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? location,
    List<String>? tags,
    Map<String, dynamic>? settings,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      culturalInfo: culturalInfo ?? this.culturalInfo,
      isPublic: isPublic ?? this.isPublic,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      settings: settings ?? this.settings,
    );
  }

  /// Check if user is a member of the group
  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  /// Check if user is an admin of the group
  bool isAdmin(String userId) {
    return adminIds.contains(userId);
  }

  /// Check if user is the creator of the group
  bool isCreator(String userId) {
    return creatorId == userId;
  }

  /// Get member count
  int get memberCount => memberIds.length;

  /// Check if group is full
  bool get isFull => memberIds.length >= maxMembers;

  /// Get cultural info for display
  String get culturalDisplay {
    if (culturalInfo == null) return 'General';
    
    final nationality = culturalInfo!['nationality'] ?? '';
    final tribe = culturalInfo!['tribe'] ?? '';
    
    if (nationality.isNotEmpty && tribe.isNotEmpty) {
      return '$nationality - $tribe';
    } else if (nationality.isNotEmpty) {
      return nationality;
    } else if (tribe.isNotEmpty) {
      return tribe;
    }
    
    return 'General';
  }

  /// Get group category display name
  String get categoryDisplay {
    switch (category.toLowerCase()) {
      case 'cultural':
        return 'Cultural';
      case 'professional':
        return 'Professional';
      case 'social':
        return 'Social';
      case 'educational':
        return 'Educational';
      case 'religious':
        return 'Religious';
      case 'regional':
        return 'Regional';
      default:
        return 'General';
    }
  }

  @override
  String toString() {
    return 'GroupModel{id: $id, name: $name, category: $category, members: ${memberIds.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Group categories available in the app
class GroupCategories {
  static const List<String> categories = [
    'Cultural',
    'Professional',
    'Social',
    'Educational',
    'Religious',
    'Regional',
    'General',
  ];

  static const Map<String, String> categoryDescriptions = {
    'Cultural': 'Groups focused on cultural heritage, traditions, and celebrations',
    'Professional': 'Professional networking and career development groups',
    'Social': 'Social groups for making friends and social connections',
    'Educational': 'Groups focused on learning and education',
    'Religious': 'Groups based on religious or spiritual beliefs',
    'Regional': 'Groups for people from specific regions or countries',
    'General': 'General interest groups',
  };

  static const Map<String, String> categoryIcons = {
    'Cultural': '🎭',
    'Professional': '💼',
    'Social': '👥',
    'Educational': '📚',
    'Religious': '🕌',
    'Regional': '🌍',
    'General': '🌟',
  };
}
