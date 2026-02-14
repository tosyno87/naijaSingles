# Phase 1.1: Match Services Consolidation

## Analysis Summary

### Current Services:
1. **MatchService** (`lib/features/match/services/match_service.dart`)
   - Main interface, delegates to LikesService
   - Used by: `match_bloc.dart`, `swipebloc_bloc.dart`
   - ✅ Keep - This is the correct location and pattern

2. **LikesService** (`lib/features/match/services/likes_service.dart`)
   - Core like/match logic
   - Handles mutual like detection, match creation
   - ✅ Keep - Core functionality

3. **OptimizedMatchService** (`lib/services/optimized_match_service.dart`)
   - Performance-optimized version (2-3 reads vs 5-10)
   - Used by: `super_like_service.dart`, `user_search_repo.dart`
   - ⚠️ Merge optimizations into LikesService

4. **SmartMatchService** (`lib/services/smart_match_service.dart`)
   - Discovery/ordering service for user lists
   - Used by: `unified_discovery_service.dart`
   - ⚠️ Move to discovery feature (not match-related)

5. **SmartMatchingService** (`lib/services/smart_matching_service.dart`)
   - Compatibility scoring
   - ❌ Not directly used - Extract to CompatibilityEngine or remove

## Consolidation Strategy

### Step 1: Enhance LikesService with Optimizations
- Merge caching logic from OptimizedMatchService
- Add batch operations for better performance
- Keep the optimized query patterns

### Step 2: Extract Compatibility Logic
- Create `lib/features/match/data/services/compatibility_engine.dart`
- Move compatibility scoring from SmartMatchingService
- Keep mode-specific compatibility logic

### Step 3: Move Discovery Logic
- Move SmartMatchService to `lib/features/discovery/data/services/discovery_ordering_service.dart`
- This is discovery/ordering, not match creation

### Step 4: Update All Usages
- Update `super_like_service.dart` to use MatchService
- Update `user_search_repo.dart` to use MatchService
- Update `unified_discovery_service.dart` to use discovery ordering service

### Step 5: Remove Old Services
- Remove `optimized_match_service.dart`
- Remove `smart_matching_service.dart`
- Keep `smart_match_service.dart` temporarily until moved

## Target Structure

```
lib/features/match/
├── data/
│   └── services/
│       ├── match_service.dart          (Main interface - enhanced)
│       ├── likes_service.dart          (Core logic - optimized)
│       └── compatibility_engine.dart  (NEW - compatibility scoring)
└── services/  (remove after consolidation)
    ├── match_service.dart  (move to data/services)
    └── likes_service.dart  (move to data/services)
```
