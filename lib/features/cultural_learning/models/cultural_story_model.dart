import 'package:cloud_firestore/cloud_firestore.dart';

class CulturalStory {

  const CulturalStory({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.country,
    required this.category,
    required this.tags,
    required this.imageUrl,
    required this.isVerified,
    required this.likesCount,
    required this.commentsCount,
    required this.likedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublished,
  });

  factory CulturalStory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CulturalStory(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      country: data['country'] ?? '',
      category: data['category'] ?? 'Traditions',
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      isVerified: data['isVerified'] ?? false,
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isPublished: data['isPublished'] ?? true,
    );
  }
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String country;
  final String category; // 'Traditions', 'Food', 'Music', 'Language', 'History'
  final List<String> tags;
  final String imageUrl;
  final bool isVerified; // Community-verified stories
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;

  Map<String, dynamic> toFirestore() => {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'country': country,
      'category': category,
      'tags': tags,
      'imageUrl': imageUrl,
      'isVerified': isVerified,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPublished': isPublished,
    };
}

class LanguageExchange {

  const LanguageExchange({
    required this.id,
    required this.nativeLanguage,
    required this.learningLanguage,
    required this.userId,
    required this.userName,
    required this.proficiency,
    required this.country,
    required this.city,
    required this.isOnline,
    required this.isInPerson,
    required this.description,
    required this.interests,
    required this.createdAt,
    required this.isActive,
  });

  factory LanguageExchange.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LanguageExchange(
      id: doc.id,
      nativeLanguage: data['nativeLanguage'] ?? '',
      learningLanguage: data['learningLanguage'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      proficiency: data['proficiency'] ?? 'Beginner',
      country: data['country'] ?? '',
      city: data['city'] ?? '',
      isOnline: data['isOnline'] ?? true,
      isInPerson: data['isInPerson'] ?? false,
      description: data['description'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
  final String id;
  final String nativeLanguage;
  final String learningLanguage;
  final String userId;
  final String userName;
  final String proficiency; // 'Beginner', 'Intermediate', 'Advanced'
  final String country;
  final String city;
  final bool isOnline;
  final bool isInPerson;
  final String description;
  final List<String> interests;
  final DateTime createdAt;
  final bool isActive;

  Map<String, dynamic> toFirestore() => {
      'nativeLanguage': nativeLanguage,
      'learningLanguage': learningLanguage,
      'userId': userId,
      'userName': userName,
      'proficiency': proficiency,
      'country': country,
      'city': city,
      'isOnline': isOnline,
      'isInPerson': isInPerson,
      'description': description,
      'interests': interests,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
}
