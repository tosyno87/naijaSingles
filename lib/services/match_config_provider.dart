import 'match_config.dart';
import 'match_experiment_assignment.dart';
import 'match_tuning_config.dart';
import 'match_tuning_config_loader.dart';
import 'match_tuning_remote_source.dart';

/// Cached runtime provider for match scoring config.
///
/// Defaults are always used when remote payloads are missing or invalid.
class MatchConfigProvider {
  MatchConfigProvider({
    MatchTuningConfigLoader? loader,
    MatchTuningRemoteSource? remoteSource,
    MatchExperimentAssigner? assigner,
    DateTime Function()? now,
    this.refreshInterval = const Duration(minutes: 10),
  })  : _remoteSource = remoteSource ?? MatchTuningRemoteSource(),
        _loader = loader,
        _assigner = assigner ?? const MatchExperimentAssigner(),
        _now = now ?? DateTime.now;

  static final MatchConfigProvider instance = MatchConfigProvider();

  final MatchTuningConfigLoader? _loader;
  final MatchTuningRemoteSource _remoteSource;
  final MatchExperimentAssigner _assigner;
  final DateTime Function() _now;
  final Duration refreshInterval;

  MatchConfig _cached = MatchConfig.defaults;
  MatchExperimentConfig? _experimentConfig;
  DateTime? _lastLoadedAt;
  bool _loading = false;

  Future<MatchConfig> getCurrentConfig({bool forceRefresh = false}) async {
    final shouldRefresh =
        forceRefresh || _lastLoadedAt == null || _isStale(_lastLoadedAt!);
    if (!shouldRefresh || _loading) {
      return _cached;
    }

    _loading = true;
    try {
      final rawRemoteConfig = await _remoteSource.loadRawDocument();
      final tuning = await _loadBaseTuning(rawRemoteConfig);
      _cached = tuning.applyTo(MatchConfig.defaults);
      _experimentConfig = MatchExperimentConfig.fromRaw(rawRemoteConfig);
      _lastLoadedAt = _now();
      return _cached;
    } finally {
      _loading = false;
    }
  }

  Future<MatchConfig> getCurrentConfigForUser(
    String? userId, {
    bool forceRefresh = false,
  }) async {
    final base = await getCurrentConfig(forceRefresh: forceRefresh);
    if (userId == null || userId.isEmpty) {
      return base;
    }

    final assignment = _assigner.assign(userId, _experimentConfig);
    if (assignment == null || assignment.isControl) {
      return base;
    }

    MatchExperimentVariant? selectedVariant;
    for (final variant in _experimentConfig?.variants ?? const []) {
      if (variant.id == assignment.variantId) {
        selectedVariant = variant;
        break;
      }
    }
    if (selectedVariant == null) {
      return base;
    }

    final variantPayload = _normalizeVariantPayload(
      selectedVariant.payload,
      assignment,
    );
    final variantTuning =
        MatchTuningConfigLoader(source: () async => variantPayload);
    final tuning = await variantTuning.load();
    // Variant payloads are treated as deltas on top of refreshed base tuning.
    return tuning.applyTo(base);
  }

  Future<MatchExperimentAssignment?> getAssignmentForUser(
    String? userId, {
    bool forceRefresh = false,
  }) async {
    if (userId == null || userId.isEmpty) {
      return null;
    }
    await getCurrentConfig(forceRefresh: forceRefresh);
    return _assigner.assign(userId, _experimentConfig);
  }

  Map<String, dynamic> _normalizeVariantPayload(
    Map<String, dynamic> payload,
    MatchExperimentAssignment assignment,
  ) {
    final normalized = Map<String, dynamic>.from(payload);
    normalized.putIfAbsent(
      'version',
      () => '${assignment.experimentId}:${assignment.variantId}',
    );
    normalized.putIfAbsent(
      'rollbackKey',
      () => 'rollback_${assignment.experimentId}_${assignment.variantId}',
    );
    return normalized;
  }

  Future<MatchTuningConfig> _loadBaseTuning(
    Map<String, dynamic>? rawRemoteConfig,
  ) async {
    if (_loader != null) {
      return _loader.load();
    }
    return MatchTuningConfig.fromMapOrDefaults(
      _extractPayload(rawRemoteConfig),
    );
  }

  Map<String, dynamic>? _extractPayload(Map<String, dynamic>? rawRemoteConfig) {
    if (rawRemoteConfig == null || rawRemoteConfig.isEmpty) {
      return null;
    }
    final payload = rawRemoteConfig['payload'];
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return rawRemoteConfig;
  }

  bool _isStale(DateTime loadedAt) =>
      _now().difference(loadedAt) >= refreshInterval;
}
