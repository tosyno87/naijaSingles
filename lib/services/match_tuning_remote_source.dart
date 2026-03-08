import 'package:cloud_firestore/cloud_firestore.dart';

import '../common/utils/app_logger.dart';

typedef MatchTuningDocumentFetcher = Future<Map<String, dynamic>?> Function();

/// Firestore-backed source for live match tuning payloads.
///
/// Expected shape (either top-level or under [payloadField]):
/// {
///   "version": "...",
///   "rollbackKey": "...",
///   ...
/// }
class MatchTuningRemoteSource {
  MatchTuningRemoteSource({
    FirebaseFirestore? firestore,
    this.collectionPath = 'runtimeConfig',
    this.documentId = 'matchTuning',
    this.payloadField = 'payload',
    MatchTuningDocumentFetcher? fetcher,
  })  : _firestore = firestore,
        _fetcher = fetcher;

  final FirebaseFirestore? _firestore;
  final MatchTuningDocumentFetcher? _fetcher;
  final String collectionPath;
  final String documentId;
  final String payloadField;

  Future<Map<String, dynamic>?> loadRawDocument() async {
    try {
      return await (_fetcher ?? _fetchFromFirestore)();
    } on Object catch (e, st) {
      AppLogger.warning(
        'Failed to load raw Firestore match tuning document',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> load() async {
    try {
      final raw = await loadRawDocument();
      if (raw == null || raw.isEmpty) {
        return null;
      }

      final payload = raw[payloadField];
      if (payload is Map<String, dynamic>) {
        return payload;
      }
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }

      // Backward-compatible path: allow top-level config shape.
      return raw;
    } on Object catch (e, st) {
      AppLogger.warning(
        'Failed to load Firestore match tuning payload',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchFromFirestore() async {
    final firestore = _firestore ?? FirebaseFirestore.instance;
    final snapshot =
        await firestore.collection(collectionPath).doc(documentId).get();
    final data = snapshot.data();
    if (data == null || data.isEmpty) {
      return null;
    }
    return data;
  }
}
