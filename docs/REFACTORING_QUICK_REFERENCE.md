# Refactoring Quick Reference

**Branch:** `refactor/architecture-cleanup`  
**Full Plan:** See [REFACTORING_PLAN.md](./REFACTORING_PLAN.md)

## Current Phase: Phase 1 - Service Consolidation

---

## Quick Commands

### Branch Management
```bash
# Switch to refactoring branch
git checkout refactor/architecture-cleanup

# Create a sub-branch for specific work
git checkout -b refactor/match-services-consolidation

# Return to main
git checkout main
```

### Testing Before Commits
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Check for unused imports
flutter pub run import_sorter:main
```

---

## Phase 1: Service Consolidation

### 1.1 Match Services (In Progress)

**Files to Consolidate:**
- `lib/services/smart_match_service.dart`
- `lib/services/smart_matching_service.dart`
- `lib/services/optimized_match_service.dart`
- `lib/features/match/services/match_service.dart`

**Target:**
- `lib/features/match/data/services/match_service.dart`
- `lib/features/match/data/services/compatibility_engine.dart`

**Steps:**
1. Find all usages: `grep -r "SmartMatchService\|SmartMatchingService\|OptimizedMatchService" lib/`
2. Compare functionality
3. Merge into single service
4. Update imports
5. Remove old files

---

### 1.2 Notification Services (Next)

**Files to Consolidate:**
- `lib/services/enhanced_notification_service.dart`
- `lib/services/enhanced_notification_service_v2.dart`
- `lib/services/industry_notification_service.dart`

**Target:**
- `lib/features/notifications/data/services/notification_service.dart`

**Find Usages:**
```bash
grep -r "EnhancedNotificationService\|IndustryNotificationService" lib/
```

---

### 1.3 Discovery Services (After Notifications)

**Files to Consolidate:**
- `lib/services/discovery_service.dart`
- `lib/services/unified_discovery_service.dart`
- `lib/services/realtime_discovery_service.dart`

**Target:**
- `lib/features/discovery/data/services/discovery_service.dart`

---

## Phase 2: State Management Migration

### Provider → BLoC Checklist

**Providers to Migrate:**
- [ ] `UserProvider` → `UserBloc`
- [ ] `ThemeProvider` → `ThemeBloc`
- [ ] `OnboardingController` → `OnboardingBloc`

**Find All Provider Usages:**
```bash
# Find Consumer widgets
grep -r "Consumer<" lib/

# Find Provider.of usage
grep -r "Provider.of<" lib/

# Find ChangeNotifierProvider
grep -r "ChangeNotifierProvider" lib/
```

**Migration Pattern:**
```dart
// Before (Provider)
Consumer<UserProvider>(
  builder: (context, userProvider, child) {
    return Text(userProvider.currentUser?.name ?? '');
  },
)

// After (BLoC)
BlocBuilder<UserBloc, UserState>(
  builder: (context, state) {
    return Text(state.currentUser?.name ?? '');
  },
)
```

---

## Phase 3: Code Organization

### Service Relocation Checklist

**Services to Move:**
- [ ] `match_service.dart` → `lib/features/match/data/services/`
- [ ] `notification_service.dart` → `lib/features/notifications/data/services/`
- [ ] `discovery_service.dart` → `lib/features/discovery/data/services/`
- [ ] `group_service.dart` → `lib/features/groups/data/services/`
- [ ] `chat_service.dart` → `lib/features/chat/data/services/`

**After Moving:**
```bash
# Update imports (use IDE refactoring)
# Verify build
flutter pub get
flutter analyze
flutter test
```

---

## Phase 4: Dependency Cleanup

### Dependencies to Remove

**After BLoC Migration:**
- [ ] Remove `provider: ^6.1.5` from `pubspec.yaml`

**Image Packages (Audit First):**
- [ ] Check if `crop_image` is used
- [ ] Keep: `image_picker`, `image_cropper`
- [ ] Remove redundant ones

**Swiper Packages (Audit First):**
- [ ] Check usage of each swiper package
- [ ] Keep one, remove others

**Find Package Usage:**
```bash
# Find imports
grep -r "package:provider" lib/
grep -r "package:crop_image" lib/
grep -r "package:swipe_cards" lib/
```

---

## Phase 5: Code Cleanup

### Remove Old Files

**Find Old Files:**
```bash
# Find all _old.dart files
find lib/ -name "*_old.dart"

# Find all _backup.dart files
find lib/ -name "*_backup.dart"

# Find all duplicate numbered files
find . -name "* 2.*" -o -name "* 3.*"
```

**Before Removing:**
```bash
# Verify not imported
grep -r "bio_screen_old" lib/
grep -r "interests_screen_old" lib/
```

---

## Testing Checklist

### Before Each Commit
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] App builds successfully (`flutter build apk --debug`)
- [ ] No new linter errors

### After Service Consolidation
- [ ] All old service imports removed
- [ ] New service works in app
- [ ] Tests updated and passing
- [ ] No regressions in functionality

### After State Management Migration
- [ ] All screens migrated
- [ ] No `Consumer` or `Provider.of` usage
- [ ] App functionality unchanged
- [ ] Performance not degraded

---

## Common Issues & Solutions

### Import Errors After Moving Files
```bash
# Use IDE refactoring (VS Code / Android Studio)
# Or manually update imports
find lib/ -name "*.dart" -exec sed -i '' 's|old/path|new/path|g' {} +
```

### Build Failures
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade
flutter analyze
```

### Test Failures
```bash
# Run specific test
flutter test test/path/to/test.dart

# Run with coverage
flutter test --coverage
```

---

## Progress Tracking

Update this as you complete tasks:

### Phase 1: Service Consolidation
- [ ] 1.1 Match Services
- [ ] 1.2 Notification Services  
- [ ] 1.3 Discovery Services

### Phase 2: State Management
- [ ] 2.1 Decision Made
- [ ] 2.2 UserProvider → UserBloc
- [ ] 2.3 ThemeProvider → ThemeBloc
- [ ] 2.4 OnboardingController → OnboardingBloc
- [ ] 2.5 Remove Provider dependency

### Phase 3: Organization
- [ ] 3.1 Service Relocation
- [ ] 3.2 Feature Structure Standardization

### Phase 4: Dependencies
- [ ] 4.1 Remove Provider
- [ ] 4.2 Consolidate Image Packages
- [ ] 4.3 Consolidate Swiper Packages

### Phase 5: Cleanup
- [ ] 5.1 Remove Old Files
- [ ] 5.2 Remove Placeholder Services

### Phase 6: Testing & Docs
- [ ] 6.1 Increase Test Coverage
- [ ] 6.2 Architecture Documentation

---

## Useful Git Commands

```bash
# Create feature branch for specific task
git checkout -b refactor/match-services

# Commit with clear message
git commit -m "refactor: consolidate match services into single service"

# Push branch
git push -u origin refactor/match-services

# Squash commits before merge (if needed)
git rebase -i HEAD~5
```

---

**Last Updated:** 2025-01-27
