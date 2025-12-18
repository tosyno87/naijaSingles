# Dating App UI Guidelines

## Profile Counter Policy

**DO NOT** add profile counters or pagination indicators (e.g., "1 of 5 profiles", "Profile 3 of 10") to the dating interface.

### Why Profile Counters Are Problematic:

1. **User Anxiety**: Counters create pressure and anxiety for users
2. **Not Typical**: Most successful dating apps (Tinder, Bumble, Hinge) don't show profile counts
3. **Reduces Engagement**: Users may feel overwhelmed or rushed
4. **Poor UX**: Creates a "shopping" mentality rather than genuine connection

### What to Do Instead:

- **Focus on the current profile**: Let users focus on one person at a time
- **Use subtle indicators**: If needed, use subtle loading states or progress indicators
- **Keep it simple**: The interface should feel natural and pressure-free

### Implementation Notes:

- The main dating interface is in `lib/features/home/ui/screens/home_page.dart`
- The swipe card component is in `lib/features/home/ui/screens/swipe_card.dart`
- Always follow dating app best practices for user experience

### Code Examples:

❌ **Don't do this:**
```dart
Text("${currentIndex + 1} of ${totalProfiles} profiles")
```

✅ **Do this instead:**
```dart
// Focus on the current profile without counters
// Use subtle loading states if needed
```

## Other UI Guidelines:

1. **Keep profiles focused**: One profile at a time
2. **Minimize distractions**: Remove unnecessary UI elements
3. **Focus on connection**: Emphasize the person, not the process
4. **Maintain mystery**: Don't reveal too much about the matching process
