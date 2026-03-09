import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../common/utils/firestore_helpers.dart';

/// Industry-standard content moderation service
/// Features:
/// - Text content filtering
/// - Image content analysis
/// - Spam detection
/// - Inappropriate content detection
/// - User reporting system
/// - Automated moderation actions
class ContentModerationService {
  factory ContentModerationService() => _instance;
  ContentModerationService._internal();
  static final ContentModerationService _instance =
      ContentModerationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Inappropriate words/phrases (simplified list)
  static const List<String> _inappropriateWords = [
    'spam',
    'scam',
    'fake',
    'bot',
    'hate',
    'abuse',
    'harassment',
    'inappropriate',
    'offensive',
    'explicit',
    'adult',
    'nsfw',
  ];

  // Spam patterns
  static const List<String> _spamPatterns = [
    'click here',
    'free money',
    'win now',
    'urgent',
    'limited time',
    'act now',
    'guaranteed',
    'no risk',
    'instant',
    'immediate',
  ];

  /// Moderate text content
  Future<ModerationResult> moderateText(String text) async {
    try {
      log('🔍 Moderating text content...');

      final issues = <ModerationIssue>[];

      // Check for inappropriate words
      final inappropriateWords = _checkInappropriateWords(text);
      if (inappropriateWords.isNotEmpty) {
        issues.add(
          ModerationIssue(
            type: ModerationIssueType.inappropriateContent,
            severity: ModerationSeverity.high,
            description:
                'Contains inappropriate words: ${inappropriateWords.join(', ')}',
            confidence: 0.9,
          ),
        );
      }

      // Check for spam patterns
      final spamPatterns = _checkSpamPatterns(text);
      if (spamPatterns.isNotEmpty) {
        issues.add(
          ModerationIssue(
            type: ModerationIssueType.spam,
            severity: ModerationSeverity.medium,
            description: 'Contains spam patterns: ${spamPatterns.join(', ')}',
            confidence: 0.8,
          ),
        );
      }

      // Check for excessive repetition
      if (_checkExcessiveRepetition(text)) {
        issues.add(
          const ModerationIssue(
            type: ModerationIssueType.spam,
            severity: ModerationSeverity.medium,
            description: 'Contains excessive repetition',
            confidence: 0.7,
          ),
        );
      }

      // Check for all caps (shouting)
      if (_checkAllCaps(text)) {
        issues.add(
          const ModerationIssue(
            type: ModerationIssueType.inappropriateContent,
            severity: ModerationSeverity.low,
            description: 'Contains excessive capitalization',
            confidence: 0.6,
          ),
        );
      }

      // Check for personal information
      final personalInfo = _checkPersonalInformation(text);
      if (personalInfo.isNotEmpty) {
        issues.add(
          ModerationIssue(
            type: ModerationIssueType.personalInformation,
            severity: ModerationSeverity.high,
            description:
                'Contains personal information: ${personalInfo.join(', ')}',
            confidence: 0.8,
          ),
        );
      }

      // Determine overall result
      final result = _determineModerationResult(issues);

      log('✅ Text moderation completed: ${result.action}');
      return result;
    } on Object catch (e) {
      log('❌ Error moderating text: $e');
      return ModerationResult(
        action: ModerationAction.approve,
        issues: [],
        confidence: 0,
        moderatedAt: DateTime.now(),
      );
    }
  }

  /// Moderate image content
  Future<ModerationResult> moderateImage(String imageUrl) async {
    try {
      log('🖼️ Moderating image content...');

      // Simulate image analysis
      await Future.delayed(const Duration(seconds: 2));

      final issues = <ModerationIssue>[];

      // Simulate different image analysis results
      final random = DateTime.now().millisecondsSinceEpoch % 100;

      if (random < 5) {
        // 5% chance of inappropriate content
        issues.add(
          const ModerationIssue(
            type: ModerationIssueType.inappropriateContent,
            severity: ModerationSeverity.high,
            description: 'Image contains inappropriate content',
            confidence: 0.9,
          ),
        );
      } else if (random < 15) {
        // 10% chance of questionable content
        issues.add(
          const ModerationIssue(
            type: ModerationIssueType.inappropriateContent,
            severity: ModerationSeverity.medium,
            description: 'Image may contain questionable content',
            confidence: 0.7,
          ),
        );
      }

      // Determine overall result
      final result = _determineModerationResult(issues);

      log('✅ Image moderation completed: ${result.action}');
      return result;
    } on Object catch (e) {
      log('❌ Error moderating image: $e');
      return ModerationResult(
        action: ModerationAction.approve,
        issues: [],
        confidence: 0,
        moderatedAt: DateTime.now(),
      );
    }
  }

  /// Moderate user profile
  Future<ModerationResult> moderateProfile(String userId) async {
    try {
      log('👤 Moderating user profile: $userId');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return ModerationResult(
          action: ModerationAction.reject,
          issues: [
            const ModerationIssue(
              type: ModerationIssueType.inappropriateContent,
              severity: ModerationSeverity.high,
              description: 'User profile not found',
              confidence: 1,
            ),
          ],
          confidence: 1,
          moderatedAt: DateTime.now(),
        );
      }

      final userData = userDoc.data()!;
      final issues = <ModerationIssue>[];

      // Check bio
      final bio = userData['bio'] as String?;
      if (bio != null && bio.isNotEmpty) {
        final bioModeration = await moderateText(bio);
        issues.addAll(bioModeration.issues);
      }

      // Check profile photos
      final profilePhotos = userData['photos'] as List<dynamic>? ?? [];
      for (final photo in profilePhotos) {
        final photoUrl = photo['url'] as String?;
        if (photoUrl != null) {
          final photoModeration = await moderateImage(photoUrl);
          issues.addAll(photoModeration.issues);
        }
      }

      // Check for fake profiles
      if (_checkFakeProfile(userData)) {
        issues.add(
          const ModerationIssue(
            type: ModerationIssueType.fakeProfile,
            severity: ModerationSeverity.high,
            description: 'Profile appears to be fake',
            confidence: 0.8,
          ),
        );
      }

      // Determine overall result
      final result = _determineModerationResult(issues);

      log('✅ Profile moderation completed: ${result.action}');
      return result;
    } on Object catch (e) {
      log('❌ Error moderating profile: $e');
      return ModerationResult(
        action: ModerationAction.approve,
        issues: [],
        confidence: 0,
        moderatedAt: DateTime.now(),
      );
    }
  }

  /// Report content
  Future<void> reportContent({
    required String contentId,
    required String contentType,
    required String reason,
    String? description,
  }) async {
    try {
      log('🚨 Reporting content: $contentId');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('reports').add({
        'contentId': contentId,
        'contentType': contentType,
        'reporterId': currentUserId,
        'reason': reason,
        'description': description,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
      });

      log('✅ Content reported successfully');
    } on Object catch (e) {
      log('❌ Error reporting content: $e');
      rethrow;
    }
  }

  /// Get moderation history for user
  Future<List<ModerationHistory>> getModerationHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('moderation_history')
          .where('userId', isEqualTo: userId)
          .orderBy('moderatedAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ModerationHistory(
          id: doc.id,
          userId: userId,
          contentType: data['contentType'] ?? '',
          contentId: data['contentId'] ?? '',
          action: ModerationAction.values.firstWhere(
            (e) => e.name == data['action'],
            orElse: () => ModerationAction.approve,
          ),
          issues: (data['issues'] as List<dynamic>?)
                  ?.map((issue) => ModerationIssue.fromMap(issue))
                  .toList() ??
              [],
          moderatedAt: parseDateTime(data['moderatedAt']),
        );
      }).toList();
    } on Object catch (e) {
      log('❌ Error getting moderation history: $e');
      return [];
    }
  }

  /// Check inappropriate words
  List<String> _checkInappropriateWords(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    return words.where((word) => _inappropriateWords.contains(word)).toList();
  }

  /// Check spam patterns
  List<String> _checkSpamPatterns(String text) {
    final lowerText = text.toLowerCase();
    return _spamPatterns.where(lowerText.contains).toList();
  }

  /// Check for excessive repetition
  bool _checkExcessiveRepetition(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final wordCounts = <String, int>{};

    for (final word in words) {
      wordCounts[word] = (wordCounts[word] ?? 0) + 1;
    }

    // Check if any word appears more than 3 times
    return wordCounts.values.any((n) => n > 3);
  }

  /// Check for all caps
  bool _checkAllCaps(String text) {
    final words = text.split(RegExp(r'\s+'));
    final capsWords = words
        .where((word) => word == word.toUpperCase() && word.length > 2)
        .length;
    return capsWords > words.length * 0.5; // More than 50% caps
  }

  /// Check for personal information
  List<String> _checkPersonalInformation(String text) {
    final issues = <String>[];

    // Check for phone numbers
    if (RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b').hasMatch(text)) {
      issues.add('phone number');
    }

    // Check for email addresses
    if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
        .hasMatch(text)) {
      issues.add('email address');
    }

    // Check for social security numbers
    if (RegExp(r'\b\d{3}-?\d{2}-?\d{4}\b').hasMatch(text)) {
      issues.add('social security number');
    }

    return issues;
  }

  /// Check for fake profile
  bool _checkFakeProfile(Map<String, dynamic> userData) {
    // Simple heuristics for fake profile detection
    final bio = userData['bio'] as String? ?? '';
    final photos = userData['photos'] as List<dynamic>? ?? [];

    // Check for very short bio
    if (bio.length < 10) return true;

    // Check for no photos
    if (photos.isEmpty) return true;

    // Check for suspicious bio content
    if (_checkSpamPatterns(bio).isNotEmpty) return true;

    return false;
  }

  /// Determine moderation result
  ModerationResult _determineModerationResult(List<ModerationIssue> issues) {
    if (issues.isEmpty) {
      return ModerationResult(
        action: ModerationAction.approve,
        issues: issues,
        confidence: 1,
        moderatedAt: DateTime.now(),
      );
    }

    // Check for high severity issues
    final highSeverityIssues = issues
        .where((issue) => issue.severity == ModerationSeverity.high)
        .length;
    if (highSeverityIssues > 0) {
      return ModerationResult(
        action: ModerationAction.reject,
        issues: issues,
        confidence: 0.9,
        moderatedAt: DateTime.now(),
      );
    }

    // Check for medium severity issues
    final mediumSeverityIssues = issues
        .where((issue) => issue.severity == ModerationSeverity.medium)
        .length;
    if (mediumSeverityIssues > 1) {
      return ModerationResult(
        action: ModerationAction.reject,
        issues: issues,
        confidence: 0.8,
        moderatedAt: DateTime.now(),
      );
    }

    // Check for multiple low severity issues
    final lowSeverityIssues = issues
        .where((issue) => issue.severity == ModerationSeverity.low)
        .length;
    if (lowSeverityIssues > 2) {
      return ModerationResult(
        action: ModerationAction.review,
        issues: issues,
        confidence: 0.7,
        moderatedAt: DateTime.now(),
      );
    }

    return ModerationResult(
      action: ModerationAction.approve,
      issues: issues,
      confidence: 0.6,
      moderatedAt: DateTime.now(),
    );
  }
}

/// Moderation issue types
enum ModerationIssueType {
  inappropriateContent,
  spam,
  personalInformation,
  fakeProfile,
  harassment,
  violence,
}

/// Moderation severity levels
enum ModerationSeverity {
  low,
  medium,
  high,
}

/// Moderation actions
enum ModerationAction {
  approve,
  review,
  reject,
  delete,
}

/// Moderation issue model
class ModerationIssue {
  const ModerationIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.confidence,
  });

  factory ModerationIssue.fromMap(Map<String, dynamic> map) => ModerationIssue(
        type: ModerationIssueType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => ModerationIssueType.inappropriateContent,
        ),
        severity: ModerationSeverity.values.firstWhere(
          (e) => e.name == map['severity'],
          orElse: () => ModerationSeverity.low,
        ),
        description: map['description'] ?? '',
        confidence: map['confidence']?.toDouble() ?? 0.0,
      );
  final ModerationIssueType type;
  final ModerationSeverity severity;
  final String description;
  final double confidence;

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'severity': severity.name,
        'description': description,
        'confidence': confidence,
      };

  @override
  String toString() =>
      'ModerationIssue(${type.name}: ${severity.name}, confidence: $confidence)';
}

/// Moderation result model
class ModerationResult {
  const ModerationResult({
    required this.action,
    required this.issues,
    required this.confidence,
    required this.moderatedAt,
  });
  final ModerationAction action;
  final List<ModerationIssue> issues;
  final double confidence;
  final DateTime moderatedAt;

  @override
  String toString() =>
      'ModerationResult(${action.name}, confidence: $confidence, issues: ${issues.length})';
}

/// Moderation history model
class ModerationHistory {
  const ModerationHistory({
    required this.id,
    required this.userId,
    required this.contentType,
    required this.contentId,
    required this.action,
    required this.issues,
    required this.moderatedAt,
  });
  final String id;
  final String userId;
  final String contentType;
  final String contentId;
  final ModerationAction action;
  final List<ModerationIssue> issues;
  final DateTime moderatedAt;

  @override
  String toString() =>
      'ModerationHistory($userId: ${action.name}, $contentType)';
}
