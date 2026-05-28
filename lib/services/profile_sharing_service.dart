import 'package:share_plus/share_plus.dart';

/// Shares profile links via the platform share sheet.
class ProfileSharingService {
  Future<void> shareProfile({
    required String userId,
    required String displayName,
    String? deepLinkBase,
  }) async {
    final base = deepLinkBase ?? 'https://afropeep.app';
    final link = '$base/profile/$userId';
    await Share.share(
      'Check out $displayName on AfroPeep: $link',
      subject: '$displayName on AfroPeep',
    );
  }
}
