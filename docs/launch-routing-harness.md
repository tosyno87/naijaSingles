# Launch Routing Harness (Real Device / TestFlight Prep)

Use this harness to verify first-screen routing for critical auth launch states.

Test file:
- `integration_test/launch_routing_harness_test.dart`

## 1. Fresh / No Session

```bash
flutter test integration_test/launch_routing_harness_test.dart \
  --dart-define=PRESERVE_DEBUG_SESSION_FOR_E2E=true \
  --dart-define=LAUNCH_STATE=fresh
```

Expected:
- Welcome screen with `Create Account` and `Log in`.

## 2. Stale Session (Anonymous)

```bash
flutter test integration_test/launch_routing_harness_test.dart \
  --dart-define=PRESERVE_DEBUG_SESSION_FOR_E2E=true \
  --dart-define=LAUNCH_STATE=stale
```

Expected:
- Session is cleared and Welcome screen is shown.

Note:
- Requires Firebase Anonymous Auth enabled for the project.

## 3. Incomplete Session

```bash
flutter test integration_test/launch_routing_harness_test.dart \
  --dart-define=PRESERVE_DEBUG_SESSION_FOR_E2E=true \
  --dart-define=LAUNCH_STATE=incomplete \
  --dart-define=E2E_INCOMPLETE_EMAIL=you@example.com \
  --dart-define=E2E_INCOMPLETE_PASSWORD=your_password
```

Expected:
- App opens into onboarding flow.

## 4. Complete Session

```bash
flutter test integration_test/launch_routing_harness_test.dart \
  --dart-define=PRESERVE_DEBUG_SESSION_FOR_E2E=true \
  --dart-define=LAUNCH_STATE=complete \
  --dart-define=E2E_COMPLETE_EMAIL=you@example.com \
  --dart-define=E2E_COMPLETE_PASSWORD=your_password
```

Expected:
- App opens into main navigation (tabs like `Connect` / `Discover`).
