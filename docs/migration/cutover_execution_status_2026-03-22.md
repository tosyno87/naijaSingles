# Afropeep Migration Execution Status (2026-03-22)

## Completed execution items
- Branch: `codex/afropeep-firebase-migration`
- New Firebase project: `afropeep-prod-74a75`
- Alias mapping: `next-production -> afropeep-prod-74a75`
- Auth users migrated and parity checked:
  - Source users: 117
  - Destination users: 117
  - Missing UIDs in destination: 0
- Firestore `users` migrated and parity checked:
  - Source `users` docs: 117
  - Destination `users` docs: 117
- Storage migrated and parity checked:
  - Source objects: 132
  - Destination objects: 132
  - Source non-migration objects: 129
  - Destination non-migration objects: 129
  - Source bytes: 18,208,343
  - Destination bytes: 18,208,343
- Build verification against migrated project:
  - `flutter build ios --simulator --debug` with `ENV=next-production` passed
- Launch matrix verification:
  - `test/features/auth/auth_flow_test.dart` passed
  - core auth suite (OTP/welcome/phone/registration/google) passed
- Forced re-login cutover guard:
  - runtime guard implemented (`FORCE_RELOGIN_AFTER_MIGRATION` + epoch)
  - preflight check passed with epoch `202603221530`

## Post-cutover monitoring plan (72-hour window)
- Monitor every 30-60 minutes for first 6 hours, then every 4-6 hours:
  - Auth sign-in success rate
  - OTP verification failures
  - App crash-free sessions/users
  - Onboarding completion failures
  - Firestore/Storage permission-denied spikes

## Rollback triggers
- Auth success rate drops materially below baseline.
- OTP failures spike and remain elevated.
- Crash-free users drop materially below baseline.
- Onboarding completion failure rate spikes.

## Rollback action
1. Ship emergency build pointed to legacy Firebase project.
2. Keep legacy project active and writable during rollback window.
3. Pause further migration-only data writes until incident review completes.

## Remaining before main merge
- Wait for `www.afropeep.com` certificate to finish minting in Firebase Hosting.
- Optional: set canonical host redirect after cert is active.
- Prepare TestFlight build from this branch after final sanity pass.
