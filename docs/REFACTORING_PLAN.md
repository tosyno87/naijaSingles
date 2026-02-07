# AfroPeep Refactoring Plan

**Created:** 2025-01-27  
**Status:** In Progress  
**Branch:** `refactor/architecture-cleanup`

## Executive Summary

This document outlines a comprehensive refactoring plan to address service duplication, state management inconsistencies, and over-engineering issues identified in the codebase review. The plan is organized into phases with clear priorities and success criteria.

---

## Phase 1: Service Consolidation (Priority: Critical)

### 1.1 Match Services Consolidation

**Current State:**
- `lib/services/smart_match_service.dart` (630 lines)
- `lib/services/smart_matching_service.dart` (612 lines)
- `lib/services/optimized_match_service.dart` (417 lines)
- `lib/features/match/services/match_service.dart` (uses `likes_service.dart`)

**Target State:**
- Single `lib/features/match/data/services/match_service.dart`
- Separate `lib/features/match/data/services/compatibility_engine.dart`
- Keep `lib/features/match/services/likes_service.dart` (core logic)

**Steps:**
1. ✅ Audit all usages of each match service
2. ✅ Identify which service is most used/complete (main MatchService in features/match)
3. ✅ Extract compatibility scoring logic to `CompatibilityEngine` (moved to features/match/data/services/)
4. ✅ Merge functionality into single `MatchService` (main service already canonical)
5. ✅ Update all imports and usages
6. ✅ Remove old service files (explore match_service, mock_match_service)
7. ⏳ Add comprehensive tests

**Estimated Effort:** 2-3 days  
**Risk:** Medium (touches core matching logic)

---

### 1.2 Notification Services Consolidation

**Current State:**
- `lib/services/enhanced_notification_service.dart` (456 lines)
- `lib/services/enhanced_notification_service_v2.dart` (827 lines)
- `lib/services/industry_notification_service.dart` (600+ lines)
- `lib/features/notifications/notification_service.dart`

**Target State:**
- Single `lib/features/notifications/data/services/notification_service.dart`
- Keep v2 as base (most complete)

**Steps:**
1. ✅ Audit all usages of each notification service
2. ⏳ Compare feature completeness (v2 vs industry)
3. ⏳ Merge best features into single service
4. ⏳ Update all imports and usages
5. ⏳ Remove old service files
6. ⏳ Update `main.dart` initialization

**Estimated Effort:** 1-2 days  
**Risk:** Low-Medium (notifications are critical but isolated)

---

### 1.3 Discovery Services Consolidation

**Current State:** ✅ Already consolidated
- Single `lib/features/discovery/data/services/discovery_service.dart` combines:
  - Privacy-aware discovery (from legacy DiscoveryService)
  - Comprehensive filtering (from UnifiedDiscoveryService)
  - Real-time streams (from RealtimeDiscoveryService)
- No legacy discovery services remain in `lib/services/`

**Target State:** ✅ Achieved
- Primary: `lib/features/discovery/data/services/discovery_service.dart`
- Realtime logic integrated into main service

**Steps:**
1. ✅ Audit all usages
2. ✅ Use `unified_discovery_service` as base
3. ✅ Keep realtime as optional feature (integrated)
4. ✅ Migrate privacy logic into unified service
5. ✅ Update all imports
6. ✅ Remove old files

**Estimated Effort:** 1 day  
**Risk:** Low

---

## Phase 2: State Management Standardization (Priority: Critical)

### 2.1 Decision: BLoC vs Provider

**Current State:**
- `.cursorrules` says "Use BLoC (no deprecated Provider)"
- Reality: Provider used extensively (414 matches, 130 files)
- BLoC used in: match, auth, explore features

**Decision Required:**
- **Option A:** Migrate to BLoC (recommended per rules)
- **Option B:** Keep Provider (update rules to reflect reality)

**Recommendation:** **Option A - Migrate to BLoC** (aligns with project rules and modern Flutter practices)

---

### 2.2 Provider → BLoC Migration Plan

**Affected Components:** ✅ Migrated
- `UserProvider` → `UserBloc` ✅
- `ThemeProvider` → `ThemeBloc` ✅
- `OnboardingController` → `OnboardingBloc` ✅
- `StreetViewProvider` → `StreetViewBloc` ✅
- `LanguageProvider` → `LanguageBloc` ✅

**Steps:**
1. ✅ Create `UserBloc` with same functionality
2. ✅ Create `ThemeBloc` with same functionality
3. ✅ Create `OnboardingBloc` with same functionality
4. ✅ Update `main.dart` to use BLoC providers
5. ✅ Migrate screens (app uses BlocProvider/BlocConsumer throughout)
6. ✅ Remove Provider dependency (package:provider not in pubspec)
7. ✅ Update test_helpers to use BlocProvider instead of ChangeNotifierProvider

**Estimated Effort:** 3-5 days  
**Risk:** High (touches many files, needs careful testing)

**Migration Strategy:**
- Migrate one provider at a time
- Keep both during transition (temporary)
- Test thoroughly before removing old provider
- Use feature flags if needed

---

## Phase 3: Code Organization (Priority: High)

### 3.1 Service Relocation

**Current State:**
- Services split between `lib/services/` and `lib/features/{feature}/services/`

**Target State:**
- Feature-specific services in `lib/features/{feature}/data/services/`
- Only truly shared services in `lib/services/`

**Services to Move:**
- `match_service.dart` → `lib/features/match/data/services/`
- `notification_service.dart` → `lib/features/notifications/data/services/`
- `discovery_service.dart` → `lib/features/discovery/data/services/`
- `group_service.dart` → `lib/features/groups/data/services/`
- `chat_service.dart` → `lib/features/chat/data/services/`
- `event_service.dart` → `lib/features/events/data/services/`

**Keep in `lib/services/` (truly shared):**
- `auth_service.dart`
- `secure_storage_service.dart`
- `crashlytics_service.dart`
- `image_upload_service.dart` (if used across features)

**Steps:**
1. ✅ Identify all feature-specific services
2. ✅ Move services to appropriate feature folders:
   - `group_service.dart` → `lib/features/groups/data/services/`
   - `unified_group_service.dart` → `lib/features/groups/data/services/`
   - `group_chat_service.dart` → `lib/features/group_chat/data/services/`
   - (match, notification, discovery, chat, events already in feature folders)
3. ✅ Update all imports
4. ✅ Verify builds pass

**Estimated Effort:** 1 day  
**Risk:** Low (mostly file moves)

---

### 3.2 Feature Structure Standardization

**Target Structure:**
```
lib/features/{feature}/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── domain/  (optional, for complex business logic)
└── presentation/
    ├── bloc/
    ├── screens/
    └── widgets/
```

**Features to Standardize:**
- `onboarding/` - Has mixed structure
- `profile/` - Has multiple screen versions
- `events/` - Already well-structured ✅
- `match/` - Already well-structured ✅

**Steps:**
1. ✅ Audit each feature's structure
2. ✅ Profile: Remove 5 dead backup/alternative screens
3. ✅ Onboarding: Move services→data/services, repository→data/repositories
4. ✅ Update imports

**Estimated Effort:** 2-3 days  
**Risk:** Medium

---

## Phase 4: Dependency Cleanup (Priority: Medium)

### 4.1 State Management Dependencies

**Current:**
- `provider: ^6.1.5`
- `flutter_bloc: ^9.1.1`

**Action:** Remove `provider` after BLoC migration

---

### 4.2 Image Package Consolidation

**Current:**
- `image_picker: ^1.2.0`
- `image_cropper: ^9.1.0`
- `crop_image: ^1.0.16`
- `flutter_image_compress: ^2.4.0`

**Action:** Keep `image_picker` + `image_cropper`, remove `crop_image` if redundant

---

### 4.3 Swiper Package Consolidation

**Current:**
- `swipe_cards: ^2.0.0+1`
- `flutter_swiper_null_safety: ^1.0.2`
- `swipable_stack: ^2.0.0`

**Action:** Audit usage, keep one, remove others

---

### 4.4 Dependency Audit Script

**Steps:**
1. ⏳ Create script to find unused imports
2. ⏳ Run `flutter pub deps` analysis
3. ⏳ Remove unused dependencies
4. ⏳ Test app still works

**Estimated Effort:** 1 day  
**Risk:** Low

---

## Phase 5: Code Cleanup (Priority: Medium)

### 5.1 Remove Old/Deprecated Files

**Files to Remove:**
- All `*_old.dart` files in onboarding
- `bio_screen_old.dart`
- `interests_screen_old.dart`
- `onboarding_step_bio_old.dart`
- Any other `*_old.dart` or `*_backup.dart` files

**Steps:**
1. ⏳ Search for all `*_old.dart` and `*_backup.dart` files
2. ⏳ Verify they're not imported anywhere
3. ⏳ Remove files
4. ⏳ Commit removal

**Estimated Effort:** 0.5 days  
**Risk:** Low

---

### 5.2 Remove Placeholder/Unused Services

**Services to Audit:**
- `offline_support_service.dart` - Has placeholder `isOnline()` method
- `background_sync_service.dart` - Verify it's actually used
- `security_logging_service.dart` - May duplicate Crashlytics

**Steps:**
1. ⏳ Audit each service for actual usage
2. ⏳ Check if functionality is needed
3. ⏳ Remove or implement properly

**Estimated Effort:** 1 day  
**Risk:** Low

---

## Phase 6: Testing & Documentation (Priority: High)

### 6.1 Increase Test Coverage

**Current:** ~6.7% (31 test files for 460+ Dart files)  
**Target:** 60%+ for critical features

**Priority Test Areas:**
1. Match service (after consolidation)
2. Auth flows
3. Discovery service
4. Notification service

**Steps:**
1. ⏳ Add unit tests for consolidated services
2. ⏳ Add widget tests for critical screens
3. ⏳ Add integration tests for key user flows
4. ⏳ Set up coverage reporting

**Estimated Effort:** 3-5 days  
**Risk:** Low

---

### 6.2 Architecture Documentation

**Documents to Create:**
- `docs/architecture/SERVICE_ARCHITECTURE.md` - Service dependency graph
- `docs/architecture/STATE_MANAGEMENT.md` - BLoC patterns and conventions
- `docs/architecture/DATA_FLOW.md` - How data flows through the app
- `docs/architecture/DECISIONS.md` - Architecture Decision Records (ADRs)

**Estimated Effort:** 1-2 days  
**Risk:** Low

---

## Implementation Timeline

### Week 1: Critical Consolidations
- **Days 1-2:** Match services consolidation
- **Days 3-4:** Notification services consolidation
- **Day 5:** Discovery services consolidation

### Week 2: State Management Migration
- **Days 1-2:** Create BLoC implementations (User, Theme, Onboarding)
- **Days 3-4:** Migrate screens to BLoC
- **Day 5:** Testing and cleanup

### Week 3: Organization & Cleanup
- **Days 1-2:** Service relocation
- **Day 3:** Feature structure standardization
- **Days 4-5:** Dependency cleanup

### Week 4: Testing & Documentation
- **Days 1-3:** Add tests for consolidated services
- **Days 4-5:** Architecture documentation

**Total Estimated Time:** 4 weeks (1 developer)

---

## Success Criteria

### Phase 1 (Service Consolidation)
- ✅ Single match service with <1000 lines
- ✅ Single notification service
- ✅ Single discovery service (realtime optional)
- ✅ All old services removed
- ✅ All tests passing

### Phase 2 (State Management)
- ✅ All providers migrated to BLoC
- ✅ Provider dependency removed
- ✅ All screens using BLoC
- ✅ No `Consumer` or `Provider.of` usage

### Phase 3 (Organization)
- ✅ All feature services in feature folders
- ✅ Standard feature structure across all features
- ✅ Clear separation of concerns

### Phase 4 (Dependencies)
- ✅ Provider removed
- ✅ Redundant packages removed
- ✅ Dependency count <70

### Phase 5 (Cleanup)
- ✅ All `*_old.dart` files removed
- ✅ Placeholder services removed or implemented
- ✅ No dead code

### Phase 6 (Testing)
- ✅ 60%+ test coverage on critical features
- ✅ Architecture docs complete
- ✅ Service dependency graph documented

---

## Risk Mitigation

### High-Risk Areas
1. **State Management Migration** - Touches many files
   - **Mitigation:** Migrate incrementally, keep both during transition, thorough testing

2. **Match Service Consolidation** - Core business logic
   - **Mitigation:** Comprehensive tests before/after, feature flag if needed

### Medium-Risk Areas
1. **Service Relocation** - Many import updates
   - **Mitigation:** Use IDE refactoring tools, verify builds frequently

2. **Dependency Removal** - May break if usage missed
   - **Mitigation:** Thorough audit, test after each removal

---

## Rollback Plan

If issues arise:
1. **Service Consolidation:** Keep old services until new ones are proven
2. **State Management:** Keep Provider during migration, remove only after 100% migration
3. **File Moves:** Git makes rollback easy, commit frequently

---

## Progress Tracking

- [x] Phase 1.1: Match Services Consolidation
- [x] Phase 1.2: Notification Services Consolidation
- [x] Phase 1.3: Discovery Services Consolidation
- [x] Phase 2.1: State Management Decision
- [x] Phase 2.2: Provider → BLoC Migration
- [x] Phase 3.1: Service Relocation
- [x] Phase 3.2: Feature Structure Standardization
- [ ] Phase 4: Dependency Cleanup
- [ ] Phase 5: Code Cleanup
- [ ] Phase 6: Testing & Documentation

---

## Notes

- This refactoring should be done incrementally
- Each phase should be completed and tested before moving to next
- Keep main branch stable - work in feature branch
- Regular commits with clear messages
- Code reviews recommended for critical changes

---

**Last Updated:** 2025-01-27  
**Next Review:** After Phase 1 completion
