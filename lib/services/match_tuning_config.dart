import '../common/utils/app_logger.dart';
import 'match_config.dart';

class MatchTuningConfig {
  const MatchTuningConfig({
    required this.version,
    required this.rollbackKey,
    required this.maxWeightDelta,
    required this.datingWeights,
    required this.friendshipWeights,
    required this.networkingWeights,
    this.locationPerfectMiles,
    this.locationDecayMiles,
    this.locationFloorScore,
  });

  static const MatchTuningConfig defaults = MatchTuningConfig(
    version: 'default',
    rollbackKey: 'match_tuning_default',
    maxWeightDelta: 0.08,
    datingWeights: ModeWeights(),
    friendshipWeights: ModeWeights(),
    networkingWeights: ModeWeights(),
  );

  final String version;
  final String rollbackKey;
  final double maxWeightDelta;
  final ModeWeights datingWeights;
  final ModeWeights friendshipWeights;
  final ModeWeights networkingWeights;
  final double? locationPerfectMiles;
  final double? locationDecayMiles;
  final double? locationFloorScore;

  static MatchTuningConfig fromMapOrDefaults(
    Map<String, dynamic>? raw,
  ) {
    if (raw == null || raw.isEmpty) {
      return defaults;
    }
    try {
      final version = (raw['version'] as String?)?.trim();
      final rollbackKey = (raw['rollbackKey'] as String?)?.trim();
      final maxWeightDelta =
          _asDouble(raw['maxWeightDelta']) ?? defaults.maxWeightDelta;

      if (version == null || version.isEmpty) {
        return defaults;
      }
      if (rollbackKey == null || rollbackKey.isEmpty) {
        return defaults;
      }

      return MatchTuningConfig(
        version: version,
        rollbackKey: rollbackKey,
        maxWeightDelta: maxWeightDelta.clamp(0.01, 0.20),
        datingWeights: _parseModeWeights(raw['datingWeights']),
        friendshipWeights: _parseModeWeights(raw['friendshipWeights']),
        networkingWeights: _parseModeWeights(raw['networkingWeights']),
        locationPerfectMiles: _asDouble(raw['locationPerfectMiles']),
        locationDecayMiles: _asDouble(raw['locationDecayMiles']),
        locationFloorScore: _asDouble(raw['locationFloorScore']),
      );
    } on Object catch (e, st) {
      AppLogger.warning(
        'Invalid match tuning config; using defaults',
        error: e,
        stackTrace: st,
      );
      return defaults;
    }
  }

  MatchConfig applyTo(MatchConfig base) => base.copyWith(
        datingWeights: _applyBounded(base.datingWeights, datingWeights),
        friendshipWeights:
            _applyBounded(base.friendshipWeights, friendshipWeights),
        networkingWeights:
            _applyBounded(base.networkingWeights, networkingWeights),
        locationPerfectMiles: _applyDistanceBound(
          base.locationPerfectMiles,
          locationPerfectMiles,
        ),
        locationDecayMiles:
            _applyDistanceBound(base.locationDecayMiles, locationDecayMiles),
        locationFloorScore:
            _applyFloorBound(base.locationFloorScore, locationFloorScore),
      );

  static ModeWeights _parseModeWeights(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const ModeWeights();
    }
    return ModeWeights(
      age: _asDouble(raw['age']) ?? 0.0,
      location: _asDouble(raw['location']) ?? 0.0,
      lifestyle: _asDouble(raw['lifestyle']) ?? 0.0,
      interest: _asDouble(raw['interest']) ?? 0.0,
      completeness: _asDouble(raw['completeness']) ?? 0.0,
      social: _asDouble(raw['social']) ?? 0.0,
      professional: _asDouble(raw['professional']) ?? 0.0,
      industry: _asDouble(raw['industry']) ?? 0.0,
    );
  }

  static double? _asDouble(Object? value) =>
      value is num ? value.toDouble() : null;

  ModeWeights _applyBounded(ModeWeights base, ModeWeights incoming) =>
      ModeWeights(
        age: _bounded(base.age, incoming.age),
        location: _bounded(base.location, incoming.location),
        lifestyle: _bounded(base.lifestyle, incoming.lifestyle),
        interest: _bounded(base.interest, incoming.interest),
        completeness: _bounded(base.completeness, incoming.completeness),
        social: _bounded(base.social, incoming.social),
        professional: _bounded(base.professional, incoming.professional),
        industry: _bounded(base.industry, incoming.industry),
      );

  double _bounded(double base, double incoming) {
    // 0.0 is a deliberate "not provided" sentinel to keep base unchanged.
    if (incoming == 0.0) {
      return base;
    }
    final min = (base - maxWeightDelta).clamp(0.0, 1.0);
    final max = (base + maxWeightDelta).clamp(0.0, 1.0);
    return incoming.clamp(min, max);
  }

  static double _applyDistanceBound(double base, double? incoming) {
    if (incoming == null) {
      return base;
    }
    final min = (base * 0.7).clamp(1.0, 500.0);
    final max = (base * 1.3).clamp(1.0, 500.0);
    return incoming.clamp(min, max);
  }

  static double _applyFloorBound(double base, double? incoming) {
    if (incoming == null) {
      return base;
    }
    return incoming.clamp(0.0, 1.0);
  }
}
