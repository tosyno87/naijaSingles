class MatchExperimentVariant {
  const MatchExperimentVariant({
    required this.id,
    required this.weight,
    required this.payload,
  });

  final String id;
  final int weight;
  final Map<String, dynamic> payload;
}

class MatchExperimentConfig {
  const MatchExperimentConfig({
    required this.id,
    required this.active,
    required this.controlVariantId,
    required this.seed,
    required this.variants,
  });

  final String id;
  final bool active;
  final String controlVariantId;
  final String seed;
  final List<MatchExperimentVariant> variants;

  static MatchExperimentConfig? fromRaw(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final experiment = raw['experiment'];
    if (experiment is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(experiment);
    final id = (map['id'] as String?)?.trim();
    final controlVariantId = (map['controlVariantId'] as String?)?.trim();
    final active = map['active'] == true;
    final seed = ((map['seed'] as String?)?.trim().isNotEmpty ?? false)
        ? (map['seed'] as String).trim()
        : 'match_experiment_seed';

    final variantsRaw = map['variants'];
    if (id == null ||
        id.isEmpty ||
        controlVariantId == null ||
        controlVariantId.isEmpty ||
        variantsRaw is! List) {
      return null;
    }

    final variants = <MatchExperimentVariant>[];
    for (final entry in variantsRaw) {
      if (entry is! Map) {
        continue;
      }
      final variant = Map<String, dynamic>.from(entry);
      final variantId = (variant['id'] as String?)?.trim();
      final weight = variant['weight'];
      final payload = variant['payload'];
      if (variantId == null ||
          variantId.isEmpty ||
          weight is! num ||
          payload is! Map) {
        continue;
      }
      final normalizedWeight = weight.toInt();
      if (normalizedWeight <= 0) {
        continue;
      }
      variants.add(
        MatchExperimentVariant(
          id: variantId,
          weight: normalizedWeight,
          payload: Map<String, dynamic>.from(payload),
        ),
      );
    }

    if (variants.isEmpty) {
      return null;
    }

    return MatchExperimentConfig(
      id: id,
      active: active,
      controlVariantId: controlVariantId,
      seed: seed,
      variants: variants,
    );
  }
}

class MatchExperimentAssignment {
  const MatchExperimentAssignment({
    required this.experimentId,
    required this.variantId,
    required this.isControl,
  });

  final String experimentId;
  final String variantId;
  final bool isControl;
}

class MatchExperimentAssigner {
  const MatchExperimentAssigner();

  MatchExperimentAssignment? assign(
    String userId,
    MatchExperimentConfig? experiment,
  ) {
    if (userId.isEmpty || experiment == null || !experiment.active) {
      return null;
    }
    final totalWeight = experiment.variants.fold<int>(
      0,
      (sum, v) => sum + v.weight,
    );
    if (totalWeight <= 0) {
      return null;
    }

    final bucket = _hashBucket('${experiment.seed}:$userId', totalWeight);
    var cursor = 0;
    for (final variant in experiment.variants) {
      cursor += variant.weight;
      if (bucket < cursor) {
        return MatchExperimentAssignment(
          experimentId: experiment.id,
          variantId: variant.id,
          isControl: variant.id == experiment.controlVariantId,
        );
      }
    }
    return null;
  }

  int _hashBucket(String input, int modulo) {
    const int offset = 0x811C9DC5;
    const int prime = 0x01000193;
    int hash = offset;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * prime) & 0xFFFFFFFF;
    }
    return hash % modulo;
  }
}
