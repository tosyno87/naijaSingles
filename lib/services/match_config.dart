/// Central configuration for match-scoring weights and distance thresholds.
///
/// All values are exposed as named fields so they can be overridden from
/// remote config, A/B tests, or unit tests without touching engine code.
class MatchConfig {
  const MatchConfig({
    this.datingWeights = const ModeWeights(
      age: 0.30,
      location: 0.25,
      lifestyle: 0.20,
      interest: 0.15,
      completeness: 0.10,
    ),
    this.friendshipWeights = const ModeWeights(
      social: 0.35,
      interest: 0.25,
      location: 0.20,
      age: 0.10,
      completeness: 0.10,
    ),
    this.networkingWeights = const ModeWeights(
      professional: 0.40,
      industry: 0.25,
      location: 0.20,
      completeness: 0.15,
    ),
    this.locationPerfectMiles = 5.0,
    this.locationDecayMiles = 50.0,
    this.locationFloorScore = 0.2,
  });

  /// Default singleton used by production code.
  static const defaults = MatchConfig();

  final ModeWeights datingWeights;
  final ModeWeights friendshipWeights;
  final ModeWeights networkingWeights;

  /// Distance (miles) at or below which location score is 1.0.
  final double locationPerfectMiles;

  /// Distance (miles) at which the linear decay region ends.
  final double locationDecayMiles;

  /// Minimum location score applied beyond [locationDecayMiles].
  final double locationFloorScore;

  MatchConfig copyWith({
    ModeWeights? datingWeights,
    ModeWeights? friendshipWeights,
    ModeWeights? networkingWeights,
    double? locationPerfectMiles,
    double? locationDecayMiles,
    double? locationFloorScore,
  }) =>
      MatchConfig(
        datingWeights: datingWeights ?? this.datingWeights,
        friendshipWeights: friendshipWeights ?? this.friendshipWeights,
        networkingWeights: networkingWeights ?? this.networkingWeights,
        locationPerfectMiles: locationPerfectMiles ?? this.locationPerfectMiles,
        locationDecayMiles: locationDecayMiles ?? this.locationDecayMiles,
        locationFloorScore: locationFloorScore ?? this.locationFloorScore,
      );
}

/// Per-factor weights for a given relationship mode.
///
/// Only the fields relevant to the mode are non-zero; unused dimensions
/// default to 0.0 and are simply ignored during weighted summation.
class ModeWeights {
  const ModeWeights({
    this.age = 0.0,
    this.location = 0.0,
    this.lifestyle = 0.0,
    this.interest = 0.0,
    this.completeness = 0.0,
    this.social = 0.0,
    this.professional = 0.0,
    this.industry = 0.0,
  });

  final double age;
  final double location;
  final double lifestyle;
  final double interest;
  final double completeness;
  final double social;
  final double professional;
  final double industry;

  ModeWeights copyWith({
    double? age,
    double? location,
    double? lifestyle,
    double? interest,
    double? completeness,
    double? social,
    double? professional,
    double? industry,
  }) =>
      ModeWeights(
        age: age ?? this.age,
        location: location ?? this.location,
        lifestyle: lifestyle ?? this.lifestyle,
        interest: interest ?? this.interest,
        completeness: completeness ?? this.completeness,
        social: social ?? this.social,
        professional: professional ?? this.professional,
        industry: industry ?? this.industry,
      );
}
