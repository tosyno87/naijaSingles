import 'match_experiment_guardrail_evaluator.dart';

class MatchExperimentReportInput {
  const MatchExperimentReportInput({
    required this.experimentId,
    required this.baselineVariantId,
    required this.variantId,
    required this.baseline,
    required this.variant,
    this.guardrails = const MatchExperimentGuardrailConfig(),
  });

  final String experimentId;
  final String baselineVariantId;
  final String variantId;
  final MatchExperimentMetrics baseline;
  final MatchExperimentMetrics variant;
  final MatchExperimentGuardrailConfig guardrails;

  static MatchExperimentReportInput fromMap(Map<String, dynamic> raw) {
    final experimentId = (raw['experimentId'] as String?)?.trim();
    final baselineVariantId =
        (raw['baselineVariantId'] as String?)?.trim() ?? 'control';
    final variantId = (raw['variantId'] as String?)?.trim();
    final baselineRaw = raw['baseline'];
    final variantRaw = raw['variant'];
    if (experimentId == null ||
        experimentId.isEmpty ||
        variantId == null ||
        variantId.isEmpty ||
        baselineRaw is! Map<String, dynamic> ||
        variantRaw is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid input: experimentId, variantId, baseline, and variant are required.',
      );
    }

    final guardrailsRaw = raw['guardrails'];
    return MatchExperimentReportInput(
      experimentId: experimentId,
      baselineVariantId: baselineVariantId,
      variantId: variantId,
      baseline: _metricsFromMap(baselineRaw),
      variant: _metricsFromMap(variantRaw),
      guardrails: guardrailsRaw is Map<String, dynamic>
          ? _guardrailsFromMap(guardrailsRaw)
          : const MatchExperimentGuardrailConfig(),
    );
  }

  static MatchExperimentMetrics _metricsFromMap(Map<String, dynamic> raw) {
    final connectToMatchRate = _asDouble(raw['connectToMatchRate']);
    final matchToFirstMessageRate = _asDouble(raw['matchToFirstMessageRate']);
    final conversationRetention7dRate =
        _asDouble(raw['conversationRetention7dRate']);
    final sampleSize = raw['sampleSize'];
    if (connectToMatchRate == null ||
        matchToFirstMessageRate == null ||
        conversationRetention7dRate == null ||
        sampleSize is! int) {
      throw const FormatException(
        'Invalid metrics: rates and sampleSize(int) are required.',
      );
    }
    return MatchExperimentMetrics(
      connectToMatchRate: connectToMatchRate,
      matchToFirstMessageRate: matchToFirstMessageRate,
      conversationRetention7dRate: conversationRetention7dRate,
      sampleSize: sampleSize,
      responseRate: _asDouble(raw['responseRate']),
      medianReplyDelayMs: _asDouble(raw['medianReplyDelayMs']),
      conversationDepth: _asDouble(raw['conversationDepth']),
    );
  }

  static MatchExperimentGuardrailConfig _guardrailsFromMap(
    Map<String, dynamic> raw,
  ) =>
      MatchExperimentGuardrailConfig(
        minSampleSize: (raw['minSampleSize'] as int?) ?? 200,
        minConnectToMatchLift: _asDouble(raw['minConnectToMatchLift']) ?? 0.0,
        minMatchToFirstMessageLift:
            _asDouble(raw['minMatchToFirstMessageLift']) ?? 0.0,
        maxRetentionDrop: _asDouble(raw['maxRetentionDrop']) ?? 0.0,
        minResponseRateLift: _asDouble(raw['minResponseRateLift']),
        minConversationDepthLift: _asDouble(raw['minConversationDepthLift']),
        maxMedianReplyDelayIncreaseMs:
            _asDouble(raw['maxMedianReplyDelayIncreaseMs']),
      );

  static double? _asDouble(Object? value) =>
      value is num ? value.toDouble() : null;
}

class MatchExperimentReport {
  const MatchExperimentReport({
    required this.experimentId,
    required this.baselineVariantId,
    required this.variantId,
    required this.generatedAt,
    required this.evaluation,
  });

  final String experimentId;
  final String baselineVariantId;
  final String variantId;
  final DateTime generatedAt;
  final MatchExperimentEvaluation evaluation;

  Map<String, dynamic> toMap() => {
        'experimentId': experimentId,
        'baselineVariantId': baselineVariantId,
        'variantId': variantId,
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'decision': evaluation.decision.name,
        'reasons': evaluation.reasons,
        'deltas': {
          'connectToMatch': evaluation.connectToMatchDelta,
          'matchToFirstMessage': evaluation.matchToFirstMessageDelta,
          'conversationRetention7d': evaluation.retention7dDelta,
          if (evaluation.responseRateDelta != null)
            'responseRate': evaluation.responseRateDelta,
          if (evaluation.medianReplyDelayDeltaMs != null)
            'medianReplyDelayMs': evaluation.medianReplyDelayDeltaMs,
          if (evaluation.conversationDepthDelta != null)
            'conversationDepth': evaluation.conversationDepthDelta,
        },
      };
}

class MatchExperimentReportBuilder {
  const MatchExperimentReportBuilder({
    MatchExperimentGuardrailEvaluator evaluator =
        const MatchExperimentGuardrailEvaluator(),
  }) : _evaluator = evaluator;

  final MatchExperimentGuardrailEvaluator _evaluator;

  MatchExperimentReport build(
    MatchExperimentReportInput input, {
    DateTime Function()? now,
  }) {
    final evaluation = _evaluator.evaluate(
      baseline: input.baseline,
      variant: input.variant,
      config: input.guardrails,
    );
    return MatchExperimentReport(
      experimentId: input.experimentId,
      baselineVariantId: input.baselineVariantId,
      variantId: input.variantId,
      generatedAt: (now ?? DateTime.now)(),
      evaluation: evaluation,
    );
  }
}
