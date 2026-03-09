import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/services/match_config.dart';
import 'package:naijasingles/services/match_tuning_config.dart';
import 'package:naijasingles/services/match_tuning_config_loader.dart';

void main() {
  group('MatchTuningConfig', () {
    test('falls back to defaults for null payload', () {
      final config = MatchTuningConfig.fromMapOrDefaults(null);
      expect(config.version, MatchTuningConfig.defaults.version);
      expect(config.rollbackKey, MatchTuningConfig.defaults.rollbackKey);
    });

    test('falls back to defaults for empty payload', () {
      final config = MatchTuningConfig.fromMapOrDefaults(<String, dynamic>{});
      expect(config.version, MatchTuningConfig.defaults.version);
      expect(config.rollbackKey, MatchTuningConfig.defaults.rollbackKey);
    });

    test('falls back to defaults when required keys are missing', () {
      final missingVersion = MatchTuningConfig.fromMapOrDefaults({
        'rollbackKey': 'rk',
      });
      final missingRollback = MatchTuningConfig.fromMapOrDefaults({
        'version': 'v1',
      });
      expect(missingVersion.version, MatchTuningConfig.defaults.version);
      expect(missingRollback.version, MatchTuningConfig.defaults.version);
    });

    test('falls back to defaults for invalid payload type mismatch', () {
      final config = MatchTuningConfig.fromMapOrDefaults({
        'version': 123,
        'rollbackKey': 'rk',
      });
      expect(config.version, MatchTuningConfig.defaults.version);
    });

    test('applies bounded deltas to base weights', () {
      const base = MatchConfig.defaults;
      final tuning = MatchTuningConfig.fromMapOrDefaults({
        'version': 'v1',
        'rollbackKey': 'rk_1',
        'maxWeightDelta': 0.05,
        'datingWeights': {
          'age': 0.60,
          'location': 0.10,
        },
      });

      final tuned = tuning.applyTo(base);

      expect(tuned.datingWeights.age, closeTo(0.35, 0.00001));
      expect(tuned.datingWeights.location, closeTo(0.20, 0.00001));
      expect(
        tuned.datingWeights.lifestyle,
        closeTo(base.datingWeights.lifestyle, 0.00001),
      );
    });

    test('keeps base values when incoming field is missing/zero', () {
      const base = MatchConfig.defaults;
      final tuning = MatchTuningConfig.fromMapOrDefaults({
        'version': 'v2',
        'rollbackKey': 'rk_2',
        'datingWeights': {'age': 0.0},
      });

      final tuned = tuning.applyTo(base);
      expect(tuned.datingWeights.age, base.datingWeights.age);
    });

    test('clamps maxWeightDelta into safe range', () {
      final low = MatchTuningConfig.fromMapOrDefaults({
        'version': 'v1',
        'rollbackKey': 'rk',
        'maxWeightDelta': -1,
      });
      final high = MatchTuningConfig.fromMapOrDefaults({
        'version': 'v2',
        'rollbackKey': 'rk',
        'maxWeightDelta': 99,
      });

      expect(low.maxWeightDelta, 0.01);
      expect(high.maxWeightDelta, 0.20);
    });

    test('applies bounded location and floor values', () {
      const base = MatchConfig.defaults;
      final tuning = MatchTuningConfig.fromMapOrDefaults({
        'version': 'v3',
        'rollbackKey': 'rk',
        'locationPerfectMiles': 1000,
        'locationDecayMiles': 1,
        'locationFloorScore': 3,
      });

      final tuned = tuning.applyTo(base);

      expect(tuned.locationPerfectMiles, closeTo(6.5, 0.00001));
      expect(tuned.locationDecayMiles, closeTo(35.0, 0.00001));
      expect(tuned.locationFloorScore, 1.0);
    });

    test('applyTo is deterministic for the same input', () {
      const base = MatchConfig.defaults;
      final tuning = MatchTuningConfig.fromMapOrDefaults({
        'version': 'v4',
        'rollbackKey': 'rk',
        'maxWeightDelta': 0.05,
        'networkingWeights': {
          'professional': 0.9,
        },
      });

      final first = tuning.applyTo(base);
      final second = tuning.applyTo(base);

      expect(
        first.networkingWeights.professional,
        second.networkingWeights.professional,
      );
      expect(first.locationDecayMiles, second.locationDecayMiles);
    });
  });

  group('MatchTuningConfigLoader', () {
    test('loads config from source', () async {
      final loader = MatchTuningConfigLoader(
        source: () async => {
          'version': 'remote_v1',
          'rollbackKey': 'rk_remote',
        },
      );

      final loaded = await loader.load();
      expect(loaded.version, 'remote_v1');
      expect(loaded.rollbackKey, 'rk_remote');
    });

    test('falls back to defaults when source throws', () async {
      final loader = MatchTuningConfigLoader(
        source: () async => throw StateError('source failed'),
      );

      final loaded = await loader.load();
      expect(loaded.version, MatchTuningConfig.defaults.version);
    });
  });
}
