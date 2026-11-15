# AfroPeep Houston First Screen Build Prompt

Paste this into Cursor when you are ready to build the new first screen.

## Context

AfroPeep was rejected risk-wise because the first usable product surface can still read as a generic dating/swipe app. The new strategy is Houston-first, diaspora-community-first: events, trusted people, and local rooms first; Connect/dating second.

Use this Figma prototype as the visual direction:

- Figma file: https://www.figma.com/design/D3ZDY2CXDyoAWIK4VkXHj7
- Main frame: `4:2`
- Frame name: `AfroPeep Houston Home - editable mobile screen`

## Product Requirement

Rewrite the first post-onboarding screen around Houston events and people. First impression should not be a swipe deck. It should say: Houston, diaspora Africans, events this week, verified people. :codex-annotation{index="1"}

Build the experience so a new or returning user immediately understands:

- AfroPeep is for Africans in Houston.
- The primary action is finding real events and community rooms this week.
- Verified people are visible as part of community context.
- Connect/dating exists, but it is not the home page promise.

Do not add housing, visa, jobs, healthcare, banking, school, or general newcomer directory features. The product is the belonging layer, not a settlement super-app.

## Current Code Anchors

Start from these files:

- `lib/features/home/main_navigation_screen.dart`
- `lib/features/communities/ui/screens/discover_page_v2.dart`
- `lib/features/communities/ui/widgets/event_card_overlay.dart`
- `lib/features/communities/ui/widgets/people_card.dart`
- `lib/common/constants/app_colors.dart`

Important current state:

- `MainNavigationScreen._pages` still puts `ExploreScreen()` at tab index 0 and labels it `Connect`.
- `DiscoverPageV2` already loads people, events, communities, and stats.
- `DiscoverPageV2` is the best implementation base because it already owns the event/community data and mixed feed.
- `Tabbar` is deprecated; avoid building the new primary experience there.

## Implementation Tasks

1. Make the first tab and first post-onboarding surface community/event-first.

- In `MainNavigationScreen`, make `DiscoverPageV2` tab index 0.
- Move `ExploreScreen` to a later tab as `Connect`.
- Update bottom nav order and labels to match: `Discover`, `Connect`, `Messages`, `Profile`.
- Keep existing route names working.

2. Redesign `DiscoverPageV2` into a Houston-first home.

Use the Figma frame as the layout model:

- Header: `Houston` location chip, notification/settings affordance if existing patterns support it.
- Hero copy: `Meet Houston's diaspora this week`.
- Support copy: `Events, community rooms, and verified people who get the culture.`
- Primary CTA: `See this weekend`.
- Secondary action: `Browse communities`.
- Event-first section: large featured event card using existing event data.
- Horizontal section: upcoming events this week.
- People section: verified/local people preview, not a swipe deck.
- Community section: repeating groups/rooms.
- Soft Connect module near the bottom: `Connect when the vibe is mutual`.

3. Preserve existing behavior.

- Refresh still reloads people, events, communities, and stats.
- Tapping events still opens `RouteName.eventDetails`.
- Tapping people still opens `HingeProfileViewerScreen`.
- Browse communities still opens `UnifiedGroupsScreen`.
- Discovery preferences/filter path should keep working if exposed.
- Empty states should route users toward this weekend/events and communities, not a blank dating queue.

4. Use the existing design system.

- Use `AppColors.primaryGreen`, `AppColors.textPrimary`, `AppColors.textSecondary`, `AppColors.backgroundColor`, `AppColors.border`.
- Use `GoogleFonts.montserrat` because the surrounding screen already does.
- Keep cards at sensible radius and avoid nested cards.
- Use real image URLs from events/users when present; use existing placeholder assets when missing.
- Make the screen responsive on small iPhones. No clipped text, no overlap, no viewport-scaled font sizes.

5. Add or update focused tests.

- Add a widget-level test that confirms `MainNavigationScreen` exposes `Discover` as the first/selected tab.
- Add test coverage or a lightweight golden/smoke test for `DiscoverPageV2` where possible. If Firebase mocking makes that too heavy, isolate the new static section widgets and test those.

## Acceptance Criteria

- A completed user landing on `RouteName.mainNavigation` sees Discover/community/events first, not the swipe deck.
- Bottom navigation order is `Discover`, `Connect`, `Messages`, `Profile`.
- The top of the screen clearly says Houston, diaspora, events/rooms, and verified people within 10 seconds.
- Connect/dating is still available but secondary.
- The screen works with real Firestore data and graceful empty/loading/error states.
- `dart format` is run on touched Dart files.
- `flutter analyze --no-fatal-infos --no-fatal-warnings` does not introduce new issues.
- Relevant widget tests pass or any pre-existing blocker is documented.

## App Review Framing

Reviewer screenshots and notes should show this first screen plus events/communities. Avoid screenshots where the first impression is only a generic profile card or swipe deck.

