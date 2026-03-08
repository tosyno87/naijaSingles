import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../common/utils/app_logger.dart';
import '../../../../services/match_config_provider.dart';
import '../../../../services/match_experiment_assignment.dart';
import 'match_quality_event.dart';

typedef MatchQualityWriter = Future<void> Function(
  List<MatchQualityEvent> events,
);
typedef MatchExperimentResolver = Future<MatchExperimentAssignment?> Function(
  String userId,
);

class MatchQualityReporter {
  /// Records are asynchronous because experiment attribution can require
  /// async assignment resolution. Callers should treat record methods as
  /// fire-and-forget and use `unawaited(...)` where appropriate.
  MatchQualityReporter({
    FirebaseFirestore? firestore,
    DateTime Function()? now,
    this.batchSize = 25,
    this.flushInterval = const Duration(seconds: 3),
    this.maxQueueSize = 500,
    MatchQualityWriter? writer,
    MatchExperimentResolver? experimentResolver,
  })  : _firestore = firestore,
        _now = now ?? DateTime.now,
        _writer = writer,
        _experimentResolver = experimentResolver;

  static final MatchQualityReporter instance = MatchQualityReporter();

  final FirebaseFirestore? _firestore;
  final DateTime Function() _now;
  final int batchSize;
  final Duration flushInterval;
  final int maxQueueSize;
  final MatchQualityWriter? _writer;
  final MatchExperimentResolver? _experimentResolver;
  final List<MatchQualityEvent> _queue = <MatchQualityEvent>[];
  bool _isFlushing = false;
  Timer? _flushTimer;

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      (_firestore ?? FirebaseFirestore.instance)
          .collection('matchQualityEvents')
          .withConverter(
            fromFirestore: (snapshot, _) =>
                snapshot.data() ?? <String, dynamic>{},
            toFirestore: (value, _) => value,
          );

  Future<void> recordImpression({
    required String userId,
    required String candidateId,
    required String mode,
    Map<String, double>? scoreSnapshot,
    double? distanceMiles,
  }) async {
    final assignment = await _resolveExperiment(userId);
    _enqueue(
      MatchQualityEvent(
        type: MatchQualityEventType.impression,
        userIdHash: _hashId(userId),
        candidateIdHash: _hashId(candidateId),
        mode: mode,
        timestamp: _now(),
        scoreSnapshot: scoreSnapshot,
        distanceBucket: _distanceBucket(distanceMiles),
        experimentId: assignment?.experimentId,
        variantId: assignment?.variantId,
      ),
    );
  }

  Future<void> recordAction({
    required String userId,
    required String candidateId,
    required String mode,
    required MatchQualityActionType actionType,
    Map<String, double>? scoreSnapshot,
    double? distanceMiles,
  }) async {
    final assignment = await _resolveExperiment(userId);
    _enqueue(
      MatchQualityEvent(
        type: MatchQualityEventType.action,
        userIdHash: _hashId(userId),
        candidateIdHash: _hashId(candidateId),
        mode: mode,
        timestamp: _now(),
        actionType: actionType,
        scoreSnapshot: scoreSnapshot,
        distanceBucket: _distanceBucket(distanceMiles),
        experimentId: assignment?.experimentId,
        variantId: assignment?.variantId,
      ),
    );
  }

  Future<void> recordMatch({
    required String userId,
    required String candidateId,
    required String mode,
  }) async {
    final assignment = await _resolveExperiment(userId);
    _enqueue(
      MatchQualityEvent(
        type: MatchQualityEventType.match,
        userIdHash: _hashId(userId),
        candidateIdHash: _hashId(candidateId),
        mode: mode,
        timestamp: _now(),
        experimentId: assignment?.experimentId,
        variantId: assignment?.variantId,
      ),
    );
  }

  Future<void> recordConversationStart({
    required String userId,
    required String candidateId,
    required String mode,
    required bool within24Hours,
  }) async {
    final assignment = await _resolveExperiment(userId);
    _enqueue(
      MatchQualityEvent(
        type: MatchQualityEventType.conversationStart,
        userIdHash: _hashId(userId),
        candidateIdHash: _hashId(candidateId),
        mode: mode,
        timestamp: _now(),
        metadata: <String, dynamic>{'within24Hours': within24Hours},
        experimentId: assignment?.experimentId,
        variantId: assignment?.variantId,
      ),
    );
  }

  Future<void> recordLatency({
    required String operation,
    required int latencyMs,
    required String mode,
    String? userId,
    String? candidateId,
  }) async {
    final assignment = await _resolveExperiment(userId);
    _enqueue(
      MatchQualityEvent(
        type: MatchQualityEventType.latency,
        userIdHash: userId != null ? _hashId(userId) : 'anonymous',
        candidateIdHash: candidateId != null ? _hashId(candidateId) : null,
        mode: mode,
        timestamp: _now(),
        latencyMs: latencyMs,
        metadata: <String, dynamic>{'operation': operation},
        experimentId: assignment?.experimentId,
        variantId: assignment?.variantId,
      ),
    );
  }

  Future<void> recordConversationQuality({
    required String userId,
    required String mode,
    required int conversationDepth,
    double? responseRate,
    int? medianReplyDelayMs,
    String? candidateId,
  }) async {
    final assignment = await _resolveExperiment(userId);
    _enqueue(
      MatchQualityEvent(
        type: MatchQualityEventType.conversationQuality,
        userIdHash: _hashId(userId),
        candidateIdHash: candidateId != null ? _hashId(candidateId) : null,
        mode: mode,
        timestamp: _now(),
        metadata: <String, dynamic>{
          'conversationDepth': conversationDepth,
          if (responseRate != null) 'responseRate': responseRate,
          if (medianReplyDelayMs != null)
            'medianReplyDelayMs': medianReplyDelayMs,
        },
        experimentId: assignment?.experimentId,
        variantId: assignment?.variantId,
      ),
    );
  }

  Future<void> flush() async {
    if (_isFlushing || _queue.isEmpty) {
      return;
    }
    _isFlushing = true;
    _flushTimer?.cancel();

    final batchToWrite = List<MatchQualityEvent>.from(_queue);
    _queue.clear();

    try {
      final writeEvents = _writer ?? _flushToFirestore;
      await writeEvents(batchToWrite);
    } on Object catch (e, st) {
      _queue.insertAll(0, batchToWrite);
      _enforceQueueCap();
      _scheduleFlush();
      AppLogger.warning(
        'MatchQualityReporter flush failed; events re-queued',
        error: e,
        stackTrace: st,
      );
    } finally {
      _isFlushing = false;
    }
  }

  void dispose() {
    _flushTimer?.cancel();
  }

  void _enqueue(MatchQualityEvent event) {
    _queue.add(event);
    _enforceQueueCap();
    if (_queue.length >= batchSize) {
      unawaited(flush());
      return;
    }
    _scheduleFlush();
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(flushInterval, () {
      unawaited(flush());
    });
  }

  Future<void> _flushToFirestore(List<MatchQualityEvent> events) async {
    final firestore = _firestore ?? FirebaseFirestore.instance;
    final writeBatch = firestore.batch();
    for (final event in events) {
      final doc = _eventsCollection.doc();
      writeBatch.set(doc, event.toMap());
    }
    await writeBatch.commit();
  }

  void _enforceQueueCap() {
    final overflow = _queue.length - maxQueueSize;
    if (overflow <= 0) {
      return;
    }
    _queue.removeRange(0, overflow);
    AppLogger.warning(
      'MatchQualityReporter queue cap reached; dropped $overflow oldest events',
    );
  }

  Future<MatchExperimentAssignment?> _resolveExperiment(String? userId) async {
    if (userId == null || userId.isEmpty) {
      return null;
    }
    final resolver = _experimentResolver ??
        MatchConfigProvider.instance.getAssignmentForUser;
    try {
      return await resolver(userId);
    } on Object catch (e, st) {
      AppLogger.warning(
        'Failed to resolve match experiment assignment',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  static String _distanceBucket(double? miles) {
    if (miles == null) {
      return 'unknown';
    }
    if (miles <= 5) {
      return '0-5';
    }
    if (miles <= 15) {
      return '6-15';
    }
    if (miles <= 30) {
      return '16-30';
    }
    if (miles <= 60) {
      return '31-60';
    }
    return '60+';
  }

  // Deterministic non-reversible pseudonymization for analytics usage.
  // Not intended for cryptographic use.
  static String _hashId(String input) {
    const int offset = 0x811C9DC5;
    const int prime = 0x01000193;
    int hash = offset;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * prime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
