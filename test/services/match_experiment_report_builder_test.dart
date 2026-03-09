import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/services/match_experiment_guardrail_evaluator.dart';
import 'package:naijasingles/services/match_experiment_report_builder.dart';

void main() {
  group('MatchExperimentReportInput', () {
    test('parses valid map with optional guardrails', () {
      final input = MatchExperimentReportInput.fromMap({
        'experimentId': 'exp_match_1',
        'baselineVariantId': 'control',
        'variantId': 'distance_decay_v1',
        'baseline': {
          'connectToMatchRate': 0.20,
          'matchToFirstMessageRate': 0.40,
          'conversationRetention7dRate': 0.30,
          'responseRate': 0.50,
          'medianReplyDelayMs': 45000,
          'conversationDepth': 6.0,
          'sampleSize': 500,
        },
        'variant': {
          'connectToMatchRate': 0.23,
          'matchToFirstMessageRate': 0.43,
          'conversationRetention7dRate': 0.31,
          'responseRate': 0.55,
          'medianReplyDelayMs': 43000,
          'conversationDepth': 6.7,
          'sampleSize': 520,
        },
        'guardrails': {
          'minSampleSize': 200,
          'minConnectToMatchLift': 0.01,
          'minMatchToFirstMessageLift': 0.01,
          'maxRetentionDrop': 0.01,
          'minResponseRateLift': 0.01,
          'minConversationDepthLift': 0.1,
          'maxMedianReplyDelayIncreaseMs': 5000,
        },
      });

      expect(input.experimentId, 'exp_match_1');
      expect(input.variantId, 'distance_decay_v1');
      expect(input.guardrails.minSampleSize, 200);
      expect(input.baseline.responseRate, 0.50);
      expect(input.variant.conversationDepth, 6.7);
      expect(input.guardrails.minResponseRateLift, 0.01);
    });

    test('throws on missing required fields', () {
      expect(
        () => MatchExperimentReportInput.fromMap({
          'experimentId': 'exp_match_1',
        }),
        throwsFormatException,
      );
    });

    test('uses default guardrails when guardrails key is omitted', () {
      final input = MatchExperimentReportInput.fromMap({
        'experimentId': 'exp_match_1',
        'baselineVariantId': 'control',
        'variantId': 'distance_decay_v1',
        'baseline': {
          'connectToMatchRate': 0.20,
          'matchToFirstMessageRate': 0.40,
          'conversationRetention7dRate': 0.30,
          'sampleSize': 500,
        },
        'variant': {
          'connectToMatchRate': 0.23,
          'matchToFirstMessageRate': 0.43,
          'conversationRetention7dRate': 0.31,
          'sampleSize': 520,
        },
      });

      expect(input.guardrails.minSampleSize, 200);
      expect(input.guardrails.minConnectToMatchLift, 0.0);
      expect(input.guardrails.minMatchToFirstMessageLift, 0.0);
      expect(input.guardrails.maxRetentionDrop, 0.0);
    });
  });

  group('MatchExperimentReportBuilder', () {
    test('builds machine-readable promote report', () {
      final input = MatchExperimentReportInput.fromMap({
        'experimentId': 'exp_match_1',
        'baselineVariantId': 'control',
        'variantId': 'distance_decay_v1',
        'baseline': {
          'connectToMatchRate': 0.20,
          'matchToFirstMessageRate': 0.40,
          'conversationRetention7dRate': 0.30,
          'responseRate': 0.50,
          'medianReplyDelayMs': 45000,
          'conversationDepth': 6.0,
          'sampleSize': 500,
        },
        'variant': {
          'connectToMatchRate': 0.22,
          'matchToFirstMessageRate': 0.42,
          'conversationRetention7dRate': 0.30,
          'responseRate': 0.53,
          'medianReplyDelayMs': 43000,
          'conversationDepth': 6.4,
          'sampleSize': 520,
        },
        'guardrails': {
          'minSampleSize': 200,
          'minConnectToMatchLift': 0.01,
          'minMatchToFirstMessageLift': 0.01,
          'maxRetentionDrop': 0.0,
          'minResponseRateLift': 0.01,
          'minConversationDepthLift': 0.1,
          'maxMedianReplyDelayIncreaseMs': 5000,
        },
      });

      final report = const MatchExperimentReportBuilder().build(
        input,
        now: () => DateTime.utc(2026, 3, 8, 12),
      );
      final map = report.toMap();

      expect(map['decision'], MatchExperimentDecision.promote.name);
      expect(map['experimentId'], 'exp_match_1');
      expect(map['variantId'], 'distance_decay_v1');
      expect((map['reasons'] as List).isNotEmpty, isTrue);
      expect((map['deltas'] as Map)['connectToMatch'], closeTo(0.02, 0.000001));
      expect((map['deltas'] as Map)['responseRate'], closeTo(0.03, 0.000001));
      expect(
        (map['deltas'] as Map)['medianReplyDelayMs'],
        closeTo(-2000.0, 0.000001),
      );
      expect(
        (map['deltas'] as Map)['conversationDepth'],
        closeTo(0.4, 0.000001),
      );
    });
  });
}
