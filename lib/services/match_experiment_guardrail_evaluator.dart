enum MatchExperimentDecision {
  promote,
  hold,
  rollback,
}

class MatchExperimentMetrics {
  const MatchExperimentMetrics({
    required this.connectToMatchRate,
    required this.matchToFirstMessageRate,
    required this.conversationRetention7dRate,
    required this.sampleSize,
    this.responseRate,
    this.medianReplyDelayMs,
    this.conversationDepth,
  });

  final double connectToMatchRate;
  final double matchToFirstMessageRate;
  final double conversationRetention7dRate;
  final int sampleSize;
  final double? responseRate;
  final double? medianReplyDelayMs;
  final double? conversationDepth;
}

class MatchExperimentGuardrailConfig {
  const MatchExperimentGuardrailConfig({
    this.minSampleSize = 200,
    this.minConnectToMatchLift = 0.0,
    this.minMatchToFirstMessageLift = 0.0,
    this.maxRetentionDrop = 0.0,
    this.minResponseRateLift,
    this.minConversationDepthLift,
    this.maxMedianReplyDelayIncreaseMs,
  });

  final int minSampleSize;
  final double minConnectToMatchLift;
  final double minMatchToFirstMessageLift;
  final double maxRetentionDrop;
  final double? minResponseRateLift;
  final double? minConversationDepthLift;
  final double? maxMedianReplyDelayIncreaseMs;
}

class MatchExperimentEvaluation {
  const MatchExperimentEvaluation({
    required this.decision,
    required this.connectToMatchDelta,
    required this.matchToFirstMessageDelta,
    required this.retention7dDelta,
    required this.reasons,
    this.responseRateDelta,
    this.medianReplyDelayDeltaMs,
    this.conversationDepthDelta,
  });

  final MatchExperimentDecision decision;
  final double connectToMatchDelta;
  final double matchToFirstMessageDelta;
  final double retention7dDelta;
  final double? responseRateDelta;
  final double? medianReplyDelayDeltaMs;
  final double? conversationDepthDelta;
  final List<String> reasons;
}

class MatchExperimentGuardrailEvaluator {
  const MatchExperimentGuardrailEvaluator();

  MatchExperimentEvaluation evaluate({
    required MatchExperimentMetrics baseline,
    required MatchExperimentMetrics variant,
    MatchExperimentGuardrailConfig config =
        const MatchExperimentGuardrailConfig(),
  }) {
    final connectDelta =
        variant.connectToMatchRate - baseline.connectToMatchRate;
    final messageDelta =
        variant.matchToFirstMessageRate - baseline.matchToFirstMessageRate;
    final retentionDelta = variant.conversationRetention7dRate -
        baseline.conversationRetention7dRate;
    final responseRateDelta =
        _delta(variant.responseRate, baseline.responseRate);
    final medianReplyDelayDeltaMs =
        _delta(variant.medianReplyDelayMs, baseline.medianReplyDelayMs);
    final conversationDepthDelta =
        _delta(variant.conversationDepth, baseline.conversationDepth);

    final reasons = <String>[];
    if (baseline.sampleSize < config.minSampleSize ||
        variant.sampleSize < config.minSampleSize) {
      reasons.add('insufficient_sample_size');
      return MatchExperimentEvaluation(
        decision: MatchExperimentDecision.hold,
        connectToMatchDelta: connectDelta,
        matchToFirstMessageDelta: messageDelta,
        retention7dDelta: retentionDelta,
        responseRateDelta: responseRateDelta,
        medianReplyDelayDeltaMs: medianReplyDelayDeltaMs,
        conversationDepthDelta: conversationDepthDelta,
        reasons: reasons,
      );
    }

    final retentionDrop = -retentionDelta;
    if (retentionDrop > config.maxRetentionDrop) {
      reasons.add('retention_guardrail_breached');
      return MatchExperimentEvaluation(
        decision: MatchExperimentDecision.rollback,
        connectToMatchDelta: connectDelta,
        matchToFirstMessageDelta: messageDelta,
        retention7dDelta: retentionDelta,
        responseRateDelta: responseRateDelta,
        medianReplyDelayDeltaMs: medianReplyDelayDeltaMs,
        conversationDepthDelta: conversationDepthDelta,
        reasons: reasons,
      );
    }

    if (config.maxMedianReplyDelayIncreaseMs != null) {
      if (medianReplyDelayDeltaMs == null) {
        reasons.add('median_reply_delay_metric_missing');
      } else if (medianReplyDelayDeltaMs >
          config.maxMedianReplyDelayIncreaseMs!) {
        reasons.add('median_reply_delay_guardrail_breached');
        return MatchExperimentEvaluation(
          decision: MatchExperimentDecision.rollback,
          connectToMatchDelta: connectDelta,
          matchToFirstMessageDelta: messageDelta,
          retention7dDelta: retentionDelta,
          responseRateDelta: responseRateDelta,
          medianReplyDelayDeltaMs: medianReplyDelayDeltaMs,
          conversationDepthDelta: conversationDepthDelta,
          reasons: reasons,
        );
      }
    }

    final connectPass = connectDelta >= config.minConnectToMatchLift;
    final messagePass = messageDelta >= config.minMatchToFirstMessageLift;
    final responsePass =
        _passesOptionalMinDelta(responseRateDelta, config.minResponseRateLift);
    final depthPass = _passesOptionalMinDelta(
      conversationDepthDelta,
      config.minConversationDepthLift,
    );
    if (connectPass && messagePass && responsePass && depthPass) {
      reasons.add('kpi_lift_within_guardrails');
      return MatchExperimentEvaluation(
        decision: MatchExperimentDecision.promote,
        connectToMatchDelta: connectDelta,
        matchToFirstMessageDelta: messageDelta,
        retention7dDelta: retentionDelta,
        responseRateDelta: responseRateDelta,
        medianReplyDelayDeltaMs: medianReplyDelayDeltaMs,
        conversationDepthDelta: conversationDepthDelta,
        reasons: reasons,
      );
    }

    if (!connectPass) {
      reasons.add('connect_to_match_lift_below_threshold');
    }
    if (!messagePass) {
      reasons.add('match_to_message_lift_below_threshold');
    }
    final minResponseRateLift = config.minResponseRateLift;
    if (minResponseRateLift != null) {
      if (responseRateDelta == null) {
        reasons.add('response_rate_metric_missing');
      } else if (responseRateDelta < minResponseRateLift) {
        reasons.add('response_rate_lift_below_threshold');
      }
    }
    final minConversationDepthLift = config.minConversationDepthLift;
    if (minConversationDepthLift != null) {
      if (conversationDepthDelta == null) {
        reasons.add('conversation_depth_metric_missing');
      } else if (conversationDepthDelta < minConversationDepthLift) {
        reasons.add('conversation_depth_lift_below_threshold');
      }
    }
    if (config.maxMedianReplyDelayIncreaseMs != null &&
        medianReplyDelayDeltaMs == null) {
      reasons.add('median_reply_delay_metric_missing');
    }
    return MatchExperimentEvaluation(
      decision: MatchExperimentDecision.hold,
      connectToMatchDelta: connectDelta,
      matchToFirstMessageDelta: messageDelta,
      retention7dDelta: retentionDelta,
      responseRateDelta: responseRateDelta,
      medianReplyDelayDeltaMs: medianReplyDelayDeltaMs,
      conversationDepthDelta: conversationDepthDelta,
      reasons: reasons,
    );
  }

  double? _delta(double? variant, double? baseline) {
    if (variant == null || baseline == null) {
      return null;
    }
    return variant - baseline;
  }

  bool _passesOptionalMinDelta(double? delta, double? threshold) {
    if (threshold == null) {
      return true;
    }
    if (delta == null) {
      return false;
    }
    return delta >= threshold;
  }
}
