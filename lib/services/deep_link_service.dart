import 'dart:async';
import 'dart:developer';

import 'package:app_links/app_links.dart';

import '../common/routes/route_name.dart';
import '../main.dart';

/// Handles https://afropeep.app/profile/{userId} deep links.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  static const String profilePathPrefix = '/profile/';

  /// Returns user id when [uri] is a profile deep link.
  static String? profileUserIdFromUri(Uri uri) {
    final path = uri.path;
    if (!path.startsWith(profilePathPrefix)) return null;
    final id = path.substring(profilePathPrefix.length).split('/').first;
    if (id.isEmpty) return null;
    return id;
  }

  Future<void> initialize() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _navigate(initial);
      }
      _sub = _appLinks.uriLinkStream.listen(
        _navigate,
        onError: (Object e) => log('Deep link stream error: $e'),
      );
    } on Object catch (e) {
      log('Deep link init failed: $e');
    }
  }

  void _navigate(Uri uri) {
    final userId = profileUserIdFromUri(uri);
    if (userId == null) return;

    final nav = MyApp.navigatorKey.currentState;
    if (nav == null) {
      log('Deep link: navigator not ready for profile $userId');
      return;
    }

    log('Deep link: opening profile $userId');
    unawaited(
      nav.pushNamed(
        RouteName.publicProfile,
        arguments: userId,
      ),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
