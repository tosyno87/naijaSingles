# Architecture Decision Records (ADRs)

**Last Updated:** 2025-02-04

## ADR-001: Use BLoC for State Management

**Status:** Accepted  
**Date:** 2025-01

**Context:** The app previously used Provider and ChangeNotifier. Project rules specified BLoC.

**Decision:** Migrate all state management to BLoC (flutter_bloc).

**Consequences:**
- Consistent pattern across features
- Better testability via bloc_test
- Event/state traceability
- Provider remains a transitive dependency of flutter_bloc

---

## ADR-002: Feature-Based Service Location

**Status:** Accepted  
**Date:** 2025-01

**Context:** Services were split between `lib/services/` and feature folders inconsistently.

**Decision:** Place feature-specific services in `lib/features/{feature}/data/services/`. Keep only truly shared services (auth, secure storage, crashlytics) in `lib/services/`.

**Consequences:**
- Clear ownership per feature
- Easier to locate and refactor feature code
- Shared services remain discoverable in lib/services/

---

## ADR-003: Consolidate Duplicate Services

**Status:** Accepted  
**Date:** 2025-01

**Context:** Multiple match services (smart_match, optimized_match, explore match_service), multiple notification services, and legacy discovery services caused confusion.

**Decision:** Consolidate to a single canonical service per domain:
- MatchService (features/match/data/services/)
- NotificationService (features/notifications/data/services/)
- DiscoveryService (features/discovery/data/services/)

**Consequences:**
- One source of truth per domain
- Removed ~2000+ lines of duplicate code
- All imports updated to consolidated services

---

## ADR-004: Remove Unused Placeholder Services

**Status:** Accepted  
**Date:** 2025-02

**Context:** offline_support_service, background_sync_service, and security_logging_service were implemented but never wired into the app.

**Decision:** Remove them. Re-add with proper integration when needed.

**Consequences:**
- Less dead code
- Fewer false assumptions about available features
- Cleaner codebase

---

## ADR-005: Dependency Injection via Constructor (Partial)

**Status:** Partial  
**Date:** 2025-01

**Context:** Many services use FirebaseFirestore.instance and FirebaseAuth.instance directly, making unit tests difficult without global mocks.

**Decision:** Use constructor injection where new code is written (e.g., OnboardingBloc receives OnboardingRepository and UserBloc). Existing services that use global Firebase instances remain as-is until refactored.

**Consequences:**
- New BLoCs and repositories are testable
- Legacy services require Firebase test setup (method channel mocks or fake_cloud_firestore) for integration tests
- Future refactors should add DI for MatchService, NotificationService, etc.
