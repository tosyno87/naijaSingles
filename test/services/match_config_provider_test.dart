import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/services/match_config.dart';
import 'package:naijasingles/services/match_config_provider.dart';
import 'package:naijasingles/services/match_experiment_assignment.dart';
import 'package:naijasingles/services/match_tuning_config_loader.dart';
import 'package:naijasingles/services/match_tuning_remote_source.dart';

class _FixedAssigner extends MatchExperimentAssigner {
  const _FixedAssigner(this._assignment);

  final MatchExperimentAssignment? _assignment;

  @override
  MatchExperimentAssignment? assign(
    String userId,
    MatchExperimentConfig? experiment,
  ) =>
      _assignment;
}

void main() {
  group('MatchTuningRemoteSource', () {
    test('reads config from payload field when present', () async {
      final source = MatchTuningRemoteSource(
        fetcher: () async => {
          'payload': {
            'version': 'v1',
            'rollbackKey': 'rk_1',
          },
        },
      );

      final raw = await source.load();
      expect(raw?['version'], 'v1');
      expect(raw?['rollbackKey'], 'rk_1');
    });

    test('supports top-level config payload for compatibility', () async {
      final source = MatchTuningRemoteSource(
        fetcher: () async => {
          'version': 'v2',
          'rollbackKey': 'rk_2',
        },
      );

      final raw = await source.load();
      expect(raw?['version'], 'v2');
      expect(raw?['rollbackKey'], 'rk_2');
    });

    test('returns null when source payload is empty', () async {
      final source = MatchTuningRemoteSource(
        fetcher: () async => <String, dynamic>{},
      );

      final raw = await source.load();
      expect(raw, isNull);
    });

    test('returns null when source throws', () async {
      final source = MatchTuningRemoteSource(
        fetcher: () async => throw StateError('unavailable'),
      );

      final raw = await source.load();
      expect(raw, isNull);
    });
  });

  group('MatchConfigProvider', () {
    test('default path reads remote document only once per refresh', () async {
      var fetchCalls = 0;
      final provider = MatchConfigProvider(
        remoteSource: MatchTuningRemoteSource(
          fetcher: () async {
            fetchCalls++;
            return {
              'payload': {
                'version': 'v1',
                'rollbackKey': 'rk_1',
              },
            };
          },
        ),
      );

      await provider.getCurrentConfig(forceRefresh: true);
      await provider.getCurrentConfig();

      expect(fetchCalls, 1);
    });

    test('applies loaded tuning to defaults', () async {
      final provider = MatchConfigProvider(
        loader: MatchTuningConfigLoader(
          source: () async => {
            'version': 'v1',
            'rollbackKey': 'rk_1',
            'maxWeightDelta': 0.05,
            'datingWeights': {'age': 0.60},
          },
        ),
      );

      final config = await provider.getCurrentConfig(forceRefresh: true);
      expect(config.datingWeights.age, closeTo(0.35, 0.00001));
    });

    test('caches config until refresh interval expires', () async {
      var calls = 0;
      var now = DateTime(2026, 3, 8, 12, 0);
      final provider = MatchConfigProvider(
        loader: MatchTuningConfigLoader(
          source: () async {
            calls++;
            return {
              'version': 'v1',
              'rollbackKey': 'rk_1',
            };
          },
        ),
        now: () => now,
        refreshInterval: const Duration(minutes: 10),
      );

      final first = await provider.getCurrentConfig();
      now = now.add(const Duration(minutes: 5));
      final second = await provider.getCurrentConfig();
      now = now.add(const Duration(minutes: 6));
      final third = await provider.getCurrentConfig();

      expect(first.locationDecayMiles, MatchConfig.defaults.locationDecayMiles);
      expect(
          second.locationDecayMiles, MatchConfig.defaults.locationDecayMiles);
      expect(third.locationDecayMiles, MatchConfig.defaults.locationDecayMiles);
      expect(calls, 2);
    });

    test('forceRefresh reloads config even within refresh interval', () async {
      var calls = 0;
      final provider = MatchConfigProvider(
        loader: MatchTuningConfigLoader(
          source: () async {
            calls++;
            return {
              'version': 'v$calls',
              'rollbackKey': 'rk_$calls',
            };
          },
        ),
        refreshInterval: const Duration(hours: 1),
      );

      await provider.getCurrentConfig();
      await provider.getCurrentConfig();
      await provider.getCurrentConfig(forceRefresh: true);

      expect(calls, 2);
    });

    test('returns defaults when upstream source fails', () async {
      final provider = MatchConfigProvider(
        loader: MatchTuningConfigLoader(
          source: () async => throw StateError('remote failed'),
        ),
      );

      final config = await provider.getCurrentConfig(forceRefresh: true);
      expect(config.datingWeights.age, MatchConfig.defaults.datingWeights.age);
      expect(
        config.friendshipWeights.social,
        MatchConfig.defaults.friendshipWeights.social,
      );
      expect(
          config.locationDecayMiles, MatchConfig.defaults.locationDecayMiles);
    });

    test('returns variant config for deterministic non-control assignment',
        () async {
      final provider = MatchConfigProvider(
        assigner: const _FixedAssigner(
          MatchExperimentAssignment(
            experimentId: 'exp_match_1',
            variantId: 'distance_decay_v1',
            isControl: false,
          ),
        ),
        remoteSource: MatchTuningRemoteSource(
          fetcher: () async => {
            'payload': {
              'version': 'baseline_v1',
              'rollbackKey': 'rk_base',
              'locationDecayMiles': 45,
            },
            'experiment': {
              'id': 'exp_match_1',
              'active': true,
              'seed': 'seed_1',
              'controlVariantId': 'control',
              'variants': [
                {
                  'id': 'control',
                  'weight': 1,
                  'payload': {
                    'version': 'control_v1',
                    'rollbackKey': 'rk_control',
                  },
                },
                {
                  'id': 'distance_decay_v1',
                  'weight': 1,
                  'payload': {
                    'version': 'variant_v1',
                    'rollbackKey': 'rk_variant',
                    'locationDecayMiles': 65,
                  },
                },
              ],
            },
          },
        ),
      );

      final config = await provider.getCurrentConfigForUser('user-variant-a');
      // Base (45) with +/-30% distance guardrail clamps 65 to 58.5.
      expect(config.locationDecayMiles, closeTo(58.5, 0.00001));
    });

    test('inactive experiment falls back to base config', () async {
      final provider = MatchConfigProvider(
        remoteSource: MatchTuningRemoteSource(
          fetcher: () async => {
            'payload': {
              'version': 'baseline_v1',
              'rollbackKey': 'rk_base',
              'locationDecayMiles': 45,
            },
            'experiment': {
              'id': 'exp_match_1',
              'active': false,
              'seed': 'seed_1',
              'controlVariantId': 'control',
              'variants': [
                {
                  'id': 'control',
                  'weight': 1,
                  'payload': {
                    'version': 'control_v1',
                    'rollbackKey': 'rk_control',
                  },
                },
                {
                  'id': 'distance_decay_v1',
                  'weight': 1,
                  'payload': {
                    'version': 'variant_v1',
                    'rollbackKey': 'rk_variant',
                    'locationDecayMiles': 65,
                  },
                },
              ],
            },
          },
        ),
      );

      final config = await provider.getCurrentConfigForUser('user-a');
      expect(config.locationDecayMiles, closeTo(45.0, 0.00001));
    });

    test('returns base config when assigned variant is missing from list',
        () async {
      final provider = MatchConfigProvider(
        assigner: const _FixedAssigner(
          MatchExperimentAssignment(
            experimentId: 'exp_match_1',
            variantId: 'missing_variant',
            isControl: false,
          ),
        ),
        remoteSource: MatchTuningRemoteSource(
          fetcher: () async => {
            'payload': {
              'version': 'baseline_v1',
              'rollbackKey': 'rk_base',
              'locationDecayMiles': 47,
            },
            'experiment': {
              'id': 'exp_match_1',
              'active': true,
              'controlVariantId': 'control',
              'variants': [
                {
                  'id': 'control',
                  'weight': 1,
                  'payload': {
                    'version': 'control_v1',
                    'rollbackKey': 'rk_control',
                  },
                },
              ],
            },
          },
        ),
      );

      final config = await provider.getCurrentConfigForUser('user-b');
      expect(config.locationDecayMiles, closeTo(47.0, 0.00001));
    });

    test('getAssignmentForUser returns null for null/empty user IDs', () async {
      final provider = MatchConfigProvider(
        remoteSource: MatchTuningRemoteSource(
          fetcher: () async => {
            'payload': {
              'version': 'v1',
              'rollbackKey': 'rk_1',
            },
          },
        ),
      );

      expect(await provider.getAssignmentForUser(null), isNull);
      expect(await provider.getAssignmentForUser(''), isNull);
    });
  });

  group('MatchExperimentAssigner', () {
    test('is deterministic for same user and experiment', () {
      const assigner = MatchExperimentAssigner();
      const experiment = MatchExperimentConfig(
        id: 'exp1',
        active: true,
        controlVariantId: 'control',
        seed: 'seed',
        variants: [
          MatchExperimentVariant(id: 'control', weight: 50, payload: {}),
          MatchExperimentVariant(id: 'variant', weight: 50, payload: {}),
        ],
      );

      final a1 = assigner.assign('user-1', experiment);
      final a2 = assigner.assign('user-1', experiment);
      expect(a1?.variantId, a2?.variantId);
      expect(a1?.experimentId, 'exp1');
    });
  });
}
