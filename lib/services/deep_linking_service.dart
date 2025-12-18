import 'dart:async';
import 'dart:developer';

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Industry-standard deep linking service
/// Features:
/// - Share profile functionality
/// - Handle incoming links
/// - Fallback to web version
class DeepLinkingService {
  factory DeepLinkingService() => _instance;
  DeepLinkingService._internal();
  static final DeepLinkingService _instance = DeepLinkingService._internal();

  final StreamController<DeepLinkData> _linkStreamController =
      StreamController<DeepLinkData>.broadcast();

  /// Initialize deep linking service
  Future<void> initialize() async {
    try {
      log('🔗 Deep linking service initialized successfully');
    } catch (e) {
      log('❌ Error initializing deep linking service: $e');
    }
  }

  /// Create shareable link for profile
  String createProfileLink({
    required String userId,
    required String userName,
  }) {
    try {
      // Create a simple shareable link
      final String link = 'https://naijasingles.app/profile?userId=$userId';
      log('🔗 Created profile link: $link');
      return link;
    } catch (e) {
      log('❌ Error creating profile link: $e');
      rethrow;
    }
  }

  /// Create shareable link for match
  String createMatchLink({
    required String matchId,
    required String matchName,
  }) {
    try {
      final String link = 'https://naijasingles.app/match?matchId=$matchId';
      log('🔗 Created match link: $link');
      return link;
    } catch (e) {
      log('❌ Error creating match link: $e');
      rethrow;
    }
  }

  /// Create shareable link for event
  String createEventLink({
    required String eventId,
    required String eventName,
    required String eventDate,
  }) {
    try {
      final String link = 'https://naijasingles.app/event?eventId=$eventId';
      log('🔗 Created event link: $link');
      return link;
    } catch (e) {
      log('❌ Error creating event link: $e');
      rethrow;
    }
  }

  /// Share profile via link
  Future<void> shareProfile({
    required String userId,
    required String userName,
    String? userPhoto,
    String? shareText,
  }) async {
    try {
      final String link = createProfileLink(
        userId: userId,
        userName: userName,
      );

      final String text =
          shareText ?? 'Check out $userName\'s profile on NaijaSingles! $link';

      await Share.share(
        text,
        subject: 'Profile from NaijaSingles',
      );

      log('🔗 Profile shared successfully');
    } catch (e) {
      log('❌ Error sharing profile: $e');
      rethrow;
    }
  }

  /// Share match via link
  Future<void> shareMatch({
    required String matchId,
    required String matchName,
    String? matchPhoto,
    String? shareText,
  }) async {
    try {
      final String link = createMatchLink(
        matchId: matchId,
        matchName: matchName,
      );

      final String text = shareText ??
          'I have a new match with $matchName on NaijaSingles! $link';

      await Share.share(
        text,
        subject: 'New Match on NaijaSingles',
      );

      log('🔗 Match shared successfully');
    } catch (e) {
      log('❌ Error sharing match: $e');
      rethrow;
    }
  }

  /// Share event via link
  Future<void> shareEvent({
    required String eventId,
    required String eventName,
    required String eventDate,
    String? eventPhoto,
    String? shareText,
  }) async {
    try {
      final String link = createEventLink(
        eventId: eventId,
        eventName: eventName,
        eventDate: eventDate,
      );

      final String text = shareText ?? 'Join $eventName on $eventDate! $link';

      await Share.share(
        text,
        subject: 'Event on NaijaSingles',
      );

      log('🔗 Event shared successfully');
    } catch (e) {
      log('❌ Error sharing event: $e');
      rethrow;
    }
  }

  /// Handle incoming link
  Future<void> handleIncomingLink(Uri link) async {
    try {
      log('🔗 Handling incoming link: $link');

      // Parse link and navigate accordingly
      if (link.host == 'naijasingles.app' ||
          link.host == 'naijasingles.page.link') {
        final deepLinkData = DeepLinkData.fromUri(link);
        _linkStreamController.add(deepLinkData);
      }
    } catch (e) {
      log('❌ Error handling incoming link: $e');
    }
  }

  /// Launch URL (fallback to web)
  Future<bool> launchExternalUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      log('❌ Error launching URL: $e');
      return false;
    }
  }

  /// Get link stream for listening to incoming links
  Stream<DeepLinkData> get linkStream => _linkStreamController.stream;

  /// Dispose resources
  void dispose() {
    _linkStreamController.close();
  }
}

/// Deep link data model
class DeepLinkData {

  const DeepLinkData({
    required this.type,
    required this.parameters,
    required this.timestamp,
  });

  factory DeepLinkData.fromUri(Uri uri) => DeepLinkData(
      type: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'unknown',
      parameters: uri.queryParameters,
      timestamp: DateTime.now(),
    );
  final String type;
  final Map<String, String> parameters;
  final DateTime timestamp;

  @override
  String toString() => 'DeepLinkData(type: $type, parameters: $parameters, timestamp: $timestamp)';
}
