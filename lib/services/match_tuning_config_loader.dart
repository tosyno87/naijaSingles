import '../common/utils/app_logger.dart';
import 'match_tuning_config.dart';

typedef MatchTuningSource = Future<Map<String, dynamic>?> Function();

class MatchTuningConfigLoader {
  MatchTuningConfigLoader({required MatchTuningSource source})
      : _source = source;

  final MatchTuningSource _source;

  Future<MatchTuningConfig> load() async {
    try {
      final raw = await _source();
      return MatchTuningConfig.fromMapOrDefaults(raw);
    } on Object catch (e, st) {
      AppLogger.warning(
        'Failed to load remote match tuning config; using defaults',
        error: e,
        stackTrace: st,
      );
      return MatchTuningConfig.defaults;
    }
  }
}
