# Auth Launch-State Matrix (Cutover Validation)

Run on at least one real iPhone and one Android device.

## Build flags for migration validation
- `--dart-define=ENV=next-production` (internal QA only)
- `--dart-define=FORCE_RELOGIN_AFTER_MIGRATION=true`
- `--dart-define=AUTH_MIGRATION_CUTOVER_EPOCH=<cutover_epoch>`

## Scenarios
1. Fresh install / no session
- Expected: Welcome screen (`Create Account` / `Log in`)

2. Returning user with complete profile session
- Expected: Main app

3. Returning user with incomplete profile session
- Expected: Onboarding resume flow

4. Stale/invalid session
- Expected: session cleared, then Welcome

## OTP checks
- Valid code succeeds.
- Invalid code fails with error state.
- Resend code works.

## Evidence to capture
- Screen recordings for each scenario.
- Console logs for `AUTH_FLOW` events.
- Crash-free metric and auth success metrics for 24-72h post cutover.
