import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/services/match_experiment_guardrail_evaluator.dart';

void main() {
  group('MatchExperimentGuardrailEvaluator', () {
    const evaluator = MatchExperimentGuardrailEvaluator();
    const config = MatchExperimentGuardrailConfig(
      minSampleSize: 100,
      minConnectToMatchLift: 0.01,
      minMatchToFirstMessageLift: 0.01,
      maxRetentionDrop: 0.0,
    );

    const baseline = MatchExperimentMetrics(
      connectToMatchRate: 0.20,
      matchToFirstMessageRate: 0.40,
      conversationRetention7dRate: 0.30,
      sampleSize: 200,
    );

    test('promotes when both KPI lifts pass and retention does not drop', () {
      const variant = MatchExperimentMetrics(
        connectToMatchRate: 0.22,
        matchToFirstMessageRate: 0.42,
        conversationRetention7dRate: 0.30,
        sampleSize: 220,
      );

      final result = evaluator.evaluate(
        baseline: baseline,
        variant: variant,
        config: config,
      );

      expect(result.decision, MatchExperimentDecision.promote);
      expect(result.reasons, contains('kpi_lift_within_guardrails'));
    });

    test('rolls back when retention guardrail is breached', () {
      const variant = MatchExperimentMetrics(
        connectToMatchRate: 0.24,
        matchToFirstMessageRate: 0.45,
        conversationRetention7dRate: 0.28,
        sampleSize: 220,
      );

      final result = evaluator.evaluate(
        baseline: baseline,
        variant: variant,
        config: config,
      );

      expect(result.decision, MatchExperimentDecision.rollback);
      expect(result.reasons, contains('retention_guardrail_breached'));
    });

    test('holds when sample size is insufficient', () {
      const variant = MatchExperimentMetrics(
        connectToMatchRate: 0.24,
        matchToFirstMessageRate: 0.45,
        conversationRetention7dRate: 0.32,
        sampleSize: 60,
      );

      final result = evaluator.evaluate(
        baseline: baseline,
        variant: variant,
        config: config,
      );

      expect(result.decision, MatchExperimentDecision.hold);
      expect(result.reasons, contains('insufficient_sample_size'));
    });

    test('holds when KPI lift thresholds are not met', () {
      const variant = MatchExperimentMetrics(
        connectToMatchRate: 0.205,
        matchToFirstMessageRate: 0.405,
        conversationRetention7dRate: 0.31,
        sampleSize: 220,
      );

      final result = evaluator.evaluate(
        baseline: baseline,
        variant: variant,
        config: config,
      );

      expect(result.decision, MatchExperimentDecision.hold);
      expect(
        result.reasons,
        containsAll(<String>[
          'connect_to_match_lift_below_threshold',
          'match_to_message_lift_below_threshold',
        ]),
      );
    });

    test('rolls back when median reply delay guardrail is breached', () {
      const qualityConfig = MatchExperimentGuardrailConfig(
        minSampleSize: 100,
        minConnectToMatchLift: 0.01,
        minMatchToFirstMessageLift: 0.01,
        maxRetentionDrop: 0.0,
        maxMedianReplyDelayIncreaseMs: 1000,
      );
      const qualityBaseline = MatchExperimentMetrics(
        connectToMatchRate: 0.20,
        matchToFirstMessageRate: 0.40,
        conversationRetention7dRate: 0.30,
        sampleSize: 200,
        medianReplyDelayMs: 30000,
      );
      const qualityVariant = MatchExperimentMetrics(
        connectToMatchRate: 0.25,
        matchToFirstMessageRate: 0.50,
        conversationRetention7dRate: 0.31,
        sampleSize: 250,
        medianReplyDelayMs: 32050,
      );

      final result = evaluator.evaluate(
        baseline: qualityBaseline,
        variant: qualityVariant,
        config: qualityConfig,
      );
      expect(result.decision, MatchExperimentDecision.rollback);
      expect(result.reasons, contains('median_reply_delay_guardrail_breached'));
    });

    test('holds when configured quality metrics are missing', () {
      const qualityConfig = MatchExperimentGuardrailConfig(
        minSampleSize: 100,
        minConnectToMatchLift: 0.01,
        minMatchToFirstMessageLift: 0.01,
        maxRetentionDrop: 0.0,
        minResponseRateLift: 0.01,
      );
      const qualityVariant = MatchExperimentMetrics(
        connectToMatchRate: 0.22,
        matchToFirstMessageRate: 0.42,
        conversationRetention7dRate: 0.30,
        sampleSize: 220,
      );

      final result = evaluator.evaluate(
        baseline: baseline,
        variant: qualityVariant,
        config: qualityConfig,
      );
      expect(result.decision, MatchExperimentDecision.hold);
      expect(result.reasons, contains('response_rate_metric_missing'));
    });
  });
}
