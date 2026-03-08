import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/match/data/analytics/match_quality_event.dart';
import 'package:naijasingles/features/match/data/analytics/match_quality_reporter.dart';
import 'package:naijasingles/services/match_experiment_assignment.dart';

void main() {
  group('MatchQualityReporter', () {
    test('auto flushes when batch size is reached', () async {
      final writes = <List<MatchQualityEvent>>[];
      final reporter = MatchQualityReporter(
        now: () => DateTime(2026, 3, 8, 12),
        batchSize: 2,
        flushInterval: const Duration(days: 1),
        writer: (events) async =>
            writes.add(List<MatchQualityEvent>.from(events)),
      );

      await reporter.recordImpression(
        userId: 'u1',
        candidateId: 'c1',
        mode: 'Dating',
      );
      await reporter.recordAction(
        userId: 'u1',
        candidateId: 'c1',
        mode: 'Dating',
        actionType: MatchQualityActionType.connect,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(writes, hasLength(1));
      expect(writes.single, hasLength(2));
      expect(writes.single.first.type, MatchQualityEventType.impression);
      expect(writes.single.last.type, MatchQualityEventType.action);
    });

    test('requeues on failure and preserves ordering on retry', () async {
      final writes = <List<MatchQualityEvent>>[];
      var attempt = 0;
      final reporter = MatchQualityReporter(
        now: () => DateTime(2026, 3, 8, 12),
        batchSize: 10,
        flushInterval: const Duration(days: 1),
        writer: (events) async {
          attempt++;
          if (attempt == 1) {
            throw StateError('transient failure');
          }
          writes.add(List<MatchQualityEvent>.from(events));
        },
      );

      await reporter.recordImpression(
        userId: 'u1',
        candidateId: 'c1',
        mode: 'Dating',
      );
      await reporter.recordAction(
        userId: 'u1',
        candidateId: 'c1',
        mode: 'Dating',
        actionType: MatchQualityActionType.pass,
      );

      await reporter.flush();
      await reporter.recordMatch(
        userId: 'u1',
        candidateId: 'c2',
        mode: 'Dating',
      );
      await reporter.flush();

      expect(attempt, 2);
      expect(writes, hasLength(1));
      expect(writes.single.map((e) => e.type).toList(), [
        MatchQualityEventType.impression,
        MatchQualityEventType.action,
        MatchQualityEventType.match,
      ]);
    });

    test('enforces queue cap by dropping oldest events', () async {
      final writes = <List<MatchQualityEvent>>[];
      final reporter = MatchQualityReporter(
        now: () => DateTime(2026, 3, 8, 12),
        batchSize: 10,
        maxQueueSize: 2,
        flushInterval: const Duration(days: 1),
        writer: (events) async =>
            writes.add(List<MatchQualityEvent>.from(events)),
      );

      await reporter.recordImpression(
        userId: 'u1',
        candidateId: 'c1',
        mode: 'm1',
      );
      await reporter.recordImpression(
        userId: 'u1',
        candidateId: 'c2',
        mode: 'm2',
      );
      await reporter.recordImpression(
        userId: 'u1',
        candidateId: 'c3',
        mode: 'm3',
      );

      await reporter.flush();

      expect(writes, hasLength(1));
      expect(writes.single.map((e) => e.mode).toList(), ['m2', 'm3']);
    });

    test('records event variants and expected payload fields', () async {
      final writes = <List<MatchQualityEvent>>[];
      final reporter = MatchQualityReporter(
        now: () => DateTime(2026, 3, 8, 12),
        batchSize: 50,
        flushInterval: const Duration(days: 1),
        writer: (events) async =>
            writes.add(List<MatchQualityEvent>.from(events)),
      );

      await reporter.recordImpression(
        userId: 'u1',
        candidateId: 'c1',
        mode: 'Dating',
        distanceMiles: 4,
      );
      await reporter.recordImpression(
        userId: 'u1',
        candidateId: 'c2',
        mode: 'Dating',
        distanceMiles: 18,
      );
      await reporter.recordImpression(
        userId: 'u1',
        candidateId: 'c3',
        mode: 'Dating',
        distanceMiles: 80,
      );
      await reporter.recordMatch(
        userId: 'u1',
        candidateId: 'c4',
        mode: 'Dating',
      );
      await reporter.recordConversationStart(
        userId: 'u1',
        candidateId: 'c4',
        mode: 'Dating',
        within24Hours: true,
      );
      await reporter.recordLatency(
        operation: 'thread_open',
        latencyMs: 123,
        mode: 'Dating',
      );

      await reporter.flush();

      final events = writes.single;
      expect(events.length, 6);
      expect(events[0].distanceBucket, '0-5');
      expect(events[1].distanceBucket, '16-30');
      expect(events[2].distanceBucket, '60+');
      expect(events[4].metadata?['within24Hours'], true);
      expect(events[5].latencyMs, 123);
      expect(events[5].metadata?['operation'], 'thread_open');
      expect(events[0].userIdHash, isNot('u1'));
      expect(events[0].candidateIdHash, isNot('c1'));
    });

    test('enriches events with experiment assignment metadata', () async {
      final writes = <List<MatchQualityEvent>>[];
      final reporter = MatchQualityReporter(
        now: () => DateTime(2026, 3, 8, 12),
        batchSize: 10,
        flushInterval: const Duration(days: 1),
        writer: (events) async =>
            writes.add(List<MatchQualityEvent>.from(events)),
        experimentResolver: (_) async => const MatchExperimentAssignment(
          experimentId: 'exp_match_1',
          variantId: 'distance_decay_v1',
          isControl: false,
        ),
      );

      await reporter.recordMatch(
        userId: 'u1',
        candidateId: 'c1',
        mode: 'Dating',
      );
      await reporter.flush();

      expect(writes, hasLength(1));
      final event = writes.single.single;
      expect(event.experimentId, 'exp_match_1');
      expect(event.variantId, 'distance_decay_v1');
    });

    test('records conversation quality metrics payload', () async {
      final writes = <List<MatchQualityEvent>>[];
      final reporter = MatchQualityReporter(
        now: () => DateTime(2026, 3, 8, 12),
        batchSize: 10,
        flushInterval: const Duration(days: 1),
        writer: (events) async =>
            writes.add(List<MatchQualityEvent>.from(events)),
      );

      await reporter.recordConversationQuality(
        userId: 'u1',
        mode: 'Dating',
        conversationDepth: 6,
        responseRate: 0.75,
        medianReplyDelayMs: 120000,
      );
      await reporter.flush();

      expect(writes, hasLength(1));
      final event = writes.single.single;
      expect(event.type, MatchQualityEventType.conversationQuality);
      expect(event.metadata?['conversationDepth'], 6);
      expect(event.metadata?['responseRate'], 0.75);
      expect(event.metadata?['medianReplyDelayMs'], 120000);
    });

    test('continues recording when experiment resolver throws', () async {
      final writes = <List<MatchQualityEvent>>[];
      final reporter = MatchQualityReporter(
        now: () => DateTime(2026, 3, 8, 12),
        batchSize: 10,
        flushInterval: const Duration(days: 1),
        writer: (events) async =>
            writes.add(List<MatchQualityEvent>.from(events)),
        experimentResolver: (_) async => throw StateError('resolver down'),
      );

      await reporter.recordAction(
        userId: 'u1',
        candidateId: 'c1',
        mode: 'Dating',
        actionType: MatchQualityActionType.connect,
      );
      await reporter.flush();

      expect(writes, hasLength(1));
      final event = writes.single.single;
      expect(event.type, MatchQualityEventType.action);
      expect(event.experimentId, isNull);
      expect(event.variantId, isNull);
    });

    test('records without experiment metadata when resolver returns null',
        () async {
      final writes = <List<MatchQualityEvent>>[];
      final reporter = MatchQualityReporter(
        now: () => DateTime(2026, 3, 8, 12),
        batchSize: 10,
        flushInterval: const Duration(days: 1),
        writer: (events) async =>
            writes.add(List<MatchQualityEvent>.from(events)),
        experimentResolver: (_) async => null,
      );

      await reporter.recordMatch(
        userId: 'u1',
        candidateId: 'c1',
        mode: 'Dating',
      );
      await reporter.flush();

      expect(writes, hasLength(1));
      final event = writes.single.single;
      expect(event.type, MatchQualityEventType.match);
      expect(event.experimentId, isNull);
      expect(event.variantId, isNull);
    });

    test('recordLatency with null userId skips experiment resolution',
        () async {
      final writes = <List<MatchQualityEvent>>[];
      var resolverCalls = 0;
      final reporter = MatchQualityReporter(
        now: () => DateTime(2026, 3, 8, 12),
        batchSize: 10,
        flushInterval: const Duration(days: 1),
        writer: (events) async =>
            writes.add(List<MatchQualityEvent>.from(events)),
        experimentResolver: (_) async {
          resolverCalls++;
          return null;
        },
      );

      await reporter.recordLatency(
        operation: 'discover_load',
        latencyMs: 90,
        mode: 'Dating',
      );
      await reporter.flush();

      expect(resolverCalls, 0);
      expect(writes, hasLength(1));
      final event = writes.single.single;
      expect(event.userIdHash, 'anonymous');
      expect(event.experimentId, isNull);
      expect(event.variantId, isNull);
    });

    test('dispose cancels scheduled timer flush', () async {
      final writes = <List<MatchQualityEvent>>[];
      final reporter = MatchQualityReporter(
        now: () => DateTime(2026, 3, 8, 12),
        batchSize: 50,
        flushInterval: const Duration(milliseconds: 10),
        writer: (events) async =>
            writes.add(List<MatchQualityEvent>.from(events)),
      );

      await reporter.recordImpression(
        userId: 'u1',
        candidateId: 'c1',
        mode: 'Dating',
      );
      reporter.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(writes, isEmpty);
    });
  });
}
