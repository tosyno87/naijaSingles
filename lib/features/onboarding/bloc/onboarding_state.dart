part of 'onboarding_bloc.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  OnboardingData? get data => switch (this) {
        OnboardingLoaded(:final data) => data,
        OnboardingLoading(:final data) => data,
        _ => null,
      };

  @override
  List<Object?> get props => [];
}

final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

final class OnboardingLoaded extends OnboardingState {
  const OnboardingLoaded(this.data);

  @override
  final OnboardingData data;

  @override
  List<Object?> get props => [data];
}

final class OnboardingLoading extends OnboardingState {
  const OnboardingLoading(this.data);

  @override
  final OnboardingData data;

  @override
  List<Object?> get props => [data];
}

final class OnboardingSaveSuccess extends OnboardingState {
  const OnboardingSaveSuccess();
}

final class OnboardingSaveFailure extends OnboardingState {
  const OnboardingSaveFailure(this.error);

  final String error;

  @override
  List<Object?> get props => [error];
}
