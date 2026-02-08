# AfroPeep State Management

**Last Updated:** 2025-02-04

## Pattern: BLoC (Business Logic Component)

AfroPeep uses **flutter_bloc** for state management. All providers have been migrated from `package:provider` to BLoC.

## BLoC Conventions

### Structure

```
lib/features/{feature}/
├── bloc/
│   ├── {feature}_bloc.dart      # Main bloc
│   ├── {feature}_event.dart     # Events (part of bloc)
│   └── {feature}_state.dart     # States (part of bloc)
```

### Event Naming

- Use past tense for actions: `OnboardingBioUpdated`, `UserListenStarted`
- Use imperative for commands: `LoadMatchUserEvent`, `RightSwipeEvent`

### State Naming

- Use descriptive nouns: `OnboardingLoaded`, `UserLoaded`, `SwipeSucessState`
- Include data in state: `OnboardingLoaded(OnboardingData data)`

## Provider Tree (main.dart)

```dart
MultiBlocProvider(
  providers: [
    BlocProvider<AuthstatusBloc>(...),
    BlocProvider<UserBloc>(...),
    BlocProvider<ThemeBloc>(...),
    BlocProvider<LanguageBloc>(...),
  ],
  child: BlocProvider<OnboardingBloc>(
    create: (context) => OnboardingBloc(
      repository: OnboardingRepository(),
      userBloc: context.read<UserBloc>(),
    ),
    child: const MyApp(),
  ),
)
```

## Accessing Blocs in UI

```dart
// Read once (e.g., in callbacks)
context.read<OnboardingBloc>().add(OnboardingBioUpdated(value));

// Rebuild on state changes
BlocBuilder<OnboardingBloc, OnboardingState>(
  builder: (context, state) => ...,
)

// Listen + build
BlocConsumer<OnboardingBloc, OnboardingState>(
  listener: (context, state) { ... },
  builder: (context, state) => ...,
)
```

## Key BLoCs

| BLoC | Purpose | Location |
|------|---------|----------|
| AuthstatusBloc | Auth state | features/auth/auth_status/bloc/ |
| UserBloc | Current user, Firestore listener | common/bloc/user/ |
| OnboardingBloc | Onboarding flow state | features/onboarding/bloc/ |
| ThemeBloc | Dark/light mode | common/bloc/theme/ |
| LanguageBloc | Locale | common/bloc/language/ |
| SwipeBloc | Swipe actions, match detection | features/home/bloc/ |
| MatchUserBloc | Match list | features/match/bloc/ |

## Testing with BLoC

Use `BlocProvider.value` or `BlocProvider` with a test bloc:

```dart
await tester.pumpWidget(
  MaterialApp(
    home: BlocProvider<OnboardingBloc>.value(
      value: OnboardingBloc(repository: mockRepo, userBloc: mockUserBloc),
      child: const Scaffold(body: EnhancedBioScreen()),
    ),
  ),
);
```

For bloc unit tests, use `bloc_test`:

```dart
blocTest<OnboardingBloc, OnboardingState>(
  'emits Loaded when bio updated',
  build: () => OnboardingBloc(...),
  act: (bloc) => bloc.add(OnboardingBioUpdated('test')),
  expect: () => [OnboardingLoaded(...)],
);
```
