import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/services/match_config.dart';
import 'package:naijasingles/services/match_config_provider.dart';
import 'package:naijasingles/services/match_tuning_config_loader.dart';
import 'package:naijasingles/services/match_tuning_remote_source.dart';

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
  });
}
