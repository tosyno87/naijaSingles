import 'match_config.dart';
import 'match_tuning_config_loader.dart';
import 'match_tuning_remote_source.dart';

/// Cached runtime provider for match scoring config.
///
/// Defaults are always used when remote payloads are missing or invalid.
class MatchConfigProvider {
  MatchConfigProvider({
    MatchTuningConfigLoader? loader,
    DateTime Function()? now,
    this.refreshInterval = const Duration(minutes: 10),
  })  : _loader = loader ??
            MatchTuningConfigLoader(
              source: MatchTuningRemoteSource().load,
            ),
        _now = now ?? DateTime.now;

  static final MatchConfigProvider instance = MatchConfigProvider();

  final MatchTuningConfigLoader _loader;
  final DateTime Function() _now;
  final Duration refreshInterval;

  MatchConfig _cached = MatchConfig.defaults;
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
      final tuning = await _loader.load();
      _cached = tuning.applyTo(MatchConfig.defaults);
      _lastLoadedAt = _now();
      return _cached;
    } finally {
      _loading = false;
    }
  }

  bool _isStale(DateTime loadedAt) =>
      _now().difference(loadedAt) >= refreshInterval;
}
