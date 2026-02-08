# AfroPeep Service Architecture

**Last Updated:** 2025-02-04  
**Branch:** `refactor/architecture-cleanup`

## Overview

AfroPeep uses a **feature-based architecture** with services colocated in each feature's `data/services/` folder. Shared/infrastructure services remain in `lib/services/`.

## Service Dependency Graph

```
main.dart
├── SecureConfig
├── SecureStorageService
├── CrashlyticsService
├── NotificationService
└── BlocProvider tree
    ├── AuthstatusBloc → PhoneAuthRepository
    ├── UserBloc → FirebaseAuth, Firestore (users collection)
    ├── ThemeBloc
    ├── LanguageBloc
    └── OnboardingBloc → OnboardingRepository, UserBloc
```

## Shared Services (`lib/services/`)

| Service | Purpose | Dependencies |
|---------|---------|--------------|
| `auth_service.dart` | Authentication | Firebase Auth |
| `secure_storage_service.dart` | Encrypted key-value storage | flutter_secure_storage |
| `crashlytics_service.dart` | Crash reporting | Firebase Crashlytics |
| `image_upload_service.dart` | Image upload to Storage | Firebase Storage |

## Feature Services

### Match (`lib/features/match/data/services/`)

| Service | Purpose | Dependencies |
|---------|---------|--------------|
| `match_service.dart` | Like/match operations, match list | LikesService, Firestore, Auth |
| `likes_service.dart` | Like handling, mutual like detection | Firestore, Auth |
| `compatibility_engine.dart` | Compatibility scoring | — |

### Notifications (`lib/features/notifications/data/services/`)

| Service | Purpose | Dependencies |
|---------|---------|--------------|
| `notification_service.dart` | Push, local, in-app notifications | Firebase Messaging, Firestore, FlutterLocalNotifications |

### Discovery (`lib/features/discovery/data/services/`)

| Service | Purpose | Dependencies |
|---------|---------|--------------|
| `discovery_service.dart` | User discovery, filtering, real-time streams | Firestore, Auth |

### Groups (`lib/features/groups/data/services/`)

| Service | Purpose | Dependencies |
|---------|---------|--------------|
| `group_service.dart` | Group CRUD | Firestore |
| `unified_group_service.dart` | Group management | Firestore |

### Group Chat (`lib/features/group_chat/data/services/`)

| Service | Purpose | Dependencies |
|---------|---------|--------------|
| `group_chat_service.dart` | Group chat messages | Firestore |

### Events (`lib/features/events/data/services/`)

| Service | Purpose | Dependencies |
|---------|---------|--------------|
| `seed_events_service.dart` | Seed events if empty | Firestore |

### Onboarding (`lib/features/onboarding/data/`)

| Component | Purpose | Dependencies |
|-----------|---------|--------------|
| `onboarding_repository.dart` | Save onboarding data | Firestore, Storage, Auth |
| `photo_quality_analyzer.dart` | Photo analysis | — |

## Initialization Order (main.dart)

1. `SecureConfig.initialize()`
2. `SecureStorageService().initialize()`
3. `Firebase.initializeApp()`
4. `CrashlyticsService().initialize()`
5. `NotificationService.initialize()`
6. (After auth) `SeedEventsService().seedEventsIfEmpty()`

## Key Collections (Firestore)

- `users` — User profiles
- `likes` — Like documents (fromUserId_likes_toUserId)
- `matches` — Mutual matches
- `chatThreads` — Chat threads with subcollection `messages`
- `notifications` — Per-user notifications
- `events` — Events (Eventbrite integration)
- `groups` — Community groups

## Conventions

- **Feature services** live in `lib/features/{feature}/data/services/`
- **Repositories** abstract Firestore/API access in `data/repositories/`
- **BLoCs** consume services and repositories; do not expose raw services to UI
- Services that need Firebase are not easily testable without dependency injection; consider constructor injection for future testability
