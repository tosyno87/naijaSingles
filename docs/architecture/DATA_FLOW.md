# AfroPeep Data Flow

**Last Updated:** 2025-02-04

## Overview

Data flows **unidirectionally**: UI → Event → BLoC → State → UI. Services and repositories sit behind BLoCs.

## Authentication Flow

```
User (Phone/Email/Google/Facebook)
  → PhoneAuthRepository / GoogleLoginRepo / FacebookLoginRepo
  → Firebase Auth
  → UserBloc (listens to authStateChanges)
  → UserLoaded state
  → UI (router shows home or onboarding)
```

## Onboarding Flow

```
User fills form
  → Screen calls context.read<OnboardingBloc>().add(OnboardingBioUpdated(value))
  → OnboardingBloc updates OnboardingData
  → Emits OnboardingLoaded(newData)
  → BlocBuilder rebuilds UI

User taps "Complete"
  → OnboardingSaveUserData event
  → OnboardingBloc calls OnboardingRepository.saveUserData()
  → Repository writes to Firestore users/{uid}
  → Emits OnboardingSaveSuccess
  → Navigator pops / router advances
```

## Swipe/Match Flow

```
User swipes right
  → SwipeBloc receives RightSwipeEvent
  → rightSwipe callback (UserSearchRepo.rightSwipe → LikesService.handleLike)
  → MatchService.hasUserLiked / getUsersWhoLikedMe for match detection
  → Emits SwipeMatchCreatedState or SwipeSucessState
  → UI shows match dialog or next card
```

## Discovery Flow

```
Home / Explore screen
  → DiscoveryService.getDiscoveryStream() or similar
  → Firestore query (users collection, filters)
  → Stream<List<UserModel>> to UI
  → SwipeCardList renders cards
```

## Notification Flow

```
FCM message received
  → NotificationService (Firebase Messaging handler)
  → FlutterLocalNotificationsPlugin (local display)
  → Optional: write to Firestore notifications/{userId}
  → User taps → NotificationService.setNavigatorKey → navigatorKey.currentState.push(...)
```

## Chat Flow

```
User sends message
  → ChatService / SendMessageBox
  → Firestore: chatThreads/{threadId}/messages.add()
  → StreamBuilder on messages collection
  → UI updates in real time
```

## Key Principles

1. **BLoCs own state** — Services are stateless (or singleton) and perform I/O
2. **Repositories abstract storage** — OnboardingRepository, UserSearchRepo
3. **No direct service access from UI** — UI uses `context.read<Bloc>()` and `BlocBuilder`
4. **Streams for real-time** — Chat, notifications, discovery use Firestore streams
